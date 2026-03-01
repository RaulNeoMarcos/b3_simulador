// lib/widgets/ml_prediction_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ml_prediction.dart';

class MLPredictionCard extends StatelessWidget {
  final MLPrediction prediction;
  final String fonteDados; // NOVO PARÂMETRO
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  MLPredictionCard({
    Key? key,
    required this.prediction,
    required this.fonteDados,
  }) : super(key: key);

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
            _buildFonteIndicator(),
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
            //const SizedBox(height: 20),
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
          // 🔥 ADICIONE Expanded em cada filho
          child: _buildSinalCard(
            'Curto Prazo',
            prediction.sinalCurtoPrazoTexto,
            prediction.sinalCurtoPrazoCor,
            Icons.today,
          ),
        ),
        const SizedBox(width: 4), // Reduza o espaçamento
        Expanded(
          child: _buildSinalCard(
            'Médio Prazo',
            prediction.sinalMedioPrazoTexto,
            prediction.sinalMedioPrazoCor,
            Icons.date_range,
          ),
        ),
        const SizedBox(width: 4),
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

  // Ajuste o _buildSinalCard para textos menores:
  Widget _buildSinalCard(
    String titulo,
    String sinal,
    Color cor,
    IconData icone,
  ) {
    return Container(
      padding: const EdgeInsets.all(8), // Padding reduzido
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: cor, size: 14), // Ícone menor
          const SizedBox(height: 2),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey[600],
            ), // Fonte menor
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            sinal,
            style: TextStyle(
              fontSize: 9, // Fonte menor
              fontWeight: FontWeight.bold,
              color: cor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            _buildPrevisaoItem(
              '1 sem',
              prediction.precoPrevisto1s,
            ), // Texto menor
            _buildPrevisaoItem('1 mês', prediction.precoPrevisto1m),
            _buildPrevisaoItem(
              '3 m',
              prediction.precoPrevisto3m,
            ), // Texto menor
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8), // Padding reduzido
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'IC (95%)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
              Text(
                '${currencyFormat.format(prediction.limiteInferior)} - ${currencyFormat.format(prediction.limiteSuperior)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFonteIndicator() {
    Color fonteCor;
    IconData fonteIcon;

    switch (fonteDados) {
      case 'Alpha Vantage':
        fonteCor = Colors.blue;
        fonteIcon = Icons.api;
        break;
      case 'Fundamentus':
        fonteCor = Colors.green;
        fonteIcon = Icons.trending_up;
        break;
      case 'CVM':
        fonteCor = Colors.purple;
        fonteIcon = Icons.account_balance;
        break;
      default:
        fonteCor = Colors.orange;
        fonteIcon = Icons.storage;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fonteCor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fonteCor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(fonteIcon, size: 12, color: fonteCor),
          const SizedBox(width: 4),
          Text(
            'Fonte: $fonteDados',
            style: TextStyle(
              fontSize: 10,
              color: fonteCor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrevisaoItem(String periodo, double preco) {
    return Column(
      children: [
        Text(periodo, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          currencyFormat.format(preco),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
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
                height: 25,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.horizontal(
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
                height: 25,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.horizontal(
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
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Alta', style: TextStyle(color: Colors.green)),
            Text('Baixa', style: TextStyle(color: Colors.red)),
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
              Expanded(
                // Cada item ocupa espaço igual
                child: _buildMetricaItem('Precisão', prediction.precisao),
              ),
              const SizedBox(width: 4), // Espaço reduzido
              Expanded(child: _buildMetricaItem('Recall', prediction.recall)),
              const SizedBox(width: 4),
              Expanded(
                child: _buildMetricaItem('F1-Score', prediction.f1Score),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                // Permite quebra de linha se necessário
                child: Text(
                  'Dias de treinamento: ${prediction.diasTreinamento}',
                  style: const TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Último treino: ${DateFormat('dd/MM/yy').format(prediction.dataUltimoTreinamento)}',
                style: const TextStyle(fontSize: 9),
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
        Row(
          children: [
            const Text(
              '🔑 Features Mais Importantes',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message:
                  'Features são os indicadores que o modelo de ML considera mais relevantes. A porcentagem indica o peso relativo de cada feature nas previsões.',
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 🔥 VERIFICA SE EXISTEM FEATURES
        if (prediction.topFeatures.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Dados insuficientes para calcular importância das features',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          )
        else
          ...prediction.topFeatures.map((f) {
            // 🔥 GARANTIR QUE O VALOR É VÁLIDO
            double importanceValue = f.importance.isFinite
                ? f.importance.clamp(0, 1)
                : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Tooltip(
                          message: _getFeatureDescription(f.feature),
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.help_outline,
                              size: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _getFeatureName(f.feature),
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: LinearProgressIndicator(
                      value: importanceValue,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        importanceValue > 0.3 ? Colors.purple : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40, // Largura fixa para alinhar
                    child: Text(
                      '${(importanceValue * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

        // 🔥 RODAPÉ EXPLICATIVO
        if (prediction.topFeatures.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, size: 14, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'A soma das importâncias é 100%. Quanto maior a barra, mais influente é o indicador nas previsões.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[900],
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 🔥 NOVO MÉTODO: Descrição detalhada de cada feature
  String _getFeatureDescription(String feature) {
    final descriptions = {
      'rsi14':
          'RSI (Relative Strength Index): Indicador de momentum que mede a velocidade e magnitude dos movimentos de preço. Valores acima de 70 indicam sobrecompra, abaixo de 30 indicam sobrevenda.',
      'macd':
          'MACD (Moving Average Convergence Divergence): Indicador de tendência que mostra a relação entre duas médias móveis. Cruzes positivos indicam tendência de alta, negativos de baixa.',
      'bb_position':
          'Posição nas Bandas de Bollinger: Mostra se o preço está próximo da banda superior (sobrecompra) ou inferior (sobrevenda).',
      'volume_ratio':
          'Relação de Volume: Compara o volume atual com a média histórica. Volume alto confirma movimentos de preço.',
      'pl':
          'P/L (Preço/Lucro): Relação entre o preço da ação e o lucro por ação. Quanto menor, mais barata a ação em relação aos lucros.',
      'dividend_yield':
          'Dividend Yield: Retorno em dividendos em relação ao preço da ação. Quanto maior, mais retorno em proventos.',
      'momentum20':
          'Momentum de 20 dias: Variação percentual do preço nos últimos 20 pregões. Positivo indica tendência de alta.',
      'ma5':
          'Média Móvel de 5 dias: Preço médio dos últimos 5 dias. Usado para tendências de curto prazo.',
      'ma20':
          'Média Móvel de 20 dias: Preço médio do último mês. Indicador de tendência de médio prazo.',
      'volatilidade20':
          'Volatilidade de 20 dias: Mede a variação média dos preços. Alta volatilidade significa maior risco.',
      'beta':
          'Beta: Mede a volatilidade da ação em relação ao mercado. Beta > 1 indica maior volatilidade que o Ibovespa.',
    };

    return descriptions[feature] ??
        'Feature técnica utilizada pelo modelo de machine learning para fazer previsões.';
  }

  // Mantenha o _getFeatureName como está
  String _getFeatureName(String feature) {
    const nomes = {
      'rsi14': 'RSI (14)',
      'macd': 'MACD',
      'bb_position': 'Posição BB',
      'volume_ratio': 'Volume',
      'pl': 'P/L',
      'dividend_yield': 'Dividend Yield',
      'momentum20': 'Momentum 20d',
      'ma5': 'Média 5d',
      'ma20': 'Média 20d',
      'volatilidade20': 'Volatilidade',
      'beta': 'Beta',
    };
    return nomes[feature] ?? feature;
  }
}
