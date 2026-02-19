import 'package:b3_simulador/models/cotacao.dart';
import 'package:flutter/material.dart';
import 'ativo.dart';
import 'provento.dart';
import 'comparativo_renda_fixa.dart';

/// Resultado completo da simulação de investimento
class ResultadoSimulacao {
  // Dados do investimento
  final Ativo ativo;
  final DateTime dataInicio;
  final DateTime dataFim;
  final double valorInvestido;

  // Cotações
  final Cotacao cotacaoInicial;
  final Cotacao cotacaoFinal;
  final List<Cotacao> historicoCotacoes;

  // Quantidade de ações
  final double quantidadeAcoes;

  // Resultados da ação
  final double valorApreciacao; // Valor apenas com variação do preço
  final double totalDividendos; // Total de proventos recebidos
  final double valorFinalTotal; // Apreciação + dividendos
  final double lucroPrejuizo; // ValorFinalTotal - ValorInvestido
  final double percentualRetorno; // (Lucro / ValorInvestido) * 100

  // Detalhamento de proventos
  final List<Provento> proventosRecebidos;
  final Map<TipoProvento, double> proventosPorTipo;

  // Comparativo com renda fixa
  final ComparativoRendaFixa? comparativoRendaFixa;

  // Métricas adicionais
  final double? retornoAnualizado; // CAGR - retorno anual composto
  final int diasCorridos; // Dias totais do investimento
  final int diasUteis; // Dias úteis (aproximado)
  final double? volatilidade; // Volatilidade no período
  final double? maiorPreco; // Maior preço no período
  final double? menorPreco; // Menor preço no período
  final DateTime? dataMaiorPreco;
  final DateTime? dataMenorPreco;

  ResultadoSimulacao({
    required this.ativo,
    required this.dataInicio,
    required this.dataFim,
    required this.valorInvestido,
    required this.cotacaoInicial,
    required this.cotacaoFinal,
    required this.historicoCotacoes,
    required this.quantidadeAcoes,
    required this.valorApreciacao,
    required this.totalDividendos,
    required this.valorFinalTotal,
    required this.lucroPrejuizo,
    required this.percentualRetorno,
    required this.proventosRecebidos,
    required this.proventosPorTipo,
    this.comparativoRendaFixa,
    this.retornoAnualizado,
    this.volatilidade,
    this.maiorPreco,
    this.menorPreco,
    this.dataMaiorPreco,
    this.dataMenorPreco,
  }) : diasCorridos = dataFim.difference(dataInicio).inDays,
       diasUteis = _calcularDiasUteis(dataInicio, dataFim);

  /// Calcula aproximadamente dias úteis (considerando fins de semana)
  static int _calcularDiasUteis(DateTime inicio, DateTime fim) {
    int diasUteis = 0;
    var data = inicio;
    while (data.isBefore(fim)) {
      if (data.weekday != DateTime.saturday &&
          data.weekday != DateTime.sunday) {
        diasUteis++;
      }
      data = data.add(const Duration(days: 1));
    }
    return diasUteis;
  }

  /// Getters para formatação facilitada
  String get valorInvestidoFormatado =>
      'R\$ ${valorInvestido.toStringAsFixed(2)}';
  String get valorFinalFormatado => 'R\$ ${valorFinalTotal.toStringAsFixed(2)}';
  String get lucroFormatado => 'R\$ ${lucroPrejuizo.toStringAsFixed(2)}';
  String get percentualFormatado => '${percentualRetorno.toStringAsFixed(2)}%';
  String get dividendosFormatados =>
      'R\$ ${totalDividendos.toStringAsFixed(2)}';

  /// Cor do lucro/prejuízo (para UI)
  Color get corLucro => lucroPrejuizo >= 0 ? Colors.green : Colors.red;

  /// Ícone do resultado
  IconData get iconeResultado =>
      lucroPrejuizo >= 0 ? Icons.trending_up : Icons.trending_down;

  /// Verifica se o investimento teve retorno positivo
  bool get teveLucro => lucroPrejuizo > 0;

  /// Retorna o yield on cost (dividendos / valor investido)
  double get yieldOnCost => (totalDividendos / valorInvestido) * 100;

  /// Retorna o dividend yield médio anualizado
  double get dividendYieldMedio {
    final anos = diasCorridos / 365;
    if (anos == 0) return 0;
    return (totalDividendos / valorInvestido / anos) * 100;
  }

  /// Retorna o preço teto baseado nos dividendos (método Bazin)
  double? precoTetoBazin(double dividendoEsperadoAnual) {
    if (dividendoEsperadoAnual <= 0) return null;
    return (dividendoEsperadoAnual * 100) / 6; // 6% de yield
  }

