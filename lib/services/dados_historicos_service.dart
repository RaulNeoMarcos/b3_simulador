// lib/services/dados_historicos_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/taxa_historica.dart';

class DadosHistoricosService {
  // APIs do Banco Central do Brasil
  static const String _bcbBaseUrl =
      'https://api.bcb.gov.br/dados/serie/bcdata.sgs.';

  // Códigos SGS (Sistema Gerenciador de Séries Temporais do BCB)
  static const Map<String, int> _codigosSeries = {
    'selic': 11, // Taxa Selic acumulada no mês
    'selic_diaria': 12, // Taxa Selic diária
    'cdi': 4390, // Taxa CDI diária
    'tr': 7809, // Taxa Referencial mensal
    'ipca': 433, // IPCA mensal
    'igpm': 189, // IGP-M mensal
  };

  // Cache para evitar requisições repetidas
  final Map<String, List<TaxaHistorica>> _cache = {};

  // Constantes
  static const int MAX_RETRIES = 3;
  static const Duration TIMEOUT = Duration(seconds: 15);

  /// Busca taxas para um período específico
  Future<List<TaxaHistorica>> getTaxasPorPeriodo({
    required DateTime inicio,
    required DateTime fim,
    bool usarCache = true,
  }) async {
    final cacheKey = '${inicio.toIso8601String()}-${fim.toIso8601String()}';

    // Verifica cache
    if (usarCache && _cache.containsKey(cacheKey)) {
      print(
        '📦 Usando cache para período ${_formatarData(inicio)} a ${_formatarData(fim)}',
      );
      return _cache[cacheKey]!;
    }

    try {
      print(
        '🔄 Buscando taxas do BCB de ${_formatarData(inicio)} a ${_formatarData(fim)}',
      );

      // Busca cada série histórica em paralelo
      final results = await Future.wait([
        _buscarSerieHistorica('selic', inicio, fim),
        _buscarSerieHistorica('cdi', inicio, fim),
        _buscarSerieHistorica('tr', inicio, fim),
      ]);

      final selicData = results[0];
      final cdiData = results[1];
      final trData = results[2];

      // Combina os dados por mês
      final taxasPorMes = <String, TaxaHistorica>{};

      _combinarDados(taxasPorMes, selicData, 'selic');
      _combinarDados(taxasPorMes, cdiData, 'cdi');
      _combinarDados(taxasPorMes, trData, 'tr');

      // Converte para lista ordenada
      final taxas = taxasPorMes.values.toList()
        ..sort((a, b) => a.data.compareTo(b.data));

      print('✅ Encontradas ${taxas.length} taxas mensais');

      // Salva no cache
      if (usarCache) {
        _cache[cacheKey] = taxas;
      }

      return taxas;
    } catch (e) {
      print('❌ Erro ao buscar taxas do BCB: $e');

      // Retorna dados mockados em caso de erro
      print('⚠️ Usando dados mockados como fallback');
      return _gerarTaxasMockadas(inicio, fim);
    }
  }

  /// Busca uma série histórica específica
  Future<List<Map<String, dynamic>>> _buscarSerieHistorica(
    String serie,
    DateTime inicio,
    DateTime fim,
  ) async {
    final codigo = _codigosSeries[serie];
    if (codigo == null) return [];

    int tentativas = 0;

    while (tentativas < MAX_RETRIES) {
      try {
        // Formata datas no formato dd/MM/yyyy
        final dataInicioStr = DateFormat('dd/MM/yyyy').format(inicio);
        final dataFimStr = DateFormat('dd/MM/yyyy').format(fim);

        final url =
            '$_bcbBaseUrl$codigo/dados?formato=json&dataInicial=$dataInicioStr&dataFinal=$dataFimStr';

        print('📡 Buscando $serie: $url');

        final response = await http
            .get(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )
            .timeout(TIMEOUT);

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          return data
              .map(
                (item) => {
                  'data': item['data'],
                  'valor': double.parse(
                    item['valor'].toString().replaceAll(',', '.'),
                  ),
                },
              )
              .toList();
        } else {
          throw Exception('Erro HTTP ${response.statusCode}');
        }
      } catch (e) {
        tentativas++;
        print('⚠️ Tentativa $tentativas para $serie falhou: $e');

        if (tentativas == MAX_RETRIES) {
          print('❌ Todas as tentativas falharam para $serie');
          return [];
        }

        await Future.delayed(Duration(seconds: 2 * tentativas));
      }
    }

