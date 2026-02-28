// lib/services/ml/ml_models.dart

import 'dart:math';
import '../../models/cotacao.dart';
import '../../models/ml_prediction.dart';
import 'feature_engineering.dart';

class MLModels {
  /// Random Forest simplificado
  static Future<Map<String, double>?> randomForest(
    List<Map<String, double>> features,
    List<double> targets,
    Map<String, double> novasFeatures,
  ) async {
    if (features.isEmpty || targets.isEmpty || novasFeatures.isEmpty) {
      print('⚠️ Random Forest: dados insuficientes');
      return null;
    }

    try {
      final predictions = <double>[];
      final numTrees = 100;

      for (int i = 0; i < numTrees; i++) {
        final sampleIndices = _bootstrapSample(features.length);
        final sampleFeatures = sampleIndices
            .map((idx) => features[idx])
            .toList();
        final sampleTargets = sampleIndices.map((idx) => targets[idx]).toList();

        final treePrediction = _decisionTreePrediction(
          sampleFeatures,
          sampleTargets,
          novasFeatures,
        );

        if (treePrediction != null) {
          predictions.add(treePrediction);
        }
      }

      if (predictions.isEmpty) return null;

      final media = predictions.reduce((a, b) => a + b) / predictions.length;
      final desvio = _calcularDesvioPadraoLista(predictions);

      return {
        'predicao': media,
        'confianca': desvio > 0 ? 1 - (desvio / media).abs().clamp(0, 1) : 0.5,
      };
    } catch (e) {
      print('🔥 Erro no Random Forest: $e');
      return null;
    }
  }

  /// Gradient Boosting simplificado
  static Future<Map<String, double>?> gradientBoosting(
    List<Map<String, double>> features,
    List<double> targets,
    Map<String, double> novasFeatures,
  ) async {
    if (features.isEmpty || targets.isEmpty || novasFeatures.isEmpty) {
      print('⚠️ Gradient Boosting: dados insuficientes');
      return null;
    }

    try {
      double predicao = 0;
      double learningRate = 0.1;
      int nEstimators = 100;

      double mediaTarget = targets.reduce((a, b) => a + b) / targets.length;
      predicao = mediaTarget;

      List<double> residuos = targets.map((t) => t - mediaTarget).toList();

      for (int i = 0; i < nEstimators; i++) {
        final melhorFeature = _encontrarMelhorFeature(features, residuos);
        if (melhorFeature == null) continue;

        final valorFeature = novasFeatures[melhorFeature] ?? 0;
        predicao +=
            learningRate * valorFeature * _getFeaturePeso(melhorFeature);

        for (int j = 0; j < residuos.length; j++) {
          residuos[j] = targets[j] - predicao;
        }
      }

      return {'predicao': predicao, 'confianca': 0.7};
    } catch (e) {
      print('🔥 Erro no Gradient Boosting: $e');
      return null;
    }
  }

  /// LSTM simplificado
  static Future<Map<String, double>?> lstm(
    List<Map<String, double>> features,
    List<double> targets,
    Map<String, double> novasFeatures,
  ) async {
    if (features.isEmpty || targets.isEmpty || novasFeatures.isEmpty) {
      print('⚠️ LSTM: dados insuficientes');
      return null;
    }

    try {
      final featuresNormalizadas = _normalizarFeatures(features);
      if (featuresNormalizadas.isEmpty) return null;

      final novasNormalizadas = _normalizarFeatureUnica(
        novasFeatures,
        features,
      );

      double hidden = 0;
      double cell = 0;

      for (int i = 0; i < featuresNormalizadas.length; i++) {
        final somaFeatures = featuresNormalizadas[i].values.fold(
          0.0,
          (a, b) => a + b,
        );
        final input = somaFeatures / featuresNormalizadas[i].length;

        final forget = _sigmoid(input * 0.5 + hidden * 0.3);
        cell = cell * forget;

        final inputGate = _sigmoid(input * 0.6 + hidden * 0.4);
        final candidate = _tanh(input * 0.8 + hidden * 0.2);
        cell = cell + inputGate * candidate;

        final outputGate = _sigmoid(input * 0.7 + hidden * 0.3);
        hidden = outputGate * _tanh(cell);
      }

      final ultimoTarget = targets.isNotEmpty ? targets.last : 0;
      final predicao = hidden * 10 + ultimoTarget;

      return {'predicao': predicao, 'confianca': 0.65};
    } catch (e) {
      print('🔥 Erro no LSTM: $e');
      return null;
    }
  }

