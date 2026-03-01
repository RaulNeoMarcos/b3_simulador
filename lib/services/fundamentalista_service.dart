import 'dart:convert';

import 'package:b3_simulador/services/cvm_client.dart';
import 'package:b3_simulador/services/fundamentus_client.dart';
import 'package:http/http.dart' as http;

class FundamentalistaService {
  static const String ALPHA_VANTAGE_KEY = '465U4U84MTF11Q11';

  // Cache em memória para a sessão atual
  static final Map<String, Map<String, dynamic>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamp = {};
  static const Duration CACHE_DURATION = Duration(hours: 6);

  /// Busca dados fundamentalistas de múltiplas fontes
  static Future<Map<String, dynamic>> buscarDadosFundamentalistas(
    String ticker,
  ) async {
    final tickerLimpo = ticker.replaceAll('.SA', '');

    // Verificar cache válido
    // if (_cache.containsKey(tickerLimpo)) {
    //   final timestamp = _cacheTimestamp[tickerLimpo]!;
    //   if (DateTime.now().difference(timestamp) < CACHE_DURATION) {
    //     print('📦 Usando cache para $tickerLimpo');
    //     return _cache[tickerLimpo]!;
    //   }
    // }

    print(
      '🎯 Buscando dados fundamentalistas para $tickerLimpo de múltiplas fontes...',
    );

    // Tentar fontes em ordem de preferência
    Map<String, dynamic>? dados;

    // 1. Alpha Vantage (API rápida)
    dados = await _buscarAlphaVantage(tickerLimpo);
    if (dados != null) {
      print('✅ Alpha Vantage: dados obtidos');
      return _salvarCache(tickerLimpo, dados);
    }

    // 2. Fundamentus (web scraping)
    dados = await _buscarFundamentus(tickerLimpo);
    if (dados != null) {
      print('✅ Fundamentus: dados obtidos');
      return _salvarCache(tickerLimpo, dados);
    }

    // 3. CVM Dados Abertos (fonte oficial)
    dados = await _buscarCVM(tickerLimpo);
    if (dados != null) {
      print('✅ CVM: dados obtidos');
      return _salvarCache(tickerLimpo, dados);
    }

    // 4. Fallback para dados específicos
    print('⚠️ Nenhuma fonte retornou dados, usando fallback');
    dados = _gerarDadosFallback(tickerLimpo);
    return _salvarCache(tickerLimpo, dados);
  }

  static Future<Map<String, dynamic>?> _buscarAlphaVantage(
    String ticker,
  ) async {
    try {
      final url =
          'https://www.alphavantage.co/query?function=OVERVIEW&symbol=$ticker.SA&apikey=$ALPHA_VANTAGE_KEY';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty &&
            !data.containsKey('Error Message') &&
            data['Symbol'] != null) {
          return {
            'pe': _parseDouble(data['PERatio']),
            'pb': _parseDouble(data['PriceToBookRatio']),
            'roe': _parseDouble(data['ReturnOnEquityTTM']) / 100,
            'dividendYield': _parseDouble(data['DividendYield']) * 100,
            'payout': _parseDouble(data['PayoutRatio']),
            'beta': _parseDouble(data['Beta']),
            'marketCap': _parseDouble(data['MarketCapitalization']) * 1000000,
            'sharesOutstanding':
                _parseDouble(data['SharesOutstanding']) * 1000000,
            'fonte': 'Alpha Vantage',
          };
        }
      }
    } catch (e) {
      print('⚠️ Alpha Vantage erro: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _buscarFundamentus(String ticker) async {
    final dados = await FundamentusClient.buscarDados(ticker);
    if (dados != null) {
      dados['fonte'] = 'Fundamentus';
    }
    return dados;
  }

  static Future<Map<String, dynamic>?> _buscarCVM(String ticker) async {
    final dados = await CVMClient.buscarDados(ticker);
    if (dados != null) {
      dados['fonte'] = 'CVM';
    }
    return dados;
  }

  static Map<String, dynamic> _gerarDadosFallback(String ticker) {
    print('📊 Gerando dados fallback para $ticker');

    // Dados específicos por ticker
    final Map<String, Map<String, dynamic>> dadosEspecificos = {
      'CYRE3': {
        'pe': 4.8,
        'pb': 0.9,
        'roe': 0.19,
        'dividendYield': 4.2,
        'payout': 0.35,
        'beta': 1.4,
        'marketCap': 10600000000,
        'sharesOutstanding': 384000000,
        'fonte': 'Fallback (dados do setor)',
      },
      'PETR4': {
        'pe': 5.2,
        'pb': 0.8,
        'roe': 0.15,
        'dividendYield': 8.5,
        'payout': 0.45,
        'beta': 1.2,
        'marketCap': 350000000000,
        'sharesOutstanding': 6500000000,
        'fonte': 'Fallback (dados históricos)',
      },
      'VALE3': {
        'pe': 4.8,
        'pb': 1.2,
        'roe': 0.22,
        'dividendYield': 10.2,
        'payout': 0.60,
        'beta': 1.1,
        'marketCap': 300000000000,
        'sharesOutstanding': 5000000000,
        'fonte': 'Fallback (dados históricos)',
      },
    };

    if (dadosEspecificos.containsKey(ticker)) {
      return dadosEspecificos[ticker]!;
    }

    // Dados genéricos para outros tickers
    return {
      'pe': 10.0,
      'pb': 1.5,
      'roe': 0.12,
      'dividendYield': 4.0,
      'payout': 0.30,
      'beta': 1.0,
      'marketCap': 10000000000,
      'sharesOutstanding': 1000000000,
      'fonte': 'Fallback (dados genéricos)',
    };
  }

  static Map<String, dynamic> _salvarCache(
    String ticker,
    Map<String, dynamic> dados,
  ) {
    _cache[ticker] = dados;
    _cacheTimestamp[ticker] = DateTime.now();
    return dados;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.isEmpty || value == 'None') return 0.0;
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  static void limparCache() {
    _cache.clear();
    _cacheTimestamp.clear();
  }
}
