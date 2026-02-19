/// Representa um ativo (ação) negociado na bolsa
class Ativo {
  final String ticker; // Código da ação (ex: PETR4)
  final String nome; // Nome da empresa
  final String? setor; // Setor de atuação
  final String? tipo; // ON, PN, Units, etc.
  final String? mercado; // B3, NYSE, etc.

  Ativo({
    required this.ticker,
    required this.nome,
    this.setor,
    this.tipo,
    this.mercado,
  });

  /// Construtor para ações brasileiras (já formata ticker)
  factory Ativo.brasil(String ticker, String nome) {
    return Ativo(
      ticker: ticker.toUpperCase(),
      nome: nome,
      mercado: 'B3',
      tipo: _extrairTipo(ticker),
    );
  }

  /// Extrai o tipo da ação (PN, ON, Units) baseado no ticker
  static String? _extrairTipo(String ticker) {
    final tickerUpper = ticker.toUpperCase();
    if (tickerUpper.endsWith('3')) return 'ON';
    if (tickerUpper.endsWith('4')) return 'PN';
    if (tickerUpper.endsWith('11')) return 'Units';
    return null;
  }

  /// Retorna o ticker formatado para APIs (adiciona .SA)
  String get tickerParaAPI => ticker.contains('.') ? ticker : '$ticker.SA';

  @override
  String toString() => '$ticker - $nome';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ativo && other.ticker == ticker;
  }

  @override
  int get hashCode => ticker.hashCode;

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'ticker': ticker,
    'nome': nome,
    'setor': setor,
    'tipo': tipo,
    'mercado': mercado,
  };

  /// Constrói a partir de JSON
  factory Ativo.fromJson(Map<String, dynamic> json) => Ativo(
    ticker: json['ticker'],
    nome: json['nome'],
    setor: json['setor'],
    tipo: json['tipo'],
    mercado: json['mercado'],
  );
}