    return [];
  }

  /// Combina dados de diferentes séries em um mapa por mês
  void _combinarDados(
    Map<String, TaxaHistorica> taxasPorMes,
    List<Map<String, dynamic>> dados,
    String tipo,
  ) {
    for (var item in dados) {
      try {
        final dataStr = item['data'] as String;
        final valor = item['valor'] as double;

        // Converte data string (dd/MM/yyyy) para DateTime
        final partes = dataStr.split('/');
        final data = DateTime(
          int.parse(partes[2]),
          int.parse(partes[1]),
          1, // Primeiro dia do mês
        );

        final mesKey = DateFormat('yyyy-MM').format(data);

        if (!taxasPorMes.containsKey(mesKey)) {
          taxasPorMes[mesKey] = TaxaHistorica(
            data: data,
            selic: 0.0,
            cdi: 0.0,
            tr: 0.0,
          );
        }

        final taxa = taxasPorMes[mesKey]!;

        switch (tipo) {
          case 'selic':
            taxasPorMes[mesKey] = TaxaHistorica(
              data: data,
              selic: valor,
              cdi: taxa.cdi,
              tr: taxa.tr,
            );
            break;
          case 'cdi':
            taxasPorMes[mesKey] = TaxaHistorica(
              data: data,
              selic: taxa.selic,
              cdi: valor,
              tr: taxa.tr,
            );
            break;
          case 'tr':
            taxasPorMes[mesKey] = TaxaHistorica(
              data: data,
              selic: taxa.selic,
              cdi: taxa.cdi,
              tr: valor / 100, // TR vem em percentual
            );
            break;
        }
      } catch (e) {
        print('⚠️ Erro ao combinar dado: $e');
      }
    }
  }

  /// Busca uma taxa específica para uma data
  Future<double> getSelicPorData(DateTime data) async {
    final taxas = await getTaxasPorPeriodo(
      inicio: DateTime(data.year, data.month, 1),
      fim: DateTime(data.year, data.month, 1).add(Duration(days: 30)),
    );

    if (taxas.isNotEmpty) {
      return taxas.first.selic;
    }

    return _getSelicMock(data);
  }

  /// Busca CDI para uma data
  Future<double> getCDIPorData(DateTime data) async {
    final taxas = await getTaxasPorPeriodo(
      inicio: DateTime(data.year, data.month, 1),
      fim: DateTime(data.year, data.month, 1).add(Duration(days: 30)),
    );

    if (taxas.isNotEmpty) {
      return taxas.first.cdi;
    }

    return _getCDIMock(data);
  }

  /// Busca TR para uma data
  Future<double> getTRPorData(DateTime data) async {
    final taxas = await getTaxasPorPeriodo(
      inicio: DateTime(data.year, data.month, 1),
      fim: DateTime(data.year, data.month, 1).add(Duration(days: 30)),
    );

    if (taxas.isNotEmpty) {
      return taxas.first.tr;
    }

    return _getTRMock(data);
  }

  /// Gera taxas mockadas para fallback
  List<TaxaHistorica> _gerarTaxasMockadas(DateTime inicio, DateTime fim) {
    final taxas = <TaxaHistorica>[];
    var dataAtual = DateTime(inicio.year, inicio.month, 1);
    final dataFim = DateTime(fim.year, fim.month, 1);

    // Dados baseados na tabela histórica real
    while (dataAtual.isBefore(dataFim) || dataAtual.isAtSameMomentAs(dataFim)) {
      double selic, cdi, tr;

      switch (dataAtual.year) {
        case 2023:
          selic = 13.75;
          cdi = 13.05;
          tr = 0.0;
          break;
        case 2022:
          selic = 13.75;
          cdi = 12.39;
          tr = 0.0;
          break;
        case 2021:
          selic = 9.25;
          cdi = 4.39;
          tr = 0.1;
          break;
        case 2020:
          selic = 2.75;
          cdi = 2.75;
          tr = 0.2;
          break;
        case 2019:
          selic = 5.94;
          cdi = 5.94;
          tr = 0.3;
          break;
        case 2018:
          selic = 6.50;
          cdi = 6.50;
          tr = 0.4;
          break;
        case 2017:
          selic = 9.25;
          cdi = 9.25;
          tr = 0.5;
          break;
        case 2016:
          selic = 14.15;
          cdi = 14.15;
          tr = 0.6;
          break;
        case 2015:
          selic = 14.25;
          cdi = 13.66;
          tr = 0.7;
          break;
        default:
          selic = 10.0;
          cdi = 9.8;
          tr = 0.5;
      }

      // Ajustes mensais (pequenas variações)
      final variacaoMensal = (dataAtual.month * 0.1);

      taxas.add(
        TaxaHistorica(
          data: dataAtual,
          selic: selic + (dataAtual.month % 3 == 0 ? variacaoMensal : 0),
          cdi: cdi + (dataAtual.month % 3 == 0 ? variacaoMensal : 0),
          tr: tr + (dataAtual.month == 6 ? 0.1 : 0),
        ),
      );

      dataAtual = DateTime(dataAtual.year, dataAtual.month + 1, 1);
    }

    return taxas;
  }

  /// Mock para Selic
  double _getSelicMock(DateTime data) {
    if (data.year == 2023) return 13.75;
    if (data.year == 2022) return 13.75;
    if (data.year == 2021) return 9.25;
    if (data.year == 2020) return 2.75;
    if (data.year == 2019) return 5.94;
    if (data.year == 2018) return 6.50;
    if (data.year == 2017) return 9.25;
    if (data.year == 2016) return 14.15;
    if (data.year == 2015) return 14.25;
    return 10.0;
  }

  /// Mock para CDI
  double _getCDIMock(DateTime data) {
    if (data.year == 2023) return 13.05;
    if (data.year == 2022) return 12.39;
    if (data.year == 2021) return 4.39;
    if (data.year == 2020) return 2.75;
    if (data.year == 2019) return 5.94;
    if (data.year == 2018) return 6.50;
    if (data.year == 2017) return 9.25;
    if (data.year == 2016) return 14.15;
    if (data.year == 2015) return 13.66;
    return 9.8;
  }

  /// Mock para TR
  double _getTRMock(DateTime data) {
    if (data.year >= 2020) return 0.0;
    if (data.year == 2019) return 0.3;
    if (data.year == 2018) return 0.4;
    if (data.year == 2017) return 0.5;
    if (data.year == 2016) return 0.6;
    if (data.year == 2015) return 0.7;
    return 0.5;
  }

  /// Formata data para logging
  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  /// Limpa o cache
  void limparCache() {
    _cache.clear();
  }

  /// Obtém estatísticas do cache
  Map<String, dynamic> get estatisticasCache {
    return {'tamanho': _cache.length, 'periodos': _cache.keys.toList()};
  }
}


