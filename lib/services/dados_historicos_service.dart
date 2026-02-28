// lib/services/dados_historicos_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:b3_simulador/services/logger_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/taxa_historica.dart';

class DadosHistoricosService {
  final LoggerService _log = LoggerService();
  // APIs do Banco Central do Brasil
  static const String _bcbBaseUrl =
      'https://api.bcb.gov.br/dados/serie/bcdata.sgs.';

  // Códigos SGS (Sistema Gerenciador de Séries Temporais do BCB)
  static const Map<String, int> _codigosSeries = {
    'selic': 11, // Taxa Selic acumulada no mês
    'cdi': 4390, // Taxa CDI diária
    'tr': 7809, // Taxa Referencial mensal
  };

  // Projeções realistas baseadas no Relatório Focus
  static const Map<int, Map<String, double>> _projecoes = {
    2024: {'selic': 11.75, 'cdi': 11.65, 'tr': 0.0}, // 11.65% ao ano
    2025: {'selic': 10.00, 'cdi': 9.90, 'tr': 0.0}, // 9.90% ao ano
    2026: {'selic': 9.50, 'cdi': 9.40, 'tr': 0.0}, // 9.40% ao ano
  };

  final Map<String, List<TaxaHistorica>> _cache = {};

  static const int MAX_RETRIES = 2;
  static const Duration TIMEOUT = Duration(seconds: 10);

  Future<List<TaxaHistorica>> getTaxasPorPeriodo({
    required DateTime inicio,
    required DateTime fim,
    bool usarCache = true,
  }) async {
    final cacheKey = '${inicio.toIso8601String()}-${fim.toIso8601String()}';

    _log.info(
      'Buscando taxas históricas',
      tag: 'BCB',
      data: {
        'inicio': inicio.toIso8601String(),
        'fim': fim.toIso8601String(),
        'usar_cache': usarCache,
      },
    );

    if (usarCache && _cache.containsKey(cacheKey)) {
      _log.debug(
        'Usando cache',
        tag: 'BCB',
        data: {'cache_key': cacheKey, 'tamanho': _cache[cacheKey]?.length},
      );
      return _cache[cacheKey]!;
    }

    final hoje = DateTime.now();
    final taxas = <TaxaHistorica>[];

    var dataAtual = DateTime(inicio.year, inicio.month, 1);
    final dataFim = DateTime(fim.year, fim.month, 1);

    int mesesProcessados = 0;
    int mesesReais = 0;
    int mesesProjetados = 0;

    while (!dataAtual.isAfter(dataFim)) {
      mesesProcessados++;

      try {
        TaxaHistorica taxa;

        if (dataAtual.isBefore(hoje) || dataAtual.isAtSameMomentAs(hoje)) {
          taxa = await _buscarTaxaReal(dataAtual);
          mesesReais++;
        } else {
          taxa = _gerarTaxaProjetada(dataAtual);
          mesesProjetados++;
        }

        taxas.add(taxa);

        if (mesesProcessados % 12 == 0) {
          _log.debug(
            'Progresso: $mesesProcessados meses',
            tag: 'BCB',
            data: {'reais': mesesReais, 'projetados': mesesProjetados},
          );
        }
      } catch (e, stackTrace) {
        _log.error(
          'Erro ao processar mês',
          tag: 'BCB',
          error: e,
          stackTrace: stackTrace,
          data: {'mes': dataAtual.month, 'ano': dataAtual.year},
        );
      }

      dataAtual = DateTime(dataAtual.year, dataAtual.month + 1, 1);
    }

    _log.info(
      'Processamento concluído',
      tag: 'BCB',
      data: {
        'total_meses': mesesProcessados,
        'meses_reais': mesesReais,
        'meses_projetados': mesesProjetados,
      },
    );

    if (usarCache) {
      _cache[cacheKey] = taxas;
    }

    return taxas;
  }

  /// Busca dados REAIS para um mês específico
  Future<TaxaHistorica> _buscarTaxaReal(DateTime data) async {
    _log.debug(
      'Buscando taxa real',
      tag: 'BCB',
      data: {'mes': data.month, 'ano': data.year},
    );

    try {
      double? selic = await _buscarValorSerie('selic', data);
      double? cdi = await _buscarValorSerie('cdi', data);
      double? tr = await _buscarValorSerie('tr', data);

      _log.debug(
        'Valores obtidos',
        tag: 'BCB',
        data: {
          'selic': selic,
          'cdi': cdi,
          'tr': tr,
          'fonte': selic != null ? 'API' : 'projeção',
        },
      );

      return TaxaHistorica(
        data: data,
        selic: selic ?? _getProjecaoAno(data.year)['selic']!,
        cdi: cdi ?? _getProjecaoAno(data.year)['cdi']!,
        tr: (tr ?? _getProjecaoAno(data.year)['tr']!) / 100,
      );
    } catch (e, stackTrace) {
      _log.error(
        'Erro ao buscar taxa real, usando projeção',
        tag: 'BCB',
        error: e,
        stackTrace: stackTrace,
        data: {'mes': data.month, 'ano': data.year},
      );
      return _gerarTaxaProjetada(data);
    }
  }

  /// Busca valor de uma série para um período
  Future<double?> _buscarValorSerie(String serie, DateTime data) async {
    final codigo = _codigosSeries[serie];
    if (codigo == null) return null;

    try {
      final url = '...'; // sua URL
      final response = await http.get(Uri.parse(url)).timeout(TIMEOUT);

      if (response.statusCode == 200) {
        final List<dynamic> dataList = json.decode(response.body);

        if (dataList.isNotEmpty) {
          double soma = 0;
          int count = 0;

          for (var item in dataList) {
            final valor = double.parse(
              item['valor'].toString().replaceAll(',', '.'),
            );
            soma += valor;
            count++;
          }

          if (count > 0) {
            final media = soma / count;

            // 🚨 CORREÇÃO CRÍTICA: Se o valor for menor que 1, provavelmente veio em decimal
            // e precisa ser convertido para percentual
            if (media < 1 && serie != 'tr') {
              // TR pode ser realmente pequena
              final valorPercentual = media * 100;
              print(
                '📊 $serie em ${data.month}/${data.year}: ${media}% → CORRIGIDO: ${valorPercentual}%',
              );
              return valorPercentual;
            }

            print('📊 $serie em ${data.month}/${data.year}: $media%');
            return media;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Gera taxa PROJETADA baseada no Focus
  TaxaHistorica _gerarTaxaProjetada(DateTime data) {
    final projecao = _getProjecaoAno(data.year);

    return TaxaHistorica(
      data: data,
      selic: projecao['selic']!,
      cdi: projecao['cdi']!,
      tr: projecao['tr']! / 100,
    );
  }

  /// Obtém projeção para um ano
  Map<String, double> _getProjecaoAno(int ano) {
    if (_projecoes.containsKey(ano)) {
      return _projecoes[ano]!;
    }

    // Para anos além das projeções, mantém a última conhecida
    return _projecoes.values.last;
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  void limparCache() {
    _cache.clear();
  }
}