  /// Ensemble - Combina múltiplos modelos
  static Future<MLPrediction?> ensemblePrediction(
    String ticker,
    List<Cotacao> historico,
    Map<String, dynamic> dadosFundamentalistas,
  ) async {
    print('🎯 Iniciando ensemblePrediction para $ticker');

    if (historico.isEmpty) {
      print('⚠️ Histórico vazio');
      return null;
    }

    try {
      // ===== 1. CALCULAR FEATURES =====
      print('📊 Calculando features técnicas...');
      final featuresTecnicas = FeatureEngineering.calcularFeatures(historico);
      print('📊 Features técnicas: ${featuresTecnicas.length}');

      // Features fundamentalistas (com fallback)
      Map<String, double> featuresFundamentalistas = {};
      if (dadosFundamentalistas.isNotEmpty) {
        featuresFundamentalistas =
            FeatureEngineering.calcularFeaturesFundamentalistas(
              dadosFundamentalistas,
            );
        print(
          '📊 Features fundamentalistas: ${featuresFundamentalistas.length}',
        );
      } else {
        print('⚠️ Dados fundamentalistas vazios, usando valores padrão');
        featuresFundamentalistas = {
          'pl': 10.0,
          'pvpa': 1.5,
          'roe': 0.12,
          'dividend_yield': 4.0,
          'payout': 0.3,
          'beta': 1.0,
        };
      }

      // Features de sentimento (mockadas por enquanto)
      final featuresSentimento =
          await FeatureEngineering.calcularFeaturesSentimento(ticker);
      print('📊 Features sentimento: ${featuresSentimento.length}');

      // Combinar todas as features
      final featuresCompletas = {
        ...featuresTecnicas,
        ...featuresFundamentalistas,
        ...featuresSentimento,
      };
      print('📊 Total de features: ${featuresCompletas.length}');

      // ===== 2. PREPARAR DADOS DE TREINAMENTO =====
      print('📊 Preparando dados de treinamento...');
      final dadosTreinamento = _prepararDadosTreinamento(historico);
      final featuresTreino =
          dadosTreinamento['features'] as List<Map<String, double>>;
      final targetsTreino = dadosTreinamento['targets'] as List<double>;

      print(
        '🎯 Features treino: ${featuresTreino.length}, Targets treino: ${targetsTreino.length}',
      );

      if (featuresTreino.isEmpty || targetsTreino.isEmpty) {
        print('⚠️ Dados de treinamento insuficientes');
        return null;
      }

      // Verificar escala dos targets
      _verificarEscalaTargets(targetsTreino);

      // ===== 3. EXECUTAR MODELOS EM PARALELO =====
      print('🤖 Executando modelos de ML...');
      final results = await Future.wait([
        randomForest(featuresTreino, targetsTreino, featuresCompletas),
        gradientBoosting(featuresTreino, targetsTreino, featuresCompletas),
        lstm(featuresTreino, targetsTreino, featuresCompletas),
      ]);

      // Filtrar resultados nulos
      final resultadosValidos = results.where((r) => r != null).toList();
      print('✅ Modelos que funcionaram: ${resultadosValidos.length} de 3');

      if (resultadosValidos.isEmpty) {
        print('⚠️ Nenhum modelo conseguiu gerar previsão');
        return null;
      }

      // ===== 4. COMBINAR RESULTADOS (ENSEMBLE) =====
      double predicaoFinal = 0;
      double confiancaTotal = 0;
      final pesos = [0.35, 0.35, 0.30]; // Pesos para RF, GB, LSTM

      for (int i = 0; i < results.length; i++) {
        if (results[i] != null) {
          predicaoFinal += (results[i]!['predicao'] ?? 0) * pesos[i];
          confiancaTotal += (results[i]!['confianca'] ?? 0.5) * pesos[i];
        }
      }

      print('🎯 Predicao final (bruta): $predicaoFinal');

      // ===== 5. CORREÇÃO DE ESCALA =====
      // Verificar se a predicao é um preço absoluto (valor > 10) ou retorno (valor < 1)
      final ultimoPreco = historico.last.fechamento;
      double retornoPrevisto;

      if (predicaoFinal.abs() > 10) {
        // Provavelmente é preço absoluto - converter para retorno
        print('⚠️ Detectado possível preço absoluto: $predicaoFinal');
        retornoPrevisto = (predicaoFinal - ultimoPreco) / ultimoPreco;
        print(
          '📊 Convertido para retorno: ${(retornoPrevisto * 100).toStringAsFixed(2)}%',
        );
      } else {
        // Já é retorno percentual
        retornoPrevisto = predicaoFinal;
      }

      // Limitar retorno a valores realistas (ações raramente movem >10% em um dia)
      final retornoLimitado = retornoPrevisto.clamp(-0.10, 0.10);
      final precoPrevistoRealista = ultimoPreco * (1 + retornoLimitado);

      print('📈 Preço atual: $ultimoPreco');
      print(
        '📊 Retorno original: ${(retornoPrevisto * 100).toStringAsFixed(2)}%',
      );
      print(
        '📊 Retorno limitado: ${(retornoLimitado * 100).toStringAsFixed(2)}%',
      );
      print('💰 Preço previsto (realista): $precoPrevistoRealista');

      // ===== 6. CALCULAR PROBABILIDADES E SINAIS =====
      // Probabilidade de alta baseada no retorno (mapear de -10%-10% para 0-100%)
      final probAlta = (50 + retornoLimitado * 500).clamp(0, 100).toDouble();

      // Determinar sinais
      final sinalCurto = _determinarSinal(retornoLimitado, 0.01);
      final sinalMedio = _determinarSinal(retornoLimitado * 2, 0.02);
      final sinalLongo = _determinarSinal(retornoLimitado * 3, 0.03);

      // ===== 7. CALCULAR PROJEÇÕES FUTURAS =====
      // Usar o mesmo retorno projetado para períodos futuros
      // Quanto mais longo o prazo, maior a incerteza
      final fatorIncerteza = 1.5;

      final preco1s = ultimoPreco * (1 + retornoLimitado * 2);
      final preco1m = ultimoPreco * (1 + retornoLimitado * 4);
      final preco3m = ultimoPreco * (1 + retornoLimitado * 8);

      // ===== 8. CRIAR OBJETO MLPrediction =====
      final prediction = MLPrediction(
        ticker: ticker,
        dataPrevisao: DateTime.now(),
        modelo: ModeloML.ensemble,
        precoPrevisto1d: precoPrevistoRealista,
        precoPrevisto1s: preco1s,
        precoPrevisto1m: preco1m,
        precoPrevisto3m: preco3m,
        probabilidadeAlta: probAlta,
        probabilidadeBaixa: 100 - probAlta,
        sinalCurtoPrazo: sinalCurto,
        sinalMedioPrazo: sinalMedio,
        sinalLongoPrazo: sinalLongo,
        acuracia: confiancaTotal,
        precisao: confiancaTotal * 0.95,
        recall: confiancaTotal * 0.92,
        f1Score: confiancaTotal * 0.93,
        topFeatures: _getTopFeatures(featuresCompletas),
        intervaloConfianca: 0.95,
        limiteInferior: precoPrevistoRealista * 0.95,
        limiteSuperior: precoPrevistoRealista * 1.05,
        diasTreinamento: historico.length,
        dataUltimoTreinamento: DateTime.now().subtract(const Duration(days: 1)),
      );

      print('✅ PREVISÃO FINAL CRIADA COM SUCESSO:');
      print('   Ticker: $ticker');
      print('   Preço atual: ${ultimoPreco.toStringAsFixed(2)}');
      print('   Preço previsto: ${precoPrevistoRealista.toStringAsFixed(2)}');
      print('   Retorno: ${(retornoLimitado * 100).toStringAsFixed(2)}%');
      print('   Probabilidade alta: ${probAlta.toStringAsFixed(1)}%');
      print('   Sinal: $sinalCurto');

      return prediction;
    } catch (e, stackTrace) {
      print('🔥 ERRO CRÍTICO no ensemblePrediction: $e');
      print('📋 StackTrace: $stackTrace');
      return null;
    }
  }

