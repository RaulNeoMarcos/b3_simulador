// lib/services/renda_fixa_service.dart

import 'dart:math';
import 'package:b3_simulador/models/comparativo_renda_fixa.dart';
import 'package:b3_simulador/models/taxa_historica.dart';
import 'package:b3_simulador/services/dados_historicos_service.dart';
import 'package:b3_simulador/services/logger_service.dart';

class RendaFixaService {
  final LoggerService _log = LoggerService();
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
    _log.info(
      'Iniciando comparação renda fixa',
      tag: 'RF',
      data: {
        'valor_inicial': valorInicial,
        'data_inicio': dataInicio.toIso8601String(),
        'data_fim': dataFim.toIso8601String(),
      },
    );

    try {
      await _carregarTaxas(dataInicio, dataFim);

      _log.debug('Calculando poupança...', tag: 'RF');
      final valorFinalPoupanca = await _calcularPoupanca(
        valorInicial: valorInicial,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      _log.debug('Calculando CDI...', tag: 'RF');
      final valorFinalCDI = await _calcularCDI(
        valorInicial: valorInicial,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      final resultado = ComparativoRendaFixa(
        valorInicial: valorInicial,
        dataInicio: dataInicio,
        dataFim: dataFim,
        valorFinalPoupanca: valorFinalPoupanca,
        rendimentoPoupanca: valorFinalPoupanca - valorInicial,
        percentualPoupanca: ((valorFinalPoupanca / valorInicial - 1) * 100),
        valorFinalCDI: valorFinalCDI,
        rendimentoCDI: valorFinalCDI - valorInicial,
        percentualCDI: ((valorFinalCDI / valorInicial - 1) * 100),
      );

      _log.info(
        'Comparação concluída',
        tag: 'RF',
        data: {
          'poupanca_final': valorFinalPoupanca,
          'cdi_final': valorFinalCDI,
          'diferenca': valorFinalCDI - valorFinalPoupanca,
        },
      );

      return resultado;
    } catch (e, stackTrace) {
      _log.error(
        'Erro na comparação renda fixa',
        tag: 'RF',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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
      _log.warning('Sem taxas para calcular poupança', tag: 'RF');
      return valorInicial;
    }

    double valorAtual = valorInicial;
    int mesesAplicados = 0;

    _log.debug(
      'Iniciando cálculo poupança',
      tag: 'RF',
      data: {'valor_inicial': valorInicial, 'total_taxas': _taxasCache!.length},
    );

    final mesesNoPeriodo = _taxasCache!
        .where(
          (taxa) =>
              !taxa.data.isBefore(dataInicio) && !taxa.data.isAfter(dataFim),
        )
        .toList();

    for (var taxa in mesesNoPeriodo) {
      mesesAplicados++;

      double rendimentoMensal;
      String regra;

      if (taxa.selic > 8.5) {
        rendimentoMensal = 0.005 + taxa.tr;
        regra = 'selic > 8.5%';
      } else {
        final selicMensal = taxa.selic / 12 / 100;
        rendimentoMensal = 0.7 * selicMensal + taxa.tr;
        regra = 'selic <= 8.5%';
      }

      valorAtual = valorAtual * (1 + rendimentoMensal);

      _log.debug(
        'Mês $mesesAplicados processado',
        tag: 'RF',
        data: {
          'data': '${taxa.data.month}/${taxa.data.year}',
          'selic': taxa.selic,
          'tr': taxa.tr,
          'regra': regra,
          'rendimento': rendimentoMensal * 100,
          'valor_atual': valorAtual,
        },
      );
    }

    _log.info(
      'Cálculo poupança finalizado',
      tag: 'RF',
      data: {
        'valor_final': valorAtual,
        'rendimento_total': valorAtual - valorInicial,
        'percentual': ((valorAtual / valorInicial - 1) * 100),
      },
    );

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