// // services/dados_historicos_service.dart
// import 'package:br_api/br_api.dart';
// import 'package:intl/intl.dart';
// import '../models/taxa_historica.dart';

// class DadosHistoricosService {
//   final BrasilAPI _brasilAPI = BrasilAPI();
  
//   // Cache para evitar requisições repetidas
//   final Map<String, TaxaHistorica> _cache = {};
  
//   /// Busca taxas para uma data específica
//   Future<TaxaHistorica> getTaxasPorData(DateTime data) async {
//     final chaveCache = DateFormat('yyyy-MM').format(data);
    
//     // Verifica cache
//     if (_cache.containsKey(chaveCache)) {
//       return _cache[chaveCache]!;
//     }
    
//     try {
//       // Formata data para a API (YYYY-MM)
//       final anoMes = DateFormat('yyyy-MM').format(data);
      
//       // Busca Selic (exemplo de endpoint - ajustar conforme documentação real)
//       final selicData = await _brasilAPI.bc.selic(anoMes);
      
//       // Busca CDI (pode precisar de ajustes ou fonte alternativa)
//       final cdiData = await _brasilAPI.bc.cdi(anoMes);
      
//       // Busca TR (endpoint específico)
//       final trData = await _brasilAPI.bc.tr(anoMes);
      
