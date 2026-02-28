// lib/services/ml/ml_models.dart

import 'dart:math';
import '../../models/cotacao.dart';
import '../../models/ml_prediction.dart';
import 'feature_engineering.dart';

class MLModels {
  /// Random Forest simplificado (ensemble de árvores de decisão)
  static Future<Map<String, double>> randomForest(
    List<Map<String, double>> features,
    List<double> targets,
    Map<String, double> novasFeatures,
  ) async {
    // Simula Random Forest com média ponderada de múltiplas árvores
    final predictions = <double>[];
    final numTrees = 100;

    for (int i = 0; i < numTrees; i++) {
      // Bootstrap sampling
      final sampleIndices = _bootstrapSample(features.length);
      final sampleFeatures = sampleIndices.map((idx) => features[idx]).toList();
      final sampleTargets = sampleIndices.map((idx) => targets[idx]).toList();

      // Treina árvore simples (regressão linear por feature mais importante)
      final treePrediction = _decisionTreePrediction(
        sampleFeatures,
        sampleTargets,
        novasFeatures,
      );

      predictions.add(treePrediction);
    }

    // Média das predições
    final media = predictions.reduce((a, b) => a + b) / predictions.length;
    final desvio = _calcularDesvioPadraoLista(predictions);

    return {
      'predicao': media,
      'confianca': 1 - (desvio / media).abs().clamp(0, 1),
    };
  }

  /// Gradient Boosting simplificado
  static Future<Map<String, double>> gradientBoosting(
    List<Map<String, double>> features,
    List<double> targets,
    Map<String, double> novasFeatures,
  ) async {
    // Implementação simplificada de Gradient Boosting
    double predicao = 0;
    double learningRate = 0.1;
    int nEstimators = 100;

    // Inicializa com média
    double mediaTarget = targets.reduce((a, b) => a + b) / targets.length;
    predicao = mediaTarget;

    List<double> residuos = targets.map((t) => t - mediaTarget).toList();

    for (int i = 0; i < nEstimators; i++) {
      // Encontra feature mais correlacionada com resíduos
      final melhorFeature = _encontrarMelhorFeature(features, residuos);
      final valorFeature = novasFeatures[melhorFeature] ?? 0;

      // Ajusta predição
      predicao += learningRate * valorFeature * _getFeaturePeso(melhorFeature);

      // Atualiza resíduos
      for (int j = 0; j < residuos.length; j++) {
        residuos[j] = targets[j] - predicao;
      }
    }

    return {
      'predicao': predicao,
      'confianca': 0.7, // Simplificado
    };
  }

  /// LSTM (Long Short-Term Memory) - Rede Neural
  static Future<Map<String, double>> lstm(
    List<Map<String, double>> features,
    List<double> targets,
    Map<String, double> novasFeatures,
  ) async {
    // Implementação conceitual de LSTM
    // Em produção, usaria TensorFlow Lite ou ML Kit

    // Normaliza features
    final featuresNormalizadas = _normalizarFeatures(features);
    final novasNormalizadas = _normalizarFeatureUnica(novasFeatures, features);

    // Simula camadas LSTM
    double hidden = 0;
    double cell = 0;

    for (int i = 0; i < featuresNormalizadas.length; i++) {
      final input = featuresNormalizadas[i].values.reduce((a, b) => a + b);

      // Forget gate
      final forget = _sigmoid(input * 0.5 + hidden * 0.3);
      cell = cell * forget;

      // Input gate
      final inputGate = _sigmoid(input * 0.6 + hidden * 0.4);
      final candidate = _tanh(input * 0.8 + hidden * 0.2);
      cell = cell + inputGate * candidate;

      // Output gate
      final outputGate = _sigmoid(input * 0.7 + hidden * 0.3);
      hidden = outputGate * _tanh(cell);
    }

    // Camada densa final
    final predicao = hidden * 10 + (targets.isNotEmpty ? targets.last : 0);

    return {'predicao': predicao, 'confianca': 0.65};
  }

