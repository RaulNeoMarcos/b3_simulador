// lib/widgets/valuation_avancado_card.dart

import 'package:flutter/material.dart';
import '../models/valuation_avancado.dart';

class ValuationAvancadoCard extends StatelessWidget {
  final ValuationAvancado valuation;

  const ValuationAvancadoCard({Key? key, required this.valuation})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Valuation Avançado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Preço Justo DCF: ${valuation.precoJustoDCF.toStringAsFixed(2)}',
            ),
            Text(
              'Preço Justo Gordon: ${valuation.precoJustoGordon.toStringAsFixed(2)}',
            ),
            Text(
              'Preço Justo EV/EBITDA: ${valuation.precoJustoEVEBITDA.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }
}
