// lib/services/sources/cvm_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class CVMClient {
  static const String BASE_URL = 'https://dados.cvm.gov.br/api';

  /// Busca dados fundamentalistas de um ticker na API da CVM
  static Future<Map<String, dynamic>?> buscarDados(String ticker) async {
    final tickerLimpo = ticker.replaceAll('.SA', '');

    try {
      print('📡 CVM: buscando $tickerLimpo...');

      // Primeiro, encontrar o código CVM da empresa pelo ticker
      final codCVM = await _buscarCodigoCVM(tickerLimpo);
      if (codCVM == null) return null;

      // Buscar dados contábeis do último trimestre
      final url = '$BASE_URL/consolidado_dre_frete/cia_aberta/$codCVM';
      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _processarDadosCVM(data, tickerLimpo);
      }

      return null;
    } catch (e) {
      print('⚠️ CVM: exceção - $e');
      return null;
    }
  }

  static Future<String?> _buscarCodigoCVM(String ticker) async {
    // TODO: Implementar mapeamento ticker -> código CVM
    // Por enquanto, retorna null (API da CVM é mais complexa)
    return null;
  }

  static Map<String, dynamic> _processarDadosCVM(
    Map<String, dynamic> data,
    String ticker,
  ) {
    // TODO: Implementar processamento dos dados da CVM
    // Retornar no mesmo formato das outras fontes
    return {};
  }
}
