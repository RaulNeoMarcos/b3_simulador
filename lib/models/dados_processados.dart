import 'package:b3_simulador/models/cotacao.dart';
import 'package:b3_simulador/models/provento.dart';

/// Classe auxiliar para dados processados
class DadosProcessados {
  final Cotacao cotacaoInicial;
  final Cotacao cotacaoFinal;
  final double quantidadeAcoes;
  final double valorApreciacao;
  final double totalDividendos;
  final double valorFinalTotal;
  final double lucro;
  final double percentual;
  final List<Provento> proventosRecebidos;
  final Map<TipoProvento, double> proventosPorTipo;
  final double? retornoAnualizado;
  final double? volatilidade;
  final double? maiorPreco;
  final double? menorPreco;
  final DateTime? dataMaiorPreco;
  final DateTime? dataMenorPreco;

  DadosProcessados({
    required this.cotacaoInicial,
    required this.cotacaoFinal,
    required this.quantidadeAcoes,
    required this.valorApreciacao,
    required this.totalDividendos,
    required this.valorFinalTotal,
    required this.lucro,
    required this.percentual,
    required this.proventosRecebidos,
    required this.proventosPorTipo,
    this.retornoAnualizado,
    this.volatilidade,
    this.maiorPreco,
    this.menorPreco,
    this.dataMaiorPreco,
    this.dataMenorPreco,
  });
}

/// Classe auxiliar para processamento de dividendos
class ProcessamentoDividendos {
  final double totalDividendos;
  final List<Provento> proventosRecebidos;
  final Map<TipoProvento, double> proventosPorTipo;

  ProcessamentoDividendos({
    required this.totalDividendos,
    required this.proventosRecebidos,
    required this.proventosPorTipo,
  });
}