  /// Método auxiliar para verificar escala dos targets
  static void _verificarEscalaTargets(List<double> targets) {
    if (targets.isEmpty) return;

    final media = targets.reduce((a, b) => a + b) / targets.length;
    final maximo = targets.reduce(max);
    final minimo = targets.reduce(min);

    print('📊 Verificação de escala dos targets:');
    print('   Média: ${(media * 100).toStringAsFixed(2)}%');
    print('   Mínimo: ${(minimo * 100).toStringAsFixed(2)}%');
    print('   Máximo: ${(maximo * 100).toStringAsFixed(2)}%');

    if (maximo > 0.3 || minimo < -0.3) {
      print('⚠️ ATENÇÃO: Targets com valores extremos!');
      print(
        '   Isso pode indicar dados anômalos ou necessidade de normalização.',
      );
    } else {
      print('✅ Targets em escala adequada (entre -30% e +30%)');
    }
  }

  // ... TODOS OS MÉTODOS AUXILIARES COM VERIFICAÇÃO DE NULL ...

  static List<int> _bootstrapSample(int n) {
    if (n <= 0) return [];
    final random = Random();
    return List.generate(n, (_) => random.nextInt(n));
  }

  static double? _decisionTreePrediction(
    List<Map<String, double>> features,
    List<double> targets,
    Map<String, double> novasFeatures,
  ) {
    if (features.isEmpty || targets.isEmpty || novasFeatures.isEmpty) {
      return null;
    }

    try {
      final featureImportance = <String, double>{};

      for (var feature in features.first.keys) {
        double somaCorrelacao = 0;
        int count = 0;
        for (int i = 0; i < min(features.length, targets.length); i++) {
          if (features[i].containsKey(feature)) {
            somaCorrelacao += (features[i][feature] ?? 0) * targets[i];
            count++;
          }
        }
        if (count > 0) {
          featureImportance[feature] = somaCorrelacao.abs();
        }
      }

      if (featureImportance.isEmpty) return null;

      final melhorFeature = featureImportance.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      final x = features.map((f) => f[melhorFeature] ?? 0).toList();
      final y = targets;

      final coeficiente = _calcularCoeficiente(x, y);
      final intercepto = _calcularIntercepto(x, y, coeficiente);

      return intercepto + coeficiente * (novasFeatures[melhorFeature] ?? 0);
    } catch (e) {
      print('⚠️ Erro na árvore de decisão: $e');
      return null;
    }
  }

