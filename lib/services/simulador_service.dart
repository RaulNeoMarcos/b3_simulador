// lib/services/simulador_service.dart

import 'dart:math';
import 'package:b3_simulador/models/ativo.dart';
import 'package:b3_simulador/models/cotacao.dart';
import 'package:b3_simulador/models/dados_processados.dart';
import 'package:b3_simulador/models/provento.dart';
import 'package:b3_simulador/models/resultado_simulacao.dart';
import 'package:b3_simulador/models/comparativo_renda_fixa.dart';
import 'package:b3_simulador/services/yahoo_finance_service.dart';
import 'package:b3_simulador/services/renda_fixa_service.dart';

class SimuladorService {
  final YahooFinanceService _yahooService = YahooFinanceService();
  final RendaFixaService _rendaFixaService = RendaFixaService();

  // Cache para evitar recálculos desnecessários
  final Map<String, ResultadoSimulacao> _cache = {};

  // Constantes
  static const int DIAS_UTEIS_POR_ANO = 252;

  /// Realiza a simulação completa do investimento
  Future<ResultadoSimulacao> simular({
    required String ticker,
    required DateTime dataInicio,
    required double valorInvestido,
    DateTime? dataFim,
    bool incluirComparacaoRendaFixa = true,
    bool usarCache = true,
  }) async {
    // Validações iniciais
    _validarParametros(ticker, valorInvestido, dataInicio);

    final dataFimReal = _ajustarDataFim(dataFim, dataInicio);

    // Gera chave de cache
    final cacheKey = _gerarCacheKey(
      ticker,
      dataInicio,
      dataFimReal,
      valorInvestido,
    );

    // Verifica cache
    if (usarCache && _cache.containsKey(cacheKey)) {
      print('📦 Usando cache para $ticker');
      return _cache[cacheKey]!;
    }

    try {
      // 1. Buscar dados da API Yahoo Finance
      print(
        '📡 Buscando dados para $ticker de ${_formatarData(dataInicio)} até ${_formatarData(dataFimReal)}',
      );

      final dados = await _yahooService.getDadosCompletos(
        ticker: ticker,
        dataInicio: dataInicio,
        dataFim: dataFimReal,
      );

      final cotacoes = dados['cotacoes'] as List<Cotacao>;
      final dividendos = dados['dividendos'] as List<Provento>;
      final ativo = dados['ativo'] as Ativo;

      if (cotacoes.isEmpty) {
        throw Exception('Nenhuma cotação encontrada para o período');
      }

      // 2. Ordenar e preparar dados
      final processamento = await _processarDados(
        cotacoes: cotacoes,
        dividendos: dividendos,
        ativo: ativo,
        dataInicio: dataInicio,
        dataFim: dataFimReal,
        valorInvestido: valorInvestido,
      );

      // 3. Calcular comparativo com renda fixa se solicitado
      ComparativoRendaFixa? comparativo;
      if (incluirComparacaoRendaFixa) {
        comparativo = await _calcularComparativoRendaFixa(
          valorInvestido: valorInvestido,
          dataInicio: dataInicio,
          dataFim: dataFimReal,
        );
      }

      // 4. Criar objeto de resultado
      final resultado = ResultadoSimulacao(
        ativo: ativo,
        dataInicio: dataInicio,
        dataFim: dataFimReal,
        valorInvestido: valorInvestido,
        cotacaoInicial: processamento.cotacaoInicial,
        cotacaoFinal: processamento.cotacaoFinal,
        historicoCotacoes: cotacoes,
        quantidadeAcoes: processamento.quantidadeAcoes,
        valorApreciacao: processamento.valorApreciacao,
        totalDividendos: processamento.totalDividendos,
        valorFinalTotal: processamento.valorFinalTotal,
        lucroPrejuizo: processamento.lucro,
        percentualRetorno: processamento.percentual,
        proventosRecebidos: processamento.proventosRecebidos,
        proventosPorTipo: processamento.proventosPorTipo,
        comparativoRendaFixa: comparativo,
        retornoAnualizado: processamento.retornoAnualizado,
        volatilidade: processamento.volatilidade,
        maiorPreco: processamento.maiorPreco,
        menorPreco: processamento.menorPreco,
        dataMaiorPreco: processamento.dataMaiorPreco,
        dataMenorPreco: processamento.dataMenorPreco,
      );

      // Salva no cache
      if (usarCache) {
        _cache[cacheKey] = resultado;
      }

      print('✅ Simulação concluída com sucesso!');
      return resultado;
    } catch (e) {
      print('❌ Erro na simulação: $e');
      throw Exception('Erro ao simular investimento: ${e.toString()}');
    }
  }

  /// Valida os parâmetros de entrada
  void _validarParametros(
    String ticker,
    double valorInvestido,
    DateTime dataInicio,
  ) {
    if (ticker.isEmpty) throw Exception('Ticker não pode ser vazio');
    if (valorInvestido <= 0)
      throw Exception('Valor investido deve ser positivo');
    if (valorInvestido > 1000000000)
      throw Exception('Valor investido muito alto');
    if (dataInicio.isAfter(DateTime.now())) {
      throw Exception('Data de início não pode ser futura');
    }
  }

