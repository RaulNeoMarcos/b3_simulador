import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class FundamentusClient {
  static const String BASE_URL = 'https://www.fundamentus.com.br/detalhes.php';

  /// Busca dados fundamentalistas de um ticker no Fundamentus
  static Future<Map<String, dynamic>?> buscarDados(String ticker) async {
    final tickerLimpo = ticker.replaceAll('.SA', '');

    try {
      print('📡 Fundamentus: buscando $tickerLimpo...');

      // Fundamentus espera o papel no formato "PETR4" (sem .SA)
      final response = await http
          .post(
            Uri.parse(BASE_URL),
            body: {'papel': tickerLimpo},
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseHtml(response.body, tickerLimpo);
      }

      print('⚠️ Fundamentus: erro ${response.statusCode}');
      return null;
    } catch (e) {
      print('⚠️ Fundamentus: exceção - $e');
      return null;
    }
  }

  static Map<String, dynamic>? _parseHtml(String html, String ticker) {
    try {
      final document = parser.parse(html);

      if (document.querySelector('table') == null) {
        return null;
      }

      final indicators = <String, dynamic>{};

      double? extractValue(String label) {
        try {
          final elements = document.querySelectorAll('td');
          for (int i = 0; i < elements.length; i++) {
            if (elements[i].text.contains(label) && i + 1 < elements.length) {
              final valueText = elements[i + 1].text
                  .replaceAll('.', '')
                  .replaceAll(',', '.')
                  .replaceAll(' ', '')
                  .replaceAll('%', '')
                  .replaceAll(r'R$', '')
                  .trim();
              return double.tryParse(valueText);
            }
          }
        } catch (e) {
          print('⚠️ Erro ao extrair $label: $e');
        }
        return null;
      }

      indicators['pe'] = extractValue('P/L') ?? 0;
      indicators['pb'] = extractValue('P/VP') ?? 0;
      indicators['roe'] = (extractValue('ROE') ?? 0) / 100;
      indicators['dividendYield'] = extractValue('Div.Yield') ?? 0;
      indicators['payout'] = (extractValue('Payout') ?? 0) / 100;
      indicators['marketCap'] =
          (extractValue('Valor de mercado') ?? 0) * 1000000;

      final acoesTexto = extractValue('Nro. Ações') ?? 0;
      indicators['sharesOutstanding'] = acoesTexto * 1000000;
      indicators['beta'] = 1.0;
      indicators['fonte'] = 'Fundamentus';

      if (indicators['pe'] == 0 && indicators['pb'] == 0) {
        print('⚠️ Fundamentus: página encontrada mas sem dados para $ticker');
        return null;
      }

      print('✅ Fundamentus: dados obtidos para $ticker');
      return indicators;
    } catch (e) {
      print('⚠️ Fundamentus: erro no parsing - $e');
      return null;
    }
  }
}
