// lib/widgets/grafico_evolucao.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/cotacao.dart';

class GraficoEvolucao extends StatelessWidget {
  final List<Cotacao> cotacoes;
  final Color corLinha;

  const GraficoEvolucao({
    Key? key,
    required this.cotacoes,
    required this.corLinha,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (cotacoes.isEmpty) {
      return Center(child: Text('Sem dados para exibir'));
    }

    final spots = cotacoes.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.fechamento);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: corLinha,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: corLinha.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
