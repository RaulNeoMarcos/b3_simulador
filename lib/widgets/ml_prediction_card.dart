// lib/widgets/ml_prediction_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ml_prediction.dart';

class MLPredictionCard extends StatelessWidget {
  final MLPrediction prediction;
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  MLPredictionCard({Key? key, required this.prediction}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSinais(),
            const SizedBox(height: 20),
            _buildPrevisoes(),
            const SizedBox(height: 20),
            _buildProbabilidades(),
            const SizedBox(height: 20),
            _buildMetricasModelo(),
            const SizedBox(height: 16),
            _buildFeaturesImportantes(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.psychology, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ML Predictions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Modelo: ${prediction.modelo.toString().split('.').last}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Acurácia: ${(prediction.acuracia * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSinais() {
    return Row(
      children: [
        Expanded(
          child: _buildSinalCard(
            'Curto Prazo',
            prediction.sinalCurtoPrazoTexto,
            prediction.sinalCurtoPrazoCor,
            Icons.today,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSinalCard(
            'Médio Prazo',
            prediction.sinalMedioPrazoTexto,
            prediction.sinalMedioPrazoCor,
            Icons.date_range,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSinalCard(
            'Longo Prazo',
            prediction.sinalLongoPrazoTexto,
            prediction.sinalLongoPrazoCor,
            Icons.calendar_month,
          ),
        ),
      ],
    );
  }

  Widget _buildSinalCard(
    String titulo,
    String sinal,
    Color cor,
    IconData icone,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 16),
          const SizedBox(height: 4),
          Text(titulo, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            sinal,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrevisoes() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPrevisaoItem('1 dia', prediction.precoPrevisto1d),
            _buildPrevisaoItem('1 semana', prediction.precoPrevisto1s),
            _buildPrevisaoItem('1 mês', prediction.precoPrevisto1m),
            _buildPrevisaoItem('3 meses', prediction.precoPrevisto3m),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Intervalo de Confiança (95%)',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${currencyFormat.format(prediction.limiteInferior)} - ${currencyFormat.format(prediction.limiteSuperior)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrevisaoItem(String periodo, double preco) {
    return Column(
      children: [
        Text(periodo, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(preco),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProbabilidades() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: prediction.probabilidadeAlta.toInt(),
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${prediction.probabilidadeAlta.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: prediction.probabilidadeBaixa.toInt(),
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${prediction.probabilidadeBaixa.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Alta', style: TextStyle(color: Colors.green)),
            const Text('Baixa', style: TextStyle(color: Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricasModelo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricaItem('Precisão', prediction.precisao),
              _buildMetricaItem('Recall', prediction.recall),
              _buildMetricaItem('F1-Score', prediction.f1Score),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dias de treinamento: ${prediction.diasTreinamento}'),
              Text(
                'Último treino: ${DateFormat('dd/MM/yyyy').format(prediction.dataUltimoTreinamento)}',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricaItem(String label, double valor) {
    return Column(
      children: [
        Text(
          '${(valor * 100).toStringAsFixed(1)}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildFeaturesImportantes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔑 Features Mais Importantes',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...prediction.topFeatures.map((f) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _getFeatureName(f.feature),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: f.importance,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.purple,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(f.importance * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String _getFeatureName(String feature) {
    const nomes = {
      'rsi14': 'RSI (14)',
      'macd': 'MACD',
      'bb_position': 'Posição BB',
      'volume_ratio': 'Volume',
      'pl': 'P/L',
      'dividend_yield': 'Dividend Yield',
      'momentum20': 'Momentum 20d',
    };
    return nomes[feature] ?? feature;
  }
}