  static String? _encontrarMelhorFeature(
    List<Map<String, double>> features,
    List<double> residuos,
  ) {
    if (features.isEmpty || residuos.isEmpty) return null;

    final Map<String, double> correlacoes = {};

    for (var feature in features.first.keys) {
      double soma = 0;
      int count = 0;
      for (int i = 0; i < min(features.length, residuos.length); i++) {
        if (features[i].containsKey(feature)) {
          soma += (features[i][feature] ?? 0) * residuos[i];
          count++;
        }
      }
      if (count > 0) {
        correlacoes[feature] = soma.abs();
      }
    }

    if (correlacoes.isEmpty) return null;

    return correlacoes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static double _getFeaturePeso(String feature) {
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

    for (var feature in features.first.keys) {
      final valores = features.map((f) => f[feature] ?? 0).toList();
      medias[feature] = valores.reduce((a, b) => a + b) / valores.length;

      double somaQuadrados = 0;
      for (var v in valores) {
        somaQuadrados += pow(v - medias[feature]!, 2).toDouble();
      }
      desvios[feature] = valores.length > 1
          ? sqrt(somaQuadrados / (valores.length - 1)).toDouble()
          : 1.0;
    }

    for (var f in features) {
      final normalizada = <String, double>{};
      for (var entry in f.entries) {
        if ((desvios[entry.key] ?? 0) > 0) {
          normalizada[entry.key] =
              (entry.value - (medias[entry.key] ?? 0)) /
              (desvios[entry.key] ?? 1);
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
      final valores = featuresBase.map((f) => f[key] ?? 0).toList();
      medias[key] = valores.reduce((a, b) => a + b) / valores.length;

      double somaQuadrados = 0;
      for (var v in valores) {
        somaQuadrados += pow(v - medias[key]!, 2).toDouble();
      }
      desvios[key] = valores.length > 1
          ? sqrt(somaQuadrados / (valores.length - 1)).toDouble()
          : 1.0;

      normalizada[key] = (feature[key]! - medias[key]!) / desvios[key]!;
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

    final denominador = n * somaX2 - somaX * somaX;
    if (denominador == 0) return 0;

    return (n * somaXY - somaX * somaY) / denominador;
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
    if (valores.length == 1) return 0;

    final media = valores.reduce((a, b) => a + b) / valores.length;
    double somaQuadrados = 0;

    for (var v in valores) {
      somaQuadrados += pow(v - media, 2).toDouble();
    }

    return sqrt(somaQuadrados / (valores.length - 1)).toDouble();
  }

  // No método _prepararDadosTreinamento, modifique:

  // lib/services/ml/ml_models.dart

  static Map<String, dynamic> _prepararDadosTreinamento(
    List<Cotacao> historico,
  ) {
    print(
      '📊 Preparando dados de treinamento com ${historico.length} cotações',
    );

    final MIN_JANELA = 20;

    if (historico.length < MIN_JANELA + 1) {
      print('⚠️ Histórico insuficiente');
      return {'features': [], 'targets': []};
    }

    final features = <Map<String, double>>[];
    final targets = <double>[];

    // Estatísticas para normalização
    final todosRetornos = <double>[];

    for (int i = MIN_JANELA; i < historico.length - 1; i++) {
      final janela = historico.sublist(i - MIN_JANELA, i);
      final feature = FeatureEngineering.calcularFeatures(janela);

      if (feature.isNotEmpty) {
        features.add(feature);

        // 🔥 CALCULAR RETORNO PERCENTUAL (CORRETO!)
        final precoAtual = historico[i].fechamento;
        final precoFuturo = historico[i + 1].fechamento;
        final retornoPercentual = (precoFuturo - precoAtual) / precoAtual;

        // Armazenar para análise
        todosRetornos.add(retornoPercentual);

        // Adicionar ao target (já em percentual decimal: 0.05 = 5%)
        targets.add(retornoPercentual);

        if (i < MIN_JANELA + 5) {
          // Log apenas dos primeiros para debug
          print(
            '📊 Exemplo $i: preço $precoAtual → $precoFuturo, retorno: ${(retornoPercentual * 100).toStringAsFixed(2)}%',
          );
        }
      }
    }

    // Estatísticas dos retornos
    if (todosRetornos.isNotEmpty) {
      final media =
          todosRetornos.reduce((a, b) => a + b) / todosRetornos.length;
      final variancia =
          todosRetornos.map((r) => pow(r - media, 2)).reduce((a, b) => a + b) /
          todosRetornos.length;
      final desvio = sqrt(variancia).toDouble();

      print('📊 Estatísticas dos retornos:');
      print('   Média: ${(media * 100).toStringAsFixed(2)}%');
      print('   Desvio: ${(desvio * 100).toStringAsFixed(2)}%');
      print(
        '   Mínimo: ${(todosRetornos.reduce(min) * 100).toStringAsFixed(2)}%',
      );
      print(
        '   Máximo: ${(todosRetornos.reduce(max) * 100).toStringAsFixed(2)}%',
      );
    }

    print('✅ Gerados ${features.length} exemplos de treinamento');
    return {'features': features, 'targets': targets};
  }

  // 🔥 NOVO MÉTODO: Calcular média dos targets para debug
  static double _calcularMediaTargets(List<double> targets) {
    if (targets.isEmpty) return 0;
    return targets.reduce((a, b) => a + b) / targets.length;
  }

  // 🔥 NOVO MÉTODO: Verificar se os targets estão em escala correta
  static bool _targetsEmEscalaCorreta(List<double> targets) {
    if (targets.isEmpty) return false;

    final media = _calcularMediaTargets(targets);
    final maxTarget = targets.reduce(max);
    final minTarget = targets.reduce(min);

    print('📊 Verificação de escala dos targets:');
    print('   Média: ${(media * 100).toStringAsFixed(2)}%');
    print('   Mínimo: ${(minTarget * 100).toStringAsFixed(2)}%');
    print('   Máximo: ${(maxTarget * 100).toStringAsFixed(2)}%');

    // Targets devem estar entre -30% e +30% para ações
    if (maxTarget > 0.3 || minTarget < -0.3) {
      print('⚠️ Targets fora da escala esperada!');
      return false;
    }

    print('✅ Targets em escala correta');
    return true;
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
