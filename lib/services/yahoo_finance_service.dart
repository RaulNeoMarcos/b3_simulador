// lib/services/yahoo_finance_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:b3_simulador/models/ativo.dart';
import 'package:b3_simulador/models/cotacao.dart';
import 'package:b3_simulador/models/provento.dart';
import 'dart:async';

class YahooFinanceService {
  final String _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart/';

  // Cache para evitar requisições repetidas
  final Map<String, dynamic> _cache = {};

  // Constantes
  static const int MAX_RETRIES = 3;
  static const Duration TIMEOUT = Duration(seconds: 30);

  /// Busca dados completos de um ativo (cotações + dividendos)
  Future<Map<String, dynamic>> getDadosCompletos({
    required String ticker,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    final tickerFormatado = _formatarTicker(ticker);
    final cacheKey =
        '$tickerFormatado-${dataInicio.toIso8601String()}-${dataFim.toIso8601String()}';

    // Verifica cache
    if (_cache.containsKey(cacheKey)) {
      print('📦 Usando cache para $tickerFormatado');
      return _cache[cacheKey]!;
    }

    try {
      print('🔄 Buscando dados do Yahoo Finance para $tickerFormatado');

      // Busca cotações históricas
      final cotacoes = await _buscarCotacoes(
        ticker: tickerFormatado,
        inicio: dataInicio,
        fim: dataFim,
      );

      // Busca dividendos (via endpoint específico)
      final dividendos = await _buscarDividendos(
        ticker: tickerFormatado,
        inicio: dataInicio,
        fim: dataFim,
      );

      // Cria informações do ativo
      final ativo = Ativo.brasil(
        ticker.replaceAll('.SA', ''),
        _extrairNomeEmpresa(ticker),
      );

      final resultado = {
        'ativo': ativo,
        'cotacoes': cotacoes,
        'dividendos': dividendos,
      };

      // Salva no cache
      _cache[cacheKey] = resultado;

      return resultado;
    } catch (e) {
      print('❌ Erro no Yahoo Finance: $e');

      // Em caso de erro, retorna dados mockados para não quebrar o app
      print('⚠️ Usando dados mockados como fallback');
      return _gerarDadosMockados(ticker, dataInicio, dataFim);
    }
  }

  /// Formata o ticker para API do Yahoo (adiciona .SA se necessário)
  String _formatarTicker(String ticker) {
    String tickerLimpo = ticker.trim().toUpperCase();

    if (tickerLimpo.endsWith('.SA')) {
      return tickerLimpo;
    }

    return '$tickerLimpo.SA';
  }

  /// Extrai nome da empresa baseado no ticker
  String _extrairNomeEmpresa(String ticker) {
    final tickerLimpo = ticker.replaceAll('.SA', '');

    const Map<String, String> nomesConhecidos = {
      'PETR3': 'Petrobras ON',
      'PETR4': 'Petrobras PN',
      'VALE3': 'Vale ON',
      'ITUB3': 'Itaú Unibanco ON',
      'ITUB4': 'Itaú Unibanco PN',
      'BBDC3': 'Bradesco ON',
      'BBDC4': 'Bradesco PN',
      'BBAS3': 'Banco do Brasil ON',
      'ABEV3': 'Ambev ON',
      'WEGE3': 'WEG ON',
      'ELET3': 'Eletrobras ON',
      'ELET6': 'Eletrobras PNB',
      'RENT3': 'Localiza ON',
      'LREN3': 'Lojas Renner ON',
      'MGLU3': 'Magazine Luiza ON',
      'VIIA3': 'Via ON',
    };

    return nomesConhecidos[tickerLimpo] ?? '$tickerLimpo - Ação';
  }

  /// Busca cotações históricas usando a API direta do Yahoo Finance
  Future<List<Cotacao>> _buscarCotacoes({
    required String ticker,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    int tentativas = 0;

    while (tentativas < MAX_RETRIES) {
      try {
        // Converte datas para timestamps (segundos)
        final period1 = (inicio.millisecondsSinceEpoch / 1000).floor();
        final period2 = (fim.millisecondsSinceEpoch / 1000).floor();

        // Define o intervalo baseado no período
        final intervalo = _determinarIntervalo(inicio, fim);

        final url =
            '$_baseUrl$ticker?'
            'period1=$period1&'
            'period2=$period2&'
            'interval=$intervalo&'
            'includePrePost=false&'
            'events=div%7Csplit';

        print('📡 URL: $url');

        final response = await http
            .get(
              Uri.parse(url),
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              },
            )
            .timeout(TIMEOUT);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Verifica se há erro na resposta
          if (data['chart']['error'] != null) {
            throw Exception(data['chart']['error']['description']);
          }

          final result = data['chart']['result'][0];
          final timestamps = result['timestamp'] as List;
          final indicators = result['indicators']['quote'][0];

          final cotacoes = <Cotacao>[];

          for (int i = 0; i < timestamps.length; i++) {
            final timestamp = timestamps[i];
            final data = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

            // Extrai valores (podem ser null em feriados)
            final close = _getDoubleValue(indicators['close'], i);
            final open = _getDoubleValue(indicators['open'], i);
            final high = _getDoubleValue(indicators['high'], i);
            final low = _getDoubleValue(indicators['low'], i);
            final volume = _getDoubleValue(indicators['volume'], i);

            // Só adiciona se tiver preço de fechamento
            if (close != null && close > 0) {
              cotacoes.add(
                Cotacao(
                  data: data,
                  abertura: open ?? close,
                  fechamento: close,
                  maxima: high ?? close,
                  minima: low ?? close,
                  volume: volume ?? 0,
                  ticker: ticker,
                ),
              );
            }
          }

          print('✅ Encontradas ${cotacoes.length} cotações para $ticker');

          if (cotacoes.isEmpty) {
            throw Exception('Nenhuma cotação encontrada no período');
          }

          return cotacoes;
        } else {
          throw Exception('Erro HTTP ${response.statusCode}');
        }
      } catch (e) {
        tentativas++;
        print('⚠️ Tentativa $tentativas falhou: $e');

        if (tentativas == MAX_RETRIES) {
          print('❌ Todas as tentativas falharam para $ticker');
          return [];
        }

        await Future.delayed(Duration(seconds: 2 * tentativas));
      }
    }

    return [];
  }

