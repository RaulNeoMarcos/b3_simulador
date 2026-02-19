/// Tipos de proventos pagos por ações
enum TipoProvento {
  dividendo, // Dividendos
  jcp, // Juros sobre Capital Próprio
  rendimento, // Rendimentos (FIIs)
  bonificacao, // Bonificação em ações
  desdobramento, // Split/Desdobramento
  agrupamento, // Inplit/Agrupamento
}

/// Representa um provento (dividendo, JCP, etc.) pago por um ativo
class Provento {
  final String ticker;
  final DateTime dataPagamento;
  final DateTime? dataEx; // Data "ex" (a partir da qual não tem direito)
  final DateTime? dataAprovacao; // Data de aprovação
  final TipoProvento tipo;
  final double valorPorAcao; // Valor pago por ação
  final String? descricao;
  final double? percentual; // Percentual em relação ao preço (opcional)
  final String? moeda; // BRL, USD, etc.

  Provento({
    required this.ticker,
    required this.dataPagamento,
    required this.tipo,
    required this.valorPorAcao,
    this.dataEx,
    this.dataAprovacao,
    this.descricao,
    this.percentual,
    this.moeda = 'BRL',
  });

  /// Verifica se o provento é do tipo que paga em dinheiro
  bool get isPagamentoEmDinheiro =>
      tipo == TipoProvento.dividendo ||
      tipo == TipoProvento.jcp ||
      tipo == TipoProvento.rendimento;

  /// Verifica se o provento é do tipo que altera a quantidade de ações
  bool get isAlteracaoQuantidade =>
      tipo == TipoProvento.bonificacao ||
      tipo == TipoProvento.desdobramento ||
      tipo == TipoProvento.agrupamento;

  /// Formata o tipo para exibição
  String get tipoFormatado {
    switch (tipo) {
      case TipoProvento.dividendo:
        return 'Dividendo';
      case TipoProvento.jcp:
        return 'JCP';
      case TipoProvento.rendimento:
        return 'Rendimento';
      case TipoProvento.bonificacao:
        return 'Bonificação';
      case TipoProvento.desdobramento:
        return 'Desdobramento';
      case TipoProvento.agrupamento:
        return 'Agrupamento';
    }
  }

  /// Formata o valor para exibição
  String valorFormatado({bool compacto = false}) {
    if (compacto && valorPorAcao >= 1000) {
      return 'R\$ ${(valorPorAcao / 1000).toStringAsFixed(2)}k';
    }
    return 'R\$ ${valorPorAcao.toStringAsFixed(2)}';
  }

  @override
  String toString() =>
      '$ticker - $tipoFormatado: $valorFormatado() em ${dataPagamento.dataFormatada}';

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'ticker': ticker,
    'dataPagamento': dataPagamento.toIso8601String(),
    'dataEx': dataEx?.toIso8601String(),
    'dataAprovacao': dataAprovacao?.toIso8601String(),
    'tipo': tipo.index,
    'valorPorAcao': valorPorAcao,
    'descricao': descricao,
    'percentual': percentual,
    'moeda': moeda,
  };

  /// Constrói a partir de JSON
  factory Provento.fromJson(Map<String, dynamic> json) => Provento(
    ticker: json['ticker'],
    dataPagamento: DateTime.parse(json['dataPagamento']),
    dataEx: json['dataEx'] != null ? DateTime.parse(json['dataEx']) : null,
    dataAprovacao: json['dataAprovacao'] != null
        ? DateTime.parse(json['dataAprovacao'])
        : null,
    tipo: TipoProvento.values[json['tipo']],
    valorPorAcao: json['valorPorAcao']?.toDouble() ?? 0,
    descricao: json['descricao'],
    percentual: json['percentual']?.toDouble(),
    moeda: json['moeda'] ?? 'BRL',
  );
}

/// Extensão para facilitar formatação de datas em Provento
extension DateTimeFormat on DateTime {
  String get dataFormatada =>
      '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
}
