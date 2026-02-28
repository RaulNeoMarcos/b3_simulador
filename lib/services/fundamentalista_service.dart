// lib/services/fundamentalista_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/valuation_avancado.dart';

class FundamentalistaService {
  static const String ALPHA_VANTAGE_KEY =
      'QCZCNQFQTQ94LT6D'; // Substitua pela sua chave

  /// Busca dados fundamentalistas de um ticker
  static Future<Map<String, dynamic>> buscarDadosFundamentalistas(
    String ticker,
  ) async {
    final tickerLimpo = ticker.replaceAll('.SA', '');

    try {
      print('📡 Buscando dados fundamentalistas para $tickerLimpo');

      // Usando Alpha Vantage (gratuito, precisa de chave)
      final url =
          'https://www.alphavantage.co/query?function=OVERVIEW&symbol=$tickerLimpo.SA&apikey=$ALPHA_VANTAGE_KEY';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('Error Message')) {
          print('⚠️ Erro na API: ${data['Error Message']}');
          return _gerarDadosMockados(ticker);
        }

        // Se não tiver dados, retorna mockados
        if (data.isEmpty || data['Symbol'] == null) {
          print('⚠️ Dados não encontrados, usando mock');
          return _gerarDadosMockados(ticker);
        }

        print('✅ Dados fundamentalistas obtidos com sucesso');

        return {
          'pe': _parseDouble(data['PERatio']),
          'pb': _parseDouble(data['PriceToBookRatio']),
          'roe': _parseDouble(data['ReturnOnEquityTTM']) / 100,
          'dividendYield': _parseDouble(data['DividendYield']) * 100,
          'payout': _parseDouble(data['PayoutRatio']),
          'beta': _parseDouble(data['Beta']),
          'marketCap': _parseDouble(data['MarketCapitalization']),
          'sharesOutstanding':
              _parseDouble(data['SharesOutstanding']) * 1000000,
        };
      } else {
        print('⚠️ Erro HTTP ${response.statusCode}');
        return _gerarDadosMockados(ticker);
      }
    } catch (e) {
      print('🔥 Erro ao buscar dados fundamentalistas: $e');
      return _gerarDadosMockados(ticker);
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.isEmpty || value == 'None') return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Gera dados mockados realistas para testes
  static Map<String, dynamic> _gerarDadosMockados(String ticker) {
    print('📊 Usando dados mockados para $ticker');

    if (ticker.contains('PETR4')) {
      return {
        'pe': 5.2,
        'pb': 0.8,
        'roe': 0.15,
        'dividendYield': 8.5,
        'payout': 0.45,
        'beta': 1.2,
        'marketCap': 350000000000,
        'sharesOutstanding': 6500000000,
      };
    } else if (ticker.contains('VALE3')) {
      return {
        'pe': 4.8,
        'pb': 1.2,
        'roe': 0.22,
        'dividendYield': 10.2,
        'payout': 0.60,
        'beta': 1.1,
        'marketCap': 300000000000,
        'sharesOutstanding': 5000000000,
      };
    } else if (ticker.contains('ITUB4')) {
      return {
        'pe': 7.5,
        'pb': 1.1,
        'roe': 0.18,
        'dividendYield': 6.5,
        'payout': 0.40,
        'beta': 0.9,
        'marketCap': 250000000000,
        'sharesOutstanding': 9000000000,
      };
    } else {
      // Dados genéricos
      return {
        'pe': 10.0,
        'pb': 1.5,
        'roe': 0.12,
        'dividendYield': 4.0,
        'payout': 0.30,
        'beta': 1.0,
        'marketCap': 10000000000,
        'sharesOutstanding': 1000000000,
      };
    }
  }
}
