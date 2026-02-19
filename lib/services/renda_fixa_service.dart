import 'package:b3_simulador/models/comparativo_renda_fixa.dart';
import 'package:b3_simulador/models/taxa_historica.dart';
import 'package:b3_simulador/services/dados_historicos_service.dart';

class RendaFixaService {
  final DadosHistoricosService _dadosService = DadosHistoricosService();

  // Cache de taxas por período
  List<TaxaHistorica>? _taxasCache;
  DateTime? _cacheInicio;
  DateTime? _cacheFim;

  /// Calcula comparativo completo entre poupança e CDI
  Future<ComparativoRendaFixa> compararRendaFixa({
    required double valorInicial,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    // Validações
    if (valorInicial <= 0) throw Exception('Valor inicial deve ser positivo');
    if (dataInicio.isAfter(dataFim))
      throw Exception('Data início não pode ser após data fim');

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
        ? ((rendimentoPoupanca / valorInicial) * 100).toDouble()
        : 0.0;
    final percentualCDI = valorInicial > 0
        ? ((rendimentoCDI / valorInicial) * 100).toDouble()
        : 0.0;

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
        _cacheInicio!.isBefore(inicio) &&
        _cacheFim!.isAfter(fim)) {
      return;
    }

    // Busca novas taxas
    _taxasCache = await _dadosService.getTaxasPorPeriodo(
      inicio: inicio,
      fim: fim,
    );

    _cacheInicio = inicio;
    _cacheFim = fim;
  }

  /// Calcula rendimento da poupança
  Future<double> _calcularPoupanca({
    required double valorInicial,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    double valorAtual = valorInicial;

    if (_taxasCache == null || _taxasCache!.isEmpty) {
      return valorInicial;
    }

    // Mês a mês, aplica o rendimento
    for (var taxa in _taxasCache!) {
      // Só aplica se a data do mês estiver dentro do período
      if (taxa.data.isBefore(dataInicio) || taxa.data.isAfter(dataFim)) {
        continue;
      }

      double rendimentoMensal;

      // Regra da poupança
      if (taxa.selic > 8.5) {
        // Acima de 8.5%: 0.5% ao mês + TR
        rendimentoMensal = 0.005 + (taxa.tr / 100);
      } else {
        // Abaixo ou igual: 70% da Selic ao ano (convertido para mensal)
        final selicMensal = (taxa.selic / 12) / 100; // decimal
        rendimentoMensal = 0.7 * selicMensal + (taxa.tr / 100);
      }

      valorAtual = valorAtual * (1 + rendimentoMensal);
    }

    return valorAtual;
  }

  /// Calcula rendimento do CDI com imposto de renda
  Future<double> _calcularCDI({
    required double valorInicial,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    double valorAtual = valorInicial;

    if (_taxasCache == null || _taxasCache!.isEmpty) {
      return valorInicial;
    }

    // Aplica rendimentos mês a mês
    for (var taxa in _taxasCache!) {
      if (taxa.data.isBefore(dataInicio) || taxa.data.isAfter(dataFim)) {
        continue;
      }

      // CDI anual convertido para mensal (decimal)
      final cdiMensal = (taxa.cdi / 12) / 100;
      valorAtual = valorAtual * (1 + cdiMensal);
    }

    // Calcula imposto de renda
    final diasInvestimento = dataFim.difference(dataInicio).inDays;
    final aliquotaIR = _getAliquotaIR(diasInvestimento);
    final rendimentoBruto = valorAtual - valorInicial;
    final imposto = rendimentoBruto * aliquotaIR;
    final valorLiquido = valorAtual - imposto;

    return valorLiquido;
  }

  /// Retorna alíquota de IR baseada no tempo de investimento
  double _getAliquotaIR(int dias) {
    if (dias <= 180) return 0.225; // 22.5%
    if (dias <= 360) return 0.20; // 20%
    if (dias <= 720) return 0.175; // 17.5%
    return 0.15; // 15%
  }

  /// Calcula rendimento da poupança de forma simplificada
  double calcularPoupancaSimples({
    required double valorInicial,
    required int meses,
    double selicMedia = 10.0,
    double trMedia = 0.1,
  }) {
    double valorAtual = valorInicial;

    for (int i = 0; i < meses; i++) {
      double rendimentoMensal;

      if (selicMedia > 8.5) {
        rendimentoMensal = 0.005 + (trMedia / 100);
      } else {
        final selicMensal = (selicMedia / 12) / 100;
        rendimentoMensal = 0.7 * selicMensal + (trMedia / 100);
      }

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

    // Aplica IR aproximado (média de 17.5%)
    final rendimentoBruto = valorAtual - valorInicial;
    final imposto = rendimentoBruto * 0.175;

    return valorAtual - imposto;
  }

  /// Limpa o cache
  void limparCache() {
    _taxasCache = null;
    _cacheInicio = null;
    _cacheFim = null;
    _dadosService.limparCache();
  }
}