//       // Cria objeto com as taxas
//       final taxas = TaxaHistorica(
//         data: data,
//         selic: _extrairValorMedio(selicData), // Implementar parser
//         cdi: _extrairValorMedio(cdiData),
//         tr: _extrairValorMedio(trData),
//       );
      
//       // Salva no cache
//       _cache[chaveCache] = taxas;
      
//       return taxas;
//     } catch (e) {
//       print('Erro ao buscar taxas para $data: $e');
      
//       // Fallback para dados mockados (desenvolvimento)
//       return _getMockTaxas(data);
//     }
//   }
  
//   /// Extrai valor médio da resposta da API (implementar conforme formato real)
//   double _extrairValorMedio(dynamic response) {
//     // TODO: Implementar parser conforme estrutura real da Brasil API
//     // Exemplo: response['value'] ou response.data.valor
//     return 0.0;
//   }
  
//   /// Busca taxas para um período
//   Future<List<TaxaHistorica>> getTaxasPorPeriodo({
//     required DateTime inicio,
//     required DateTime fim,
//   }) async {
//     final List<TaxaHistorica> taxas = [];
//     DateTime dataAtual = DateTime(inicio.year, inicio.month, 1);
//     final dataFim = DateTime(fim.year, fim.month, 1);
    
//     while (dataAtual.isBefore(dataFim) || dataAtual.isAtSameMomentAs(dataFim)) {
//       final taxa = await getTaxasPorData(dataAtual);
//       taxas.add(taxa);
      
//       // Avança um mês
//       dataAtual = DateTime(dataAtual.year, dataAtual.month + 1, 1);
//     }
    
//     return taxas;
//   }
  
//   /// Dados mockados para desenvolvimento/fallback
//   TaxaHistorica _getMockTaxas(DateTime data) {
//     // Dados aproximados baseados na tabela do Santander 
//     final ano = data.year;
    
//     if (ano == 2023) return TaxaHistorica(data: data, selic: 13.75, cdi: 13.05, tr: 0.0);
//     if (ano == 2022) return TaxaHistorica(data: data, selic: 13.75, cdi: 12.39, tr: 0.0);
//     if (ano == 2021) return TaxaHistorica(data: data, selic: 9.25, cdi: 4.39, tr: 0.1);
//     if (ano == 2020) return TaxaHistorica(data: data, selic: 2.75, cdi: 2.75, tr: 0.2);
//     if (ano == 2019) return TaxaHistorica(data: data, selic: 5.94, cdi: 5.94, tr: 0.3);
//     if (ano == 2018) return TaxaHistorica(data: data, selic: 6.50, cdi: 6.50, tr: 0.4);
//     if (ano == 2017) return TaxaHistorica(data: data, selic: 9.25, cdi: 9.25, tr: 0.5);
//     if (ano == 2016) return TaxaHistorica(data: data, selic: 14.15, cdi: 14.15, tr: 0.6);
//     if (ano == 2015) return TaxaHistorica(data: data, selic: 14.25, cdi: 13.66, tr: 0.7);
    
//     // Valor padrão
//     return TaxaHistorica(data: data, selic: 10.0, cdi: 9.8, tr: 0.5);
//   }
// }