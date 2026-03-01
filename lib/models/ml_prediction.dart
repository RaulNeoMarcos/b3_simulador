// lib/models/ml_prediction.dart

import 'package:flutter/material.dart';

enum ModeloML { randomForest, gradientBoosting, lstm, svm, ensemble }

enum SinalTendencia { compraForte, compra, neutro, venda, vendaForte }

class FeatureImportance {
  final String feature;
  final double importance;

  FeatureImportance({required this.feature, required this.importance});
}

class MLPrediction {
  final String ticker;
  final DateTime dataPrevisao;
  final ModeloML modelo;
  final double precoPrevisto1d;
  final double precoPrevisto1s;
  final double precoPrevisto1m;
  final double precoPrevisto3m;
  final double probabilidadeAlta;
  final double probabilidadeBaixa;
  final SinalTendencia sinalCurtoPrazo;
  final SinalTendencia sinalMedioPrazo;
  final SinalTendencia sinalLongoPrazo;
  final double acuracia;
  final double precisao;
  final double recall;
  final double f1Score;
  final List<FeatureImportance> topFeatures;
  final double intervaloConfianca;
  final double limiteInferior;
  final double limiteSuperior;
  final int diasTreinamento;
  final DateTime dataUltimoTreinamento;
  final String fonteDados; // Ex: "Alpha Vantage", "Fundamentus", "Fallback"

  MLPrediction({
    required this.ticker,
    required this.dataPrevisao,
    required this.modelo,
    required this.precoPrevisto1d,
    required this.precoPrevisto1s,
    required this.precoPrevisto1m,
    required this.precoPrevisto3m,
    required this.probabilidadeAlta,
    required this.probabilidadeBaixa,
    required this.sinalCurtoPrazo,
    required this.sinalMedioPrazo,
    required this.sinalLongoPrazo,
    required this.acuracia,
    required this.precisao,
    required this.recall,
    required this.f1Score,
    required this.topFeatures,
    required this.intervaloConfianca,
    required this.limiteInferior,
    required this.limiteSuperior,
    required this.diasTreinamento,
    required this.dataUltimoTreinamento,
    required this.fonteDados,
  });

  // Getters para texto dos sinais
  String get sinalCurtoPrazoTexto {
    switch (sinalCurtoPrazo) {
      case SinalTendencia.compraForte:
        return 'COMPRA FORTE';
      case SinalTendencia.compra:
        return 'COMPRA';
      case SinalTendencia.neutro:
        return 'NEUTRO';
      case SinalTendencia.venda:
        return 'VENDA';
      case SinalTendencia.vendaForte:
        return 'VENDA FORTE';
    }
  }

  String get sinalMedioPrazoTexto {
    switch (sinalMedioPrazo) {
      case SinalTendencia.compraForte:
        return 'COMPRA FORTE';
      case SinalTendencia.compra:
        return 'COMPRA';
      case SinalTendencia.neutro:
        return 'NEUTRO';
      case SinalTendencia.venda:
        return 'VENDA';
      case SinalTendencia.vendaForte:
        return 'VENDA FORTE';
    }
  }

  String get sinalLongoPrazoTexto {
    switch (sinalLongoPrazo) {
      case SinalTendencia.compraForte:
        return 'COMPRA FORTE';
      case SinalTendencia.compra:
        return 'COMPRA';
      case SinalTendencia.neutro:
        return 'NEUTRO';
      case SinalTendencia.venda:
        return 'VENDA';
      case SinalTendencia.vendaForte:
        return 'VENDA FORTE';
    }
  }

  // Getters para cores dos sinais
  Color get sinalCurtoPrazoCor {
    switch (sinalCurtoPrazo) {
      case SinalTendencia.compraForte:
        return Colors.green;
      case SinalTendencia.compra:
        return Colors.lightGreen;
      case SinalTendencia.neutro:
        return Colors.orange;
      case SinalTendencia.venda:
        return Colors.deepOrange;
      case SinalTendencia.vendaForte:
        return Colors.red;
    }
  }

  Color get sinalMedioPrazoCor {
    switch (sinalMedioPrazo) {
      case SinalTendencia.compraForte:
        return Colors.green;
      case SinalTendencia.compra:
        return Colors.lightGreen;
      case SinalTendencia.neutro:
        return Colors.orange;
      case SinalTendencia.venda:
        return Colors.deepOrange;
      case SinalTendencia.vendaForte:
        return Colors.red;
    }
  }

  Color get sinalLongoPrazoCor {
    switch (sinalLongoPrazo) {
      case SinalTendencia.compraForte:
        return Colors.green;
      case SinalTendencia.compra:
        return Colors.lightGreen;
      case SinalTendencia.neutro:
        return Colors.orange;
      case SinalTendencia.venda:
        return Colors.deepOrange;
      case SinalTendencia.vendaForte:
        return Colors.red;
    }
  }
}