  /// Ajusta a data final para não ser futura
  DateTime _ajustarDataFim(DateTime? dataFim, DateTime dataInicio) {
    final agora = DateTime.now();
    final dataFimReal = dataFim ?? agora;

    if (dataFimReal.isAfter(agora)) {
      return agora;
    }

    if (dataInicio.isAfter(dataFimReal)) {
      throw Exception('Data de início não pode ser após data fim');
    }

    return dataFimReal;
  }

  /// Gera chave única para cache
  String _gerarCacheKey(
    String ticker,
    DateTime inicio,
    DateTime fim,
    double valor,
  ) {
    return '$ticker-${inicio.toIso8601String()}-${fim.toIso8601String()}-$valor';
  }

  /// Processa todos os dados da simulação
  Future<DadosProcessados> _processarDados({
    required List<Cotacao> cotacoes,
    required List<Provento> dividendos,
    required Ativo ativo,
    required DateTime dataInicio,
    required DateTime dataFim,
    required double valorInvestido,
  }) async {
    // Ordenar cotações
    cotacoes.sort((a, b) => a.data.compareTo(b.data));

    // Encontrar cotações inicial e final
    final cotacaoInicial = _encontrarCotacaoMaisProxima(
      cotacoes,
      dataInicio,
      tipo: 'inicial',
    );
    final cotacaoFinal = _encontrarCotacaoMaisProxima(
      cotacoes,
      dataFim,
      tipo: 'final',
    );

    // Calcular quantidade de ações
    final quantidadeAcoes = valorInvestido / cotacaoInicial.fechamento;

    // Calcular valor com apreciação
    final valorApreciacao = quantidadeAcoes * cotacaoFinal.fechamento;

    // Processar dividendos
    final processamentoDividendos = _processarDividendos(
      dividendos: dividendos,
      quantidadeAcoes: quantidadeAcoes,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );

    // Calcular resultado final
    final valorFinalTotal =
        valorApreciacao + processamentoDividendos.totalDividendos;
    final lucro = valorFinalTotal - valorInvestido;
    final percentual = valorInvestido > 0
        ? ((lucro / valorInvestido) * 100).toDouble()
        : 0.0;

    // Calcular métricas adicionais
    final retornoAnualizado = _calcularCAGR(
      valorInicial: valorInvestido,
      valorFinal: valorFinalTotal,
      dias: dataFim.difference(dataInicio).inDays,
    );

    final volatilidade = _calcularVolatilidade(cotacoes);

    final maiorPreco = cotacoes.reduce(
      (a, b) => a.fechamento > b.fechamento ? a : b,
    );
    final menorPreco = cotacoes.reduce(
      (a, b) => a.fechamento < b.fechamento ? a : b,
    );

    return DadosProcessados(
      cotacaoInicial: cotacaoInicial,
      cotacaoFinal: cotacaoFinal,
      quantidadeAcoes: quantidadeAcoes,
      valorApreciacao: valorApreciacao,
      totalDividendos: processamentoDividendos.totalDividendos,
      valorFinalTotal: valorFinalTotal,
      lucro: lucro,
      percentual: percentual,
      proventosRecebidos: processamentoDividendos.proventosRecebidos,
      proventosPorTipo: processamentoDividendos.proventosPorTipo,
      retornoAnualizado: retornoAnualizado,
      volatilidade: volatilidade,
      maiorPreco: maiorPreco.fechamento,
      menorPreco: menorPreco.fechamento,
      dataMaiorPreco: maiorPreco.data,
      dataMenorPreco: menorPreco.data,
    );
  }

