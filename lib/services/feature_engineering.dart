// lib/services/ml/feature_engineering.dart

import 'dart:math';
import '../../models/cotacao.dart';

class FeatureEngineering {
  /// Calcula features técnicas a partir de dados históricos
  static Map<String, double> calcularFeatures(List<Cotacao> historico) {
    // if (historico.length < 50) return {};

    if (historico.length < 20) return {};

    final features = <String, double>{};
    final precos = historico.map((c) => c.fechamento).toList();
    final datas = historico.map((c) => c.data).toList();

    // 1. Médias Móveis
    features['ma5'] = _calcularMediaMovel(precos, 5);
    features['ma10'] = _calcularMediaMovel(precos, 10);
    features['ma20'] = _calcularMediaMovel(precos, 20);
    features['ma50'] = _calcularMediaMovel(precos, 50);

    // 2. Preço em relação às médias
    final precoAtual = precos.last;
    features['preco_ma5_ratio'] = precoAtual / features['ma5']!;
    features['preco_ma20_ratio'] = precoAtual / features['ma20']!;

    // 3. RSI (Relative Strength Index)
    features['rsi14'] = _calcularRSI(precos, 14);

    // 4. MACD
    final macd = _calcularMACD(precos);
    features['macd'] = macd['macd']!;
    features['macd_signal'] = macd['signal']!;
    features['macd_histogram'] = macd['histogram']!;

    // 5. Bandas de Bollinger
    final bollinger = _calcularBollinger(precos, 20);
    features['bb_upper'] = bollinger['upper']!;
    features['bb_lower'] = bollinger['lower']!;
    features['bb_width'] = bollinger['width']!;
    features['bb_position'] =
        (precoAtual - bollinger['lower']!) /
        (bollinger['upper']! - bollinger['lower']!);

    // 6. Volatilidade
    features['volatilidade5'] = _calcularVolatilidade(precos, 5);
    features['volatilidade20'] = _calcularVolatilidade(precos, 20);

    // 7. Volume (se disponível)
    final volumes = historico.map((c) => c.volume).toList();
    if (volumes.last > 0) {
      features['volume_ratio'] =
          volumes.last / _calcularMediaMovel(volumes, 20);
    }

    // 8. Momentum
    if (precos.length >= 5) {
      features['momentum5'] = precoAtual / precos[precos.length - 5] - 1;
    }
    if (precos.length >= 10) {
      features['momentum10'] = precoAtual / precos[precos.length - 10] - 1;
    }
    if (precos.length >= 20) {
      features['momentum20'] = precoAtual / precos[precos.length - 20] - 1;
    }

    // 9. Taxa de retorno diária
    features['retorno_diario'] = _calcularRetornoMedio(precos);

    // 10. Features temporais
    features['dia_semana'] = datas.last.weekday.toDouble();
    features['dia_mes'] = datas.last.day.toDouble();
    features['mes'] = datas.last.month.toDouble();

    return features;
  }

  /// Calcula features fundamentalistas
  static Map<String, double> calcularFeaturesFundamentalistas(
    Map<String, dynamic> dadosFundamentalistas,
  ) {
    final features = <String, double>{};

    features['pl'] = dadosFundamentalistas['pe'] ?? 0;
    features['pvpa'] = dadosFundamentalistas['pb'] ?? 0;
    features['roe'] = dadosFundamentalistas['roe'] ?? 0;
    features['dividend_yield'] = dadosFundamentalistas['dividendYield'] ?? 0;
    features['payout'] = dadosFundamentalistas['payout'] ?? 0;
    features['beta'] = dadosFundamentalistas['beta'] ?? 1.0;

    return features;
  }

  /// Calcula features de sentimento de mercado
  static Future<Map<String, double>> calcularFeaturesSentimento(
    String ticker,
  ) async {
    final features = <String, double>{};

    // TODO: Integrar com API de notícias para análise de sentimento
    // Por enquanto, valores simulados
    features['sentimento_noticias'] = 0.5; // 0-1 (negativo-positivo)
    features['volume_redes_sociais'] = 0.3; // Engajamento
    features['recomendacoes_analistas'] = 0.7; // % de recomendações de compra

    return features;
  }

  // Métodos auxiliares privados

  static double _calcularMediaMovel(List<double> valores, int periodo) {
    if (valores.length < periodo) return valores.last;
    final recentes = valores.sublist(valores.length - periodo);
    return recentes.reduce((a, b) => a + b) / periodo;
  }

  static double _calcularRSI(List<double> precos, int periodo) {
    if (precos.length < periodo + 1) return 50;

    double ganho = 0, perda = 0;

    for (int i = precos.length - periodo; i < precos.length; i++) {
      final variacao = precos[i] - precos[i - 1];
      if (variacao > 0) {
        ganho += variacao;
      } else {
        perda += variacao.abs();
      }
    }

    final mediaGanho = ganho / periodo;
    final mediaPerda = perda / periodo;

    if (mediaPerda == 0) return 100;

    final rs = mediaGanho / mediaPerda;
    return 100 - (100 / (1 + rs));
  }

  static Map<String, double> _calcularMACD(List<double> precos) {
    final ema12 = _calcularEMA(precos, 12);
    final ema26 = _calcularEMA(precos, 26);
    final macdLine = ema12 - ema26;
    final signalLine = _calcularEMA(precos, 9);

    return {
      'macd': macdLine,
      'signal': signalLine,
      'histogram': macdLine - signalLine,
    };
  }

  static double _calcularEMA(List<double> precos, int periodo) {
    if (precos.isEmpty) return 0;

    final multiplicador = 2 / (periodo + 1);
    double ema = precos.first;

    for (int i = 1; i < precos.length; i++) {
      ema = (precos[i] - ema) * multiplicador + ema;
    }

    return ema;
  }

  static Map<String, double> _calcularBollinger(
    List<double> precos,
    int periodo,
  ) {
    final media = _calcularMediaMovel(precos, periodo);
    final desvioPadrao = _calcularDesvioPadrao(precos, periodo);

    return {
      'upper': media + 2 * desvioPadrao,
      'lower': media - 2 * desvioPadrao,
      'width': (media + 2 * desvioPadrao) - (media - 2 * desvioPadrao),
    };
  }

  static double _calcularDesvioPadrao(List<double> valores, int periodo) {
    if (valores.length < periodo) return 0;

    final recentes = valores.sublist(valores.length - periodo);
    final media = recentes.reduce((a, b) => a + b) / periodo;

    double somaQuadrados = 0;
    for (var v in recentes) {
      somaQuadrados += pow(v - media, 2).toDouble();
    }

    return sqrt(somaQuadrados / periodo).toDouble();
  }

  static double _calcularVolatilidade(List<double> precos, int periodo) {
    if (precos.length < periodo + 1) return 0;

    final retornos = <double>[];
    for (int i = precos.length - periodo; i < precos.length; i++) {
      retornos.add((precos[i] - precos[i - 1]) / precos[i - 1]);
    }

    final media = retornos.reduce((a, b) => a + b) / retornos.length;
    double somaQuadrados = 0;

    for (var r in retornos) {
      somaQuadrados += pow(r - media, 2).toDouble();
    }

    return sqrt(somaQuadrados / retornos.length).toDouble();
  }

  static double _calcularRetornoMedio(List<double> precos) {
    if (precos.length < 2) return 0;

    double soma = 0;
    for (int i = 1; i < precos.length; i++) {
      soma += (precos[i] - precos[i - 1]) / precos[i - 1];
    }

    return soma / (precos.length - 1);
  }
}
