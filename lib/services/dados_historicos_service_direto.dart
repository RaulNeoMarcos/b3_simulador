// services/dados_historicos_service_direto.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DadosHistoricosServiceDireto {
  final String _baseUrl = 'https://api.bcb.gov.br/dados/serie/bcdata.sgs.';

  // Códigos SGS (Sistema Gerenciador de Séries Temporais do BC)
  // 11 - Selic anualizada
  // 12 - Selic diária
  // 4390 - CDI diário
  // 7809 - TR mensal
  final Map<String, int> _codigosSeries = {
    'selic': 11,
    'cdi': 4390,
    'tr': 7809,
  };

  Future<double> getSelicPorData(DateTime data) async {
    final dataFormatada = DateFormat('dd/MM/yyyy').format(data);
    final url =
        '${_baseUrl}${_codigosSeries['selic']}/dados?formato=json&data=$dataFormatada';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List dados = json.decode(response.body);
        if (dados.isNotEmpty) {
          return double.parse(dados[0]['valor'].toString());
        }
      }
    } catch (e) {
      print('Erro ao buscar Selic: $e');
    }

    return 0.0;
  }

  // Métodos similares para CDI e TR
}