  /// Processa dividendos e proventos
  ProcessamentoDividendos _processarDividendos({
    required List<Provento> dividendos,
    required double quantidadeAcoes,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) {
    double totalDividendos = 0;
    final Map<TipoProvento, double> proventosPorTipo = {};
    final List<Provento> proventosRecebidos = [];

    for (var provento in dividendos) {
      if (_isProventoNoPeriodo(provento, dataInicio, dataFim)) {
        final valorRecebido = quantidadeAcoes * provento.valorPorAcao;
        totalDividendos += valorRecebido;
        proventosRecebidos.add(provento);

        proventosPorTipo[provento.tipo] =
            (proventosPorTipo[provento.tipo] ?? 0) + valorRecebido;
      }
    }

    return ProcessamentoDividendos(
      totalDividendos: totalDividendos,
      proventosRecebidos: proventosRecebidos,
      proventosPorTipo: proventosPorTipo,
    );
  }

  /// Calcula comparativo com renda fixa
  Future<ComparativoRendaFixa?> _calcularComparativoRendaFixa({
    required double valorInvestido,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      return await _rendaFixaService.compararRendaFixa(
        valorInicial: valorInvestido,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
    } catch (e) {
      print('⚠️ Erro ao calcular renda fixa: $e');
      return null;
    }
  }

  /// Encontra a cotação mais próxima de uma data
  Cotacao _encontrarCotacaoMaisProxima(
    List<Cotacao> cotacoes,
    DateTime data, {
    required String tipo,
  }) {
    // Primeiro tenta encontrar exatamente na data
    final exata = cotacoes.firstWhere(
      (c) => _mesmaData(c.data, data),
      orElse: () => tipo == 'inicial' ? cotacoes.first : cotacoes.last,
    );

    if (exata != (tipo == 'inicial' ? cotacoes.first : cotacoes.last)) {
      return exata;
    }

    // Se não encontrar, busca a mais próxima
    if (tipo == 'inicial') {
      // Para data inicial, pega a primeira após a data
      final apos = cotacoes.firstWhere(
        (c) => c.data.isAfter(data),
        orElse: () => cotacoes.first,
      );
      return apos;
    } else {
      // Para data final, pega a última antes da data
      final antes = cotacoes.lastWhere(
        (c) => c.data.isBefore(data),
        orElse: () => cotacoes.last,
      );
      return antes;
    }
  }

  /// Verifica se duas datas são iguais (ignorando hora)
  bool _mesmaData(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Verifica se o provento está dentro do período
  bool _isProventoNoPeriodo(Provento provento, DateTime inicio, DateTime fim) {
    final dataReferencia = provento.isPagamentoEmDinheiro
        ? provento.dataPagamento
        : (provento.dataEx ?? provento.dataPagamento);

    return (dataReferencia.isAfter(inicio) ||
            _mesmaData(dataReferencia, inicio)) &&
        (dataReferencia.isBefore(fim) || _mesmaData(dataReferencia, fim));
  }

  /// Calcula o CAGR (Compound Annual Growth Rate)
  double? _calcularCAGR({
    required double valorInicial,
    required double valorFinal,
    required int dias,
  }) {
    if (valorInicial <= 0 || dias <= 0) return null;
    if (valorFinal <= 0) return null;

    final anos = dias / 365;
    if (anos <= 0) return null;

    // CORREÇÃO: Converter o resultado de pow para double explicitamente
    final razao = valorFinal / valorInicial;
    final expoente = 1 / anos;

    // Usando pow e convertendo para double
    final resultadoPow = pow(razao, expoente);
    final cagr = (resultadoPow.toDouble() - 1) * 100;

    return double.parse(cagr.toStringAsFixed(2));
  }

  /// Calcula a volatilidade (desvio padrão dos retornos diários)
  double? _calcularVolatilidade(List<Cotacao> cotacoes) {
    if (cotacoes.length < 2) return null;

    // Calcula retornos diários
    List<double> retornos = [];
    for (int i = 1; i < cotacoes.length; i++) {
      if (cotacoes[i - 1].fechamento > 0) {
        final retorno =
            (cotacoes[i].fechamento - cotacoes[i - 1].fechamento) /
            cotacoes[i - 1].fechamento;
        retornos.add(retorno);
      }
    }

    if (retornos.isEmpty) return null;

    // Calcula média dos retornos
    final somaRetornos = retornos.reduce((a, b) => a + b);
    final media = somaRetornos / retornos.length;

    // Calcula desvio padrão
    double somaQuadrados = 0;
    for (var retorno in retornos) {
      final diferenca = retorno - media;
      // CORREÇÃO: Converter pow para double
      somaQuadrados += pow(diferenca, 2).toDouble();
    }

    final variancia = retornos.length > 1
        ? somaQuadrados / (retornos.length - 1)
        : somaQuadrados;

    final desvioPadraoDiario = sqrt(variancia);
    final desvioPadraoAnual = desvioPadraoDiario * sqrt(DIAS_UTEIS_POR_ANO);

    return double.parse((desvioPadraoAnual * 100).toStringAsFixed(2));
  }

  /// Simulação simplificada (para previews)
  Future<Map<String, dynamic>> simularSimplificado({
    required String ticker,
    required DateTime dataInicio,
    required double valorInvestido,
  }) async {
    try {
      final resultado = await simular(
        ticker: ticker,
        dataInicio: dataInicio,
        valorInvestido: valorInvestido,
        incluirComparacaoRendaFixa: false,
        usarCache: true,
      );

      return {
        'sucesso': true,
        'ticker': resultado.ativo.ticker,
        'valorFinal': resultado.valorFinalTotal,
        'lucro': resultado.lucroPrejuizo,
        'percentual': resultado.percentualRetorno,
        'dividendos': resultado.totalDividendos,
        'quantidadeAcoes': resultado.quantidadeAcoes,
      };
    } catch (e) {
      return {'sucesso': false, 'erro': e.toString()};
    }
  }

  /// Limpa o cache
  void limparCache() {
    _cache.clear();
  }

  /// Remove item específico do cache
  void removerDoCache(String key) {
    _cache.remove(key);
  }

  /// Obtém estatísticas de uso do cache
  Map<String, dynamic> get estatisticasCache {
    return {'tamanho': _cache.length, 'chaves': _cache.keys.toList()};
  }

  /// Formata data para logging
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}
