// lib/services/renda_fixa_service.dart

import 'dart:math';
import 'package:b3_simulador/models/comparativo_renda_fixa.dart';
import 'package:b3_simulador/models/taxa_historica.dart';
import 'package:b3_simulador/services/dados_historicos_service.dart';

class RendaFixaService {
  final DadosHistoricosService _dadosService = DadosHistoricosService();

  // Cache de taxas por período
  List<TaxaHistorica>? _taxasCache;
  DateTime? _cacheInicio;
  DateTime? _cacheFim;

  // Constantes
  static const double LIMIAR_SELIC_POUPANCA = 8.5;
  static const double RENDIMENTO_FIXO_POUPANCA = 0.005; // 0.5% ao mês
  static const double PERCENTUAL_SELIC_POUPANCA = 0.7; // 70% da Selic

  /// Calcula comparativo completo entre poupança e CDI
  Future<ComparativoRendaFixa> compararRendaFixa({
    required double valorInicial,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    // Validações
    if (valorInicial <= 0) throw Exception('Valor inicial deve ser positivo');
    if (dataInicio.isAfter(dataFim)) {
      throw Exception('Data início não pode ser após data fim');
    }

    print(
      '📊 Calculando renda fixa de ${_formatarData(dataInicio)} a ${_formatarData(dataFim)}',
    );

    // Busca taxas do período
    await _carregarTaxas(dataInicio, dataFim);

    // Calcula rendimentos
    final valorFinalPoupanca = await _calcularPoupanca(
      valorInicial: valorInicial,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );

    final valorFinalCDI = await _calcularCDI(
      valorInicial: valorInicial,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );

    final rendimentoPoupanca = valorFinalPoupanca - valorInicial;
    final rendimentoCDI = valorFinalCDI - valorInicial;

    final percentualPoupanca = valorInicial > 0
        ? (rendimentoPoupanca / valorInicial) * 100
        : 0.0;
    final percentualCDI = valorInicial > 0
        ? (rendimentoCDI / valorInicial) * 100
        : 0.0;

    print(
      '✅ Resultados - Poupança: ${_formatarMoeda(valorFinalPoupanca)} (${percentualPoupanca.toStringAsFixed(2)}%)',
    );
    print(
      '✅ Resultados - CDI: ${_formatarMoeda(valorFinalCDI)} (${percentualCDI.toStringAsFixed(2)}%)',
    );

    return ComparativoRendaFixa(
      valorInicial: valorInicial,
      dataInicio: dataInicio,
      dataFim: dataFim,
      valorFinalPoupanca: valorFinalPoupanca,
      rendimentoPoupanca: rendimentoPoupanca,
      percentualPoupanca: percentualPoupanca,
      valorFinalCDI: valorFinalCDI,
      rendimentoCDI: rendimentoCDI,
      percentualCDI: percentualCDI,
    );
  }

  /// Carrega as taxas para o período
  Future<void> _carregarTaxas(DateTime inicio, DateTime fim) async {
    // Se já tiver cache para o período, usa
    if (_taxasCache != null &&
        _cacheInicio != null &&
        _cacheFim != null &&
        !inicio.isBefore(_cacheInicio!) &&
        !fim.isAfter(_cacheFim!)) {
      print('📦 Usando cache de taxas');
      return;
    }

    print('🔄 Carregando taxas do BCB...');

    // Busca novas taxas
    _taxasCache = await _dadosService.getTaxasPorPeriodo(
      inicio: inicio,
      fim: fim,
    );

    _cacheInicio = inicio;
    _cacheFim = fim;

    print('✅ Carregadas ${_taxasCache?.length} taxas mensais');
  }

  /// Calcula rendimento da poupança (CORRIGIDO)
  Future<double> _calcularPoupanca({
    required double valorInicial,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    if (_taxasCache == null || _taxasCache!.isEmpty) {
      print('⚠️ Sem taxas para calcular poupança');
      return valorInicial;
    }

    double valorAtual = valorInicial;
    int mesesAplicados = 0;

    print('\n💰 CALCULANDO POUPANÇA');
    print('=' * 50);
    print('Valor inicial: ${_formatarMoeda(valorInicial)}');
    print('Período: ${_formatarData(dataInicio)} a ${_formatarData(dataFim)}');
    print('Total de taxas carregadas: ${_taxasCache!.length}');
    print('=' * 50);

    // Filtra apenas os meses dentro do período
    final mesesNoPeriodo = _taxasCache!
        .where(
          (taxa) =>
              !taxa.data.isBefore(dataInicio) && !taxa.data.isAfter(dataFim),
        )
        .toList();

    print('Meses no período: ${mesesNoPeriodo.length}');

    for (var taxa in mesesNoPeriodo) {
      mesesAplicados++;

      double rendimentoMensal;

      if (taxa.selic > 8.5) {
        rendimentoMensal = 0.005 + taxa.tr;
        print('Mês ${mesesAplicados}: ${taxa.data.month}/${taxa.data.year}');
        print('  Selic: ${taxa.selic.toStringAsFixed(2)}% (>8.5%)');
        print('  TR: ${(taxa.tr * 100).toStringAsFixed(3)}%');
        print(
          '  Rendimento: 0.5% + ${(taxa.tr * 100).toStringAsFixed(3)}% = ${(rendimentoMensal * 100).toStringAsFixed(3)}%',
        );
      } else {
        final selicMensal = taxa.selic / 12 / 100;
        rendimentoMensal = 0.7 * selicMensal + taxa.tr;
        print('Mês ${mesesAplicados}: ${taxa.data.month}/${taxa.data.year}');
        print('  Selic: ${taxa.selic.toStringAsFixed(2)}% (≤8.5%)');
        print('  Selic mensal: ${(selicMensal * 100).toStringAsFixed(3)}%');
        print('  TR: ${(taxa.tr * 100).toStringAsFixed(3)}%');
        print(
          '  Rendimento: 70% de ${(selicMensal * 100).toStringAsFixed(3)}% + ${(taxa.tr * 100).toStringAsFixed(3)}% = ${(rendimentoMensal * 100).toStringAsFixed(3)}%',
        );
      }

      valorAtual = valorAtual * (1 + rendimentoMensal);
      print('  Valor após mês: ${_formatarMoeda(valorAtual)}');
      print(
        '  Acumulado: ${((valorAtual / valorInicial - 1) * 100).toStringAsFixed(2)}%',
      );
      print('-' * 40);
    }

    print('=' * 50);
    print('RESULTADO FINAL POUPANÇA:');
    print('Valor final: ${_formatarMoeda(valorAtual)}');
    print('Rendimento total: ${_formatarMoeda(valorAtual - valorInicial)}');
    print(
      'Percentual: ${((valorAtual / valorInicial - 1) * 100).toStringAsFixed(2)}%',
    );
    print('=' * 50);

    return valorAtual;
  }

  /// Calcula rendimento do CDI com imposto de renda (CORRIGIDO)
  Future<double> _calcularCDI({
    required double valorInicial,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    double valorAtual = valorInicial;
    int mesesAplicados = 0;

    for (var taxa in _taxasCache!) {
      // taxa.cdi = 9.9 (percentual ao ano)
      final cdiPercentualMensal = taxa.cdi / 12; // 0.825% ao mês
      final cdiDecimalMensal = cdiPercentualMensal / 100; // 0.00825

      print('Mês ${taxa.data.month}/${taxa.data.year}:');
      print('  CDI anual: ${taxa.cdi}%');
      print('  CDI mensal: ${cdiPercentualMensal.toStringAsFixed(3)}%');
      print('  Fator: ${(1 + cdiDecimalMensal).toStringAsFixed(5)}');

      valorAtual = valorAtual * (1 + cdiDecimalMensal);
      mesesAplicados++;
    }

    //return valorAtual;

    // Calcula o rendimento bruto
    final rendimentoBruto = valorAtual - valorInicial;

    // Calcula o imposto de renda conforme prazo
    final diasInvestimento = dataFim.difference(dataInicio).inDays;
    final aliquotaIR = _getAliquotaIR(diasInvestimento);
    final imposto = rendimentoBruto * aliquotaIR;

    // Aplica o imposto (o IR é cobrado apenas sobre o rendimento)
    final valorLiquido = valorInicial + (rendimentoBruto - imposto);

    print(
      '💰 CDI bruto após $mesesAplicados meses: ${_formatarMoeda(valorAtual)}',
    );
    print('💰 Rendimento bruto: ${_formatarMoeda(rendimentoBruto)}');
    print(
      '💰 Alíquota IR: ${(aliquotaIR * 100).toStringAsFixed(1)}% (${diasInvestimento} dias)',
    );
    print('💰 Imposto: ${_formatarMoeda(imposto)}');
    print('💰 CDI líquido: ${_formatarMoeda(valorLiquido)}');

    return valorLiquido;
  }

  // Future<double> _calcularCDI({
  //   required double valorInicial,
  //   required DateTime dataInicio,
  //   required DateTime dataFim,
  // }) async {
  //   if (_taxasCache == null || _taxasCache!.isEmpty) {
  //     print('⚠️ Sem taxas para calcular CDI');
  //     return valorInicial;
  //   }

  //   double valorAtual = valorInicial;
  //   int mesesAplicados = 0;
  //   double rendimentoAcumulado = 0;

  //   print('💰 Calculando CDI - Valor inicial: ${_formatarMoeda(valorInicial)}');

  //   // Filtra apenas os meses dentro do período
  //   final mesesNoPeriodo = _taxasCache!
  //       .where(
  //         (taxa) =>
  //             !taxa.data.isBefore(dataInicio) && !taxa.data.isAfter(dataFim),
  //       )
  //       .toList();

  //   for (var taxa in mesesNoPeriodo) {
  //     // CDI anual convertido para mensal (decimal)
  //     final cdiMensal = (taxa.cdi / 12) / 100;

  //     valorAtual = valorAtual * (1 + cdiMensal);
  //     mesesAplicados++;

  //     print(
  //       '📈 Mês ${taxa.data.month}/${taxa.data.year}: CDI ${(cdiMensal * 100).toStringAsFixed(3)}% → Acumulado: ${((valorAtual / valorInicial - 1) * 100).toStringAsFixed(2)}%',
  //     );
  //   }

  //   // Calcula o rendimento bruto
  //   final rendimentoBruto = valorAtual - valorInicial;

  //   // Calcula o imposto de renda conforme prazo
  //   final diasInvestimento = dataFim.difference(dataInicio).inDays;
  //   final aliquotaIR = _getAliquotaIR(diasInvestimento);
  //   final imposto = rendimentoBruto * aliquotaIR;

  //   // Aplica o imposto (o IR é cobrado apenas sobre o rendimento)
  //   final valorLiquido = valorInicial + (rendimentoBruto - imposto);

  //   print(
  //     '💰 CDI bruto após $mesesAplicados meses: ${_formatarMoeda(valorAtual)}',
  //   );
  //   print('💰 Rendimento bruto: ${_formatarMoeda(rendimentoBruto)}');
  //   print(
  //     '💰 Alíquota IR: ${(aliquotaIR * 100).toStringAsFixed(1)}% (${diasInvestimento} dias)',
  //   );
  //   print('💰 Imposto: ${_formatarMoeda(imposto)}');
  //   print('💰 CDI líquido: ${_formatarMoeda(valorLiquido)}');

  //   return valorLiquido;
  // }

  /// Retorna alíquota de IR baseada no tempo de investimento
  double _getAliquotaIR(int dias) {
    if (dias <= 180) return 0.225; // 22.5% até 180 dias
    if (dias <= 360) return 0.20; // 20% de 181 a 360 dias
    if (dias <= 720) return 0.175; // 17.5% de 361 a 720 dias
    return 0.15; // 15% acima de 720 dias
  }

  /// Calcula rendimento da poupança de forma simplificada
  double calcularPoupancaSimples({
    required double valorInicial,
    required int meses,
    double selicMedia = 10.0,
    double trMedia = 0.1,
  }) {
    double valorAtual = valorInicial;
    double rendimentoMensal;

    if (selicMedia > LIMIAR_SELIC_POUPANCA) {
      rendimentoMensal = RENDIMENTO_FIXO_POUPANCA + (trMedia / 100);
    } else {
      final selicMensal = (selicMedia / 12) / 100;
      rendimentoMensal =
          PERCENTUAL_SELIC_POUPANCA * selicMensal + (trMedia / 100);
    }

    for (int i = 0; i < meses; i++) {
      valorAtual = valorAtual * (1 + rendimentoMensal);
    }

    return valorAtual;
  }

  /// Calcula rendimento do CDI de forma simplificada
  double calcularCDISimples({
    required double valorInicial,
    required int meses,
    required double cdiMedia,
  }) {
    double valorAtual = valorInicial;
    final cdiMensal = (cdiMedia / 12) / 100;

    for (int i = 0; i < meses; i++) {
      valorAtual = valorAtual * (1 + cdiMensal);
    }

    // Aplica IR aproximado baseado no prazo
    final rendimentoBruto = valorAtual - valorInicial;
    final aliquotaIR = _getAliquotaIR(meses * 30); // Aproximação
    final imposto = rendimentoBruto * aliquotaIR;

    return valorAtual - imposto;
  }

  /// Formata valor para exibição
  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }

  /// Formata data para logging
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  /// Limpa o cache
  void limparCache() {
    _taxasCache = null;
    _cacheInicio = null;
    _cacheFim = null;
    _dadosService.limparCache();
  }
}