  /// Determina o intervalo baseado na diferença de datas
  String _determinarIntervalo(DateTime inicio, DateTime fim) {
    final dias = fim.difference(inicio).inDays;

    if (dias <= 30) return '1d'; // 1 dia
    if (dias <= 90) return '1d'; // 1 dia
    if (dias <= 365) return '1wk'; // 1 semana
    return '1mo'; // 1 mês
  }

  /// Extrai valor double de uma lista, tratando null
  double? _getDoubleValue(List? list, int index) {
    if (list == null) return null;
    if (index >= list.length) return null;

    final value = list[index];
    if (value == null) return null;

    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);

    return null;
  }

  /// Busca dividendos históricos
  Future<List<Provento>> _buscarDividendos({
    required String ticker,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    try {
      // Yahoo Finance tem um endpoint específico para dividendos
      final period1 = (inicio.millisecondsSinceEpoch / 1000).floor();
      final period2 = (fim.millisecondsSinceEpoch / 1000).floor();

      final url =
          '$_baseUrl$ticker?'
          'period1=$period1&'
          'period2=$period2&'
          'interval=1d&'
          'events=div';

      final response = await http.get(Uri.parse(url)).timeout(TIMEOUT);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'][0];

        final dividendos = <Provento>[];

        // Verifica se existem eventos de dividendos
        if (result.containsKey('events') &&
            result['events'].containsKey('dividends')) {
          final dividendsMap = result['events']['dividends'] as Map;

          dividendsMap.forEach((key, value) {
            try {
              final timestamp = int.parse(key);
              final dataPagamento = DateTime.fromMillisecondsSinceEpoch(
                timestamp * 1000,
              );
              final amount = (value['amount'] as num).toDouble();

              // Determina o tipo baseado no valor (simplificado)
              final tipo = amount > 1.0
                  ? TipoProvento.jcp
                  : TipoProvento.dividendo;

              dividendos.add(
                Provento(
                  ticker: ticker.replaceAll('.SA', ''),
                  dataPagamento: dataPagamento,
                  tipo: tipo,
                  valorPorAcao: amount,
                  descricao: value['type'] ?? 'Dividendo',
                ),
              );
            } catch (e) {
              print('⚠️ Erro ao processar dividendo: $e');
            }
          });
        }

        print('✅ Encontrados ${dividendos.length} dividendos para $ticker');
        return dividendos;
      }

      return [];
    } catch (e) {
      print('⚠️ Erro ao buscar dividendos: $e');
      return [];
    }
  }

  /// Gera dados mockados para fallback
  Map<String, dynamic> _gerarDadosMockados(
    String ticker,
    DateTime inicio,
    DateTime fim,
  ) {
    final tickerLimpo = ticker.replaceAll('.SA', '');

    final ativo = Ativo.brasil(tickerLimpo, _extrairNomeEmpresa(ticker));

    final cotacoes = <Cotacao>[];
    var dataAtual = inicio;
    double precoBase = 30.0;

    // Define preço base por ticker
    if (ticker.contains('VALE')) precoBase = 68.0;
    if (ticker.contains('ITUB')) precoBase = 28.0;
    if (ticker.contains('BBDC')) precoBase = 18.0;
    if (ticker.contains('BBAS')) precoBase = 42.0;
    if (ticker.contains('PETR')) precoBase = 35.0;

    while (dataAtual.isBefore(fim)) {
      if (dataAtual.weekday != DateTime.saturday &&
          dataAtual.weekday != DateTime.sunday) {
        final variacao = (dataAtual.millisecondsSinceEpoch % 10 - 5) / 100;
        final preco = precoBase * (1 + variacao);

        cotacoes.add(
          Cotacao(
            data: DateTime(dataAtual.year, dataAtual.month, dataAtual.day),
            abertura: preco * 0.99,
            fechamento: preco,
            maxima: preco * 1.02,
            minima: preco * 0.98,
            volume: 1000000 + (dataAtual.millisecondsSinceEpoch % 1000000),
            ticker: ticker,
          ),
        );
      }
      dataAtual = dataAtual.add(Duration(days: 1));
    }

    final dividendos = <Provento>[];
    dataAtual = DateTime(inicio.year, inicio.month, 15);

    while (dataAtual.isBefore(fim)) {
      dividendos.add(
        Provento(
          ticker: tickerLimpo,
          dataPagamento: DateTime(dataAtual.year, dataAtual.month, 15),
          tipo: dataAtual.month % 3 == 0
              ? TipoProvento.jcp
              : TipoProvento.dividendo,
          valorPorAcao: 0.50 + (dataAtual.millisecondsSinceEpoch % 30) / 100,
          descricao: 'Provento referente ao período',
        ),
      );

      dataAtual = DateTime(dataAtual.year, dataAtual.month + 3, 15);
    }

    return {'ativo': ativo, 'cotacoes': cotacoes, 'dividendos': dividendos};
  }

  /// Limpa o cache
  void limparCache() {
    _cache.clear();
  }
}
