/// Representa uma cotação histórica de um ativo
class Cotacao {
  final DateTime data;
  final double abertura; // Preço de abertura
  final double fechamento; // Preço de fechamento
  final double maxima; // Preço máximo do dia
  final double minima; // Preço mínimo do dia
  final double volume; // Volume negociado
  final double? ajustado; // Preço ajustado por proventos (opcional)
  final String? ticker; // Ticker do ativo (para referência)

  Cotacao({
    required this.data,
    required this.abertura,
    required this.fechamento,
    required this.maxima,
    required this.minima,
    required this.volume,
    this.ajustado,
    this.ticker,
  });

  /// Construtor simplificado apenas com fechamento
  Cotacao.simplificado({
    required this.data,
    required double precoFechamento,
    this.ticker,
  }) : abertura = precoFechamento,
       fechamento = precoFechamento,
       maxima = precoFechamento,
       minima = precoFechamento,
       volume = 0,
       ajustado = null;

  /// Variacao percentual em relação ao dia anterior
  double? variacaoPercentual(Cotacao anterior) {
    if (anterior.fechamento == 0) return null;
    return ((fechamento - anterior.fechamento) / anterior.fechamento) * 100;
  }

  /// Verifica se é final de semana
  bool get isFinalDeSemana =>
      data.weekday == DateTime.saturday || data.weekday == DateTime.sunday;

  /// Formata a data para exibição
  String get dataFormatada =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

  @override
  String toString() => '$dataFormatada: R\$ $fechamento';

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'data': data.toIso8601String(),
    'abertura': abertura,
    'fechamento': fechamento,
    'maxima': maxima,
    'minima': minima,
    'volume': volume,
    'ajustado': ajustado,
    'ticker': ticker,
  };

  /// Constrói a partir de JSON
  factory Cotacao.fromJson(Map<String, dynamic> json) => Cotacao(
    data: DateTime.parse(json['data']),
    abertura: json['abertura']?.toDouble() ?? 0,
    fechamento: json['fechamento']?.toDouble() ?? 0,
    maxima: json['maxima']?.toDouble() ?? 0,
    minima: json['minima']?.toDouble() ?? 0,
    volume: json['volume']?.toDouble() ?? 0,
    ajustado: json['ajustado']?.toDouble(),
    ticker: json['ticker'],
  );
}