  /// Gera um resumo completo do resultado
  String gerarResumoCompleto() {
    final buffer = StringBuffer();
    buffer.writeln('📊 RESULTADO DA SIMULAÇÃO');
    buffer.writeln('=' * 40);
    buffer.writeln('Ativo: ${ativo.ticker} - ${ativo.nome}');
    buffer.writeln(
      'Período: ${dataInicio.dataFormatada} a ${dataFim.dataFormatada}',
    );
    buffer.writeln('Dias: $diasCorridos ($diasUteis úteis)');
    buffer.writeln();
    buffer.writeln('💰 INVESTIMENTO');
    buffer.writeln('Valor inicial: $valorInvestidoFormatado');
    buffer.writeln('Ações compradas: ${quantidadeAcoes.toStringAsFixed(4)}');
    buffer.writeln(
      'Preço inicial: R\$ ${cotacaoInicial.fechamento.toStringAsFixed(2)}',
    );
    buffer.writeln(
      'Preço final: R\$ ${cotacaoFinal.fechamento.toStringAsFixed(2)}',
    );
    buffer.writeln();
    buffer.writeln('📈 RESULTADO');
    buffer.writeln('Apreciação: R\$ ${valorApreciacao.toStringAsFixed(2)}');
    buffer.writeln('Dividendos: $dividendosFormatados');
    buffer.writeln('Valor final: $valorFinalFormatado');
    buffer.writeln('Lucro/Prejuízo: $lucroFormatado ($percentualFormatado)');

    if (retornoAnualizado != null) {
      buffer.writeln(
        'Retorno anualizado: ${retornoAnualizado!.toStringAsFixed(2)}%',
      );
    }

    if (proventosRecebidos.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('💵 PROVENTOS POR TIPO');
      proventosPorTipo.forEach((tipo, valor) {
        final tipoStr = tipo.toString().split('.').last;
        buffer.writeln('$tipoStr: R\$ ${valor.toStringAsFixed(2)}');
      });
      buffer.writeln('Yield on cost: ${yieldOnCost.toStringAsFixed(2)}%');
    }

    if (comparativoRendaFixa != null) {
      buffer.writeln();
      buffer.writeln(
        comparativoRendaFixa!.resumoComparativo(percentualRetorno),
      );
    }

    return buffer.toString();
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'ativo': ativo.toJson(),
    'dataInicio': dataInicio.toIso8601String(),
    'dataFim': dataFim.toIso8601String(),
    'valorInvestido': valorInvestido,
    'cotacaoInicial': cotacaoInicial.toJson(),
    'cotacaoFinal': cotacaoFinal.toJson(),
    'historicoCotacoes': historicoCotacoes.map((c) => c.toJson()).toList(),
    'quantidadeAcoes': quantidadeAcoes,
    'valorApreciacao': valorApreciacao,
    'totalDividendos': totalDividendos,
    'valorFinalTotal': valorFinalTotal,
    'lucroPrejuizo': lucroPrejuizo,
    'percentualRetorno': percentualRetorno,
    'proventosRecebidos': proventosRecebidos.map((p) => p.toJson()).toList(),
    'proventosPorTipo': proventosPorTipo.map(
      (key, value) => MapEntry(key.index, value),
    ),
    'comparativoRendaFixa': comparativoRendaFixa?.toJson(),
    'retornoAnualizado': retornoAnualizado,
    'volatilidade': volatilidade,
    'maiorPreco': maiorPreco,
    'menorPreco': menorPreco,
    'dataMaiorPreco': dataMaiorPreco?.toIso8601String(),
    'dataMenorPreco': dataMenorPreco?.toIso8601String(),
    'diasCorridos': diasCorridos,
    'diasUteis': diasUteis,
  };

  /// Constrói a partir de JSON
  factory ResultadoSimulacao.fromJson(Map<String, dynamic> json) {
    final proventosMap = <TipoProvento, double>{};
    if (json['proventosPorTipo'] != null) {
      (json['proventosPorTipo'] as Map).forEach((key, value) {
        proventosMap[TipoProvento.values[int.parse(key.toString())]] = value
            .toDouble();
      });
    }

    return ResultadoSimulacao(
      ativo: Ativo.fromJson(json['ativo']),
      dataInicio: DateTime.parse(json['dataInicio']),
      dataFim: DateTime.parse(json['dataFim']),
      valorInvestido: json['valorInvestido']?.toDouble() ?? 0,
      cotacaoInicial: Cotacao.fromJson(json['cotacaoInicial']),
      cotacaoFinal: Cotacao.fromJson(json['cotacaoFinal']),
      historicoCotacoes: (json['historicoCotacoes'] as List)
          .map((c) => Cotacao.fromJson(c))
          .toList(),
      quantidadeAcoes: json['quantidadeAcoes']?.toDouble() ?? 0,
      valorApreciacao: json['valorApreciacao']?.toDouble() ?? 0,
      totalDividendos: json['totalDividendos']?.toDouble() ?? 0,
      valorFinalTotal: json['valorFinalTotal']?.toDouble() ?? 0,
      lucroPrejuizo: json['lucroPrejuizo']?.toDouble() ?? 0,
      percentualRetorno: json['percentualRetorno']?.toDouble() ?? 0,
      proventosRecebidos: (json['proventosRecebidos'] as List)
          .map((p) => Provento.fromJson(p))
          .toList(),
      proventosPorTipo: proventosMap,
      comparativoRendaFixa: json['comparativoRendaFixa'] != null
          ? ComparativoRendaFixa.fromJson(json['comparativoRendaFixa'])
          : null,
      retornoAnualizado: json['retornoAnualizado']?.toDouble(),
      volatilidade: json['volatilidade']?.toDouble(),
      maiorPreco: json['maiorPreco']?.toDouble(),
      menorPreco: json['menorPreco']?.toDouble(),
      dataMaiorPreco: json['dataMaiorPreco'] != null
          ? DateTime.parse(json['dataMaiorPreco'])
          : null,
      dataMenorPreco: json['dataMenorPreco'] != null
          ? DateTime.parse(json['dataMenorPreco'])
          : null,
    );
  }
}
