// lib/models/valuation_avancado.dart

import 'dart:ui';

class ValuationAvancado {
  final String ticker;
  final double precoAtual;
  final double precoJustoDCF;
  final double potencialValorizacaoDCF;
  final Map<int, double> fluxosProjetados;
  final double precoJustoGordon;
  final double potencialValorizacaoGordon;
  final double precoJustoEVEBITDA;
  final double potencialValorizacaoEVEBITDA;
  final String recomendacao;
  final Color corRecomendacao;

  ValuationAvancado({
    required this.ticker,
    required this.precoAtual,
    required this.precoJustoDCF,
    required this.potencialValorizacaoDCF,
    required this.fluxosProjetados,
    required this.precoJustoGordon,
    required this.potencialValorizacaoGordon,
    required this.precoJustoEVEBITDA,
    required this.potencialValorizacaoEVEBITDA,
    required this.recomendacao,
    required this.corRecomendacao,
  });
}
