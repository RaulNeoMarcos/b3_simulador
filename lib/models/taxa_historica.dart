// lib/models/taxa_historica.dart

class TaxaHistorica {
  final DateTime data;
  final double selic; // Taxa Selic anual (%)
  final double cdi; // Taxa CDI anual (%)
  final double tr; // Taxa Referencial mensal (%)

  TaxaHistorica({
    required this.data,
    required this.selic,
    required this.cdi,
    required this.tr,
  });

  /// Formata a data para exibição
  String get dataFormatada =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

  /// Retorna o rendimento da poupança para este mês
  double get rendimentoPoupancaMensal {
    if (selic > 8.5) {
      // Acima de 8.5%: 0.5% ao mês + TR
      return 0.5 + tr;
    } else {
      // Abaixo ou igual: 70% da Selic ao ano (convertido para mensal)
      final selicMensal = selic / 12;
      return 0.7 * selicMensal + tr;
    }
  }

  /// Retorna o rendimento do CDI para este mês (bruto)
  double get rendimentoCDIMensal => cdi / 12;

  @override
  String toString() {
    return 'TaxaHistorica(data: $dataFormatada, Selic: ${selic.toStringAsFixed(2)}%, CDI: ${cdi.toStringAsFixed(2)}%, TR: ${tr.toStringAsFixed(3)}%)';
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'data': data.toIso8601String(),
    'selic': selic,
    'cdi': cdi,
    'tr': tr,
  };

  /// Constrói a partir de JSON
  factory TaxaHistorica.fromJson(Map<String, dynamic> json) => TaxaHistorica(
    data: DateTime.parse(json['data']),
    selic: json['selic']?.toDouble() ?? 0,
    cdi: json['cdi']?.toDouble() ?? 0,
    tr: json['tr']?.toDouble() ?? 0,
  );
}