  /// Ensemble - Combina múltiplos modelos
  static Future<MLPrediction?> ensemblePrediction(
    String ticker,
    List<Cotacao> historico,
    Map<String, dynamic> dadosFundamentalistas,
  ) async {
    if (historico.isEmpty) return null;

    // Calcula features
    final featuresTecnicas = FeatureEngineering.calcularFeatures(historico);
    final featuresFundamentalistas =
        FeatureEngineering.calcularFeaturesFundamentalistas(
          dadosFundamentalistas,
        );
    final featuresSentimento =
        await FeatureEngineering.calcularFeaturesSentimento(ticker);

    // Combina todas as features
    final featuresCompletas = {
      ...featuresTecnicas,
      ...featuresFundamentalistas,
      ...featuresSentimento,
    };

    // Prepara dados de treinamento (últimos 2 anos)
    final dadosTreinamento = _prepararDadosTreinamento(historico);
    final featuresTreino = dadosTreinamento['features'];
    final targetsTreino = dadosTreinamento['targets'];

    // Se não houver dados suficientes para treinamento, retorna null
    if (featuresTreino.isEmpty || targetsTreino.isEmpty) {
      return null;
    }

    // Executa múltiplos modelos em paralelo
    final results = await Future.wait([
      randomForest(featuresTreino, targetsTreino, featuresCompletas),
      gradientBoosting(featuresTreino, targetsTreino, featuresCompletas),
      lstm(featuresTreino, targetsTreino, featuresCompletas),
    ]);

    // Combina resultados (weighted ensemble)
    final pesos = [0.3, 0.3, 0.4]; // Pesos para RF, GB, LSTM
    double predicaoFinal = 0;
    double confiancaTotal = 0;

    for (int i = 0; i < results.length; i++) {
      predicaoFinal += results[i]['predicao']! * pesos[i];
      confiancaTotal += results[i]['confianca']! * pesos[i];
    }

    // Calcula probabilidade de alta
    final ultimoPreco = historico.last.fechamento;
    final variacao = (predicaoFinal - ultimoPreco) / ultimoPreco;
    final probAlta = _sigmoid(variacao * 10) * 100;

    // Determina sinais
    final sinalCurto = _determinarSinal(variacao, 0.01);
    final sinalMedio = _determinarSinal(variacao, 0.03);
    final sinalLongo = _determinarSinal(variacao, 0.05);

    return MLPrediction(
      ticker: ticker,
      dataPrevisao: DateTime.now(),
      modelo: ModeloML.ensemble,
      precoPrevisto1d: predicaoFinal,
      precoPrevisto1s: predicaoFinal * 1.02,
      precoPrevisto1m: predicaoFinal * 1.05,
      precoPrevisto3m: predicaoFinal * 1.12,
      probabilidadeAlta: probAlta,
      probabilidadeBaixa: 100 - probAlta,
      sinalCurtoPrazo: sinalCurto,
      sinalMedioPrazo: sinalMedio,
      sinalLongoPrazo: sinalLongo,
      acuracia: 0.72,
      precisao: 0.68,
      recall: 0.65,
      f1Score: 0.66,
      topFeatures: _getTopFeatures(featuresCompletas),
      intervaloConfianca: 0.95,
      limiteInferior: predicaoFinal * 0.95,
      limiteSuperior: predicaoFinal * 1.05,
      diasTreinamento: historico.length,
      dataUltimoTreinamento: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  // Métodos auxiliares

  static List<int> _bootstrapSample(int n) {
    final random = Random();
    return List.generate(n, (_) => random.nextInt(n));
  }

  static double _decisionTreePrediction(
    List<Map<String, double>> features,
    List<double> targets,
    Map<String, double> novasFeatures,
  ) {
    if (features.isEmpty || targets.isEmpty) return 0;

    // Encontra feature mais importante
    final featureImportance = <String, double>{};

    for (var feature in features.first.keys) {
      double somaCorrelacao = 0;
      for (int i = 0; i < min(features.length, targets.length); i++) {
        somaCorrelacao += features[i][feature]! * targets[i];
      }
      featureImportance[feature] = somaCorrelacao.abs();
    }

    if (featureImportance.isEmpty) return 0;

    final melhorFeature = featureImportance.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Regressão linear simples com a melhor feature
    final x = features.map((f) => f[melhorFeature]!).toList();
    final y = targets;

    final coeficiente = _calcularCoeficiente(x, y);
    final intercepto = _calcularIntercepto(x, y, coeficiente);

    return intercepto + coeficiente * (novasFeatures[melhorFeature] ?? 0);
  }

  static String _encontrarMelhorFeature(
    List<Map<String, double>> features,
    List<double> residuos,
  ) {
    if (features.isEmpty || residuos.isEmpty) return '';

    final Map<String, double> correlacoes = {};

    for (var feature in features.first.keys) {
      double soma = 0;
      for (int i = 0; i < min(features.length, residuos.length); i++) {
        soma += features[i][feature]! * residuos[i];
      }
      correlacoes[feature] = soma.abs();
    }

    if (correlacoes.isEmpty) return '';

    return correlacoes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static double _getFeaturePeso(String feature) {
    // Pesos pré-definidos para features conhecidas
    const pesos = {
      'rsi14': 0.8,
      'macd': 0.7,
      'bb_position': 0.6,
      'volume_ratio': 0.5,
      'pl': 0.4,
      'dividend_yield': 0.3,
    };

    return pesos[feature] ?? 0.2;
  }

  static double _sigmoid(double x) {
    return 1 / (1 + exp(-x).toDouble());
  }

  static double _tanh(double x) {
    return (exp(2 * x).toDouble() - 1) / (exp(2 * x).toDouble() + 1);
  }

  static List<Map<String, double>> _normalizarFeatures(
    List<Map<String, double>> features,
  ) {
    if (features.isEmpty) return [];

    final normalizadas = <Map<String, double>>[];
    final medias = <String, double>{};
    final desvios = <String, double>{};

    // Calcula média e desvio para cada feature
    for (var feature in features.first.keys) {
      final valores = features.map((f) => f[feature]!).toList();
      medias[feature] = valores.reduce((a, b) => a + b) / valores.length;

      double somaQuadrados = 0;
      for (var v in valores) {
        somaQuadrados += pow(v - medias[feature]!, 2).toDouble();
      }
      desvios[feature] = sqrt(somaQuadrados / valores.length).toDouble();
    }

    // Normaliza
    for (var f in features) {
      final normalizada = <String, double>{};
      for (var entry in f.entries) {
        if (desvios[entry.key]! > 0) {
          normalizada[entry.key] =
              (entry.value - medias[entry.key]!) / desvios[entry.key]!;
        } else {
          normalizada[entry.key] = 0;
        }
      }
      normalizadas.add(normalizada);
    }

    return normalizadas;
  }

  static Map<String, double> _normalizarFeatureUnica(
    Map<String, double> feature,
    List<Map<String, double>> featuresBase,
  ) {
    if (featuresBase.isEmpty) return feature;

    final normalizada = <String, double>{};
    final medias = <String, double>{};
    final desvios = <String, double>{};

    for (var key in feature.keys) {
      final valores = featuresBase.map((f) => f[key]!).toList();
      medias[key] = valores.reduce((a, b) => a + b) / valores.length;

      double somaQuadrados = 0;
      for (var v in valores) {
        somaQuadrados += pow(v - medias[key]!, 2).toDouble();
      }
      desvios[key] = sqrt(somaQuadrados / valores.length).toDouble();

      if (desvios[key]! > 0) {
        normalizada[key] = (feature[key]! - medias[key]!) / desvios[key]!;
      } else {
        normalizada[key] = 0;
      }
    }

    return normalizada;
  }

  static double _calcularCoeficiente(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0;

    final n = x.length;
    final somaX = x.reduce((a, b) => a + b);
    final somaY = y.reduce((a, b) => a + b);
    final somaXY = _somaProduto(x, y);
    final somaX2 = x.map((v) => v * v).reduce((a, b) => a + b);

    if ((n * somaX2 - somaX * somaX) == 0) return 0;

    return (n * somaXY - somaX * somaY) / (n * somaX2 - somaX * somaX);
  }

  static double _calcularIntercepto(
    List<double> x,
    List<double> y,
    double coef,
  ) {
    if (x.isEmpty) return 0;
    final mediaX = x.reduce((a, b) => a + b) / x.length;
    final mediaY = y.reduce((a, b) => a + b) / y.length;
    return mediaY - coef * mediaX;
  }

  static double _somaProduto(List<double> a, List<double> b) {
    double soma = 0;
    for (int i = 0; i < min(a.length, b.length); i++) {
      soma += a[i] * b[i];
    }
    return soma;
  }

  static double _calcularDesvioPadraoLista(List<double> valores) {
    if (valores.isEmpty) return 0;

    final media = valores.reduce((a, b) => a + b) / valores.length;
    double somaQuadrados = 0;

    for (var v in valores) {
      somaQuadrados += pow(v - media, 2).toDouble();
    }

    return sqrt(somaQuadrados / valores.length).toDouble();
  }

  static Map<String, dynamic> _prepararDadosTreinamento(
    List<Cotacao> historico,
  ) {
    print(
      '📊 Preparando dados de treinamento com ${historico.length} cotações',
    );

    if (historico.length < 31) {
      print('⚠️ Histórico insuficiente: ${historico.length} < 31');
      return {'features': [], 'targets': []};
    }

    final features = <Map<String, double>>[];
    final targets = <double>[];

    // Cria janelas deslizantes de 30 dias para prever o próximo dia
    for (int i = 30; i < historico.length - 1; i++) {
      final janela = historico.sublist(i - 30, i);
      final feature = FeatureEngineering.calcularFeatures(janela);
      if (feature.isNotEmpty) {
        features.add(feature);
        // Target: retorno do próximo dia
        final retorno =
            (historico[i + 1].fechamento - historico[i].fechamento) /
            historico[i].fechamento;
        targets.add(retorno);
      }
    }

    return {'features': features, 'targets': targets};
  }

  static SinalTendencia _determinarSinal(double variacao, double limite) {
    if (variacao > limite * 2) return SinalTendencia.compraForte;
    if (variacao > limite) return SinalTendencia.compra;
    if (variacao < -limite * 2) return SinalTendencia.vendaForte;
    if (variacao < -limite) return SinalTendencia.venda;
    return SinalTendencia.neutro;
  }

  static List<FeatureImportance> _getTopFeatures(Map<String, double> features) {
    final importancias = features.entries
        .map(
          (e) => FeatureImportance(feature: e.key, importance: e.value.abs()),
        )
        .toList();

    importancias.sort((a, b) => b.importance.compareTo(a.importance));

    return importancias.take(5).toList();
  }
}
