/// Resultado da comparação com investimentos de renda fixa
class ComparativoRendaFixa {
  final double valorInicial;
  final DateTime dataInicio;
  final DateTime dataFim;

  // Resultados Poupança
  final double valorFinalPoupanca;
  final double rendimentoPoupanca;
  final double percentualPoupanca;

  // Resultados CDI
  final double valorFinalCDI;
  final double rendimentoCDI;
  final double percentualCDI;

  // Resultados Tesouro Selic (opcional - para versão futura)
  final double? valorFinalTesouro;
  final double? rendimentoTesouro;
  final double? percentualTesouro;

  ComparativoRendaFixa({
    required this.valorInicial,
    required this.dataInicio,
    required this.dataFim,
    required this.valorFinalPoupanca,
    required this.rendimentoPoupanca,
    required this.percentualPoupanca,
    required this.valorFinalCDI,
    required this.rendimentoCDI,
    required this.percentualCDI,
    this.valorFinalTesouro,
    this.rendimentoTesouro,
    this.percentualTesouro,
  });

  /// Qual investimento rendeu mais em valor absoluto?
  String get melhorInvestimento {
    final Map<String, double> valores = {
      'Poupança': valorFinalPoupanca,
      'CDI': valorFinalCDI,
    };
    if (valorFinalTesouro != null) {
      valores['Tesouro Selic'] = valorFinalTesouro!;
    }

    final melhor = valores.entries.reduce((a, b) => a.value > b.value ? a : b);
    return melhor.key;
  }

  /// Diferença percentual entre CDI e Poupança
  double get diferencialCDIvsPoupanca => percentualCDI - percentualPoupanca;

  /// Retorna o valor final do investimento com base no tipo
  double valorFinalPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'poupança':
      case 'poupanca':
        return valorFinalPoupanca;
      case 'cdi':
        return valorFinalCDI;
      case 'tesouro':
      case 'tesouro selic':
        return valorFinalTesouro ?? 0;
      default:
        return 0;
    }
  }

  /// Gera um resumo textual da comparação
  String resumoComparativo(double retornoAcao) {
    final buffer = StringBuffer();
    buffer.writeln('Comparativo de Investimentos:');
    buffer.writeln('📈 Ação: ${_formatPercent(retornoAcao)}');
    buffer.writeln('🏦 Poupança: ${_formatPercent(percentualPoupanca)}');
    buffer.writeln('📊 CDI (líquido): ${_formatPercent(percentualCDI)}');

    if (retornoAcao > percentualCDI && retornoAcao > percentualPoupanca) {
      buffer.writeln('✅ Ação superou todos os investimentos!');
    } else if (retornoAcao > percentualPoupanca) {
      buffer.writeln('⚠️ Ação superou a poupança, mas ficou abaixo do CDI.');
    } else {
      buffer.writeln('📉 Ação teve desempenho inferior à renda fixa.');
    }

    return buffer.toString();
  }

  String _formatPercent(double value) => '${value.toStringAsFixed(2)}%';

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'valorInicial': valorInicial,
    'dataInicio': dataInicio.toIso8601String(),
    'dataFim': dataFim.toIso8601String(),
    'valorFinalPoupanca': valorFinalPoupanca,
    'rendimentoPoupanca': rendimentoPoupanca,
    'percentualPoupanca': percentualPoupanca,
    'valorFinalCDI': valorFinalCDI,
    'rendimentoCDI': rendimentoCDI,
    'percentualCDI': percentualCDI,
    'valorFinalTesouro': valorFinalTesouro,
    'rendimentoTesouro': rendimentoTesouro,
    'percentualTesouro': percentualTesouro,
  };

  /// Constrói a partir de JSON
  factory ComparativoRendaFixa.fromJson(Map<String, dynamic> json) =>
      ComparativoRendaFixa(
        valorInicial: json['valorInicial']?.toDouble() ?? 0,
        dataInicio: DateTime.parse(json['dataInicio']),
        dataFim: DateTime.parse(json['dataFim']),
        valorFinalPoupanca: json['valorFinalPoupanca']?.toDouble() ?? 0,
        rendimentoPoupanca: json['rendimentoPoupanca']?.toDouble() ?? 0,
        percentualPoupanca: json['percentualPoupanca']?.toDouble() ?? 0,
        valorFinalCDI: json['valorFinalCDI']?.toDouble() ?? 0,
        rendimentoCDI: json['rendimentoCDI']?.toDouble() ?? 0,
        percentualCDI: json['percentualCDI']?.toDouble() ?? 0,
        valorFinalTesouro: json['valorFinalTesouro']?.toDouble(),
        rendimentoTesouro: json['rendimentoTesouro']?.toDouble(),
        percentualTesouro: json['percentualTesouro']?.toDouble(),
      );
}
