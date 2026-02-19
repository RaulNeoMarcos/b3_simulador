// lib/widgets/comparativo_renda_fixa_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:b3_simulador/models/comparativo_renda_fixa.dart';

class ComparativoRendaFixaCard extends StatelessWidget {
  final ComparativoRendaFixa comparativo;
  final double retornoAcao; // Garantindo que é double
  final bool showDetalhado;

  const ComparativoRendaFixaCard({
    Key? key,
    required this.comparativo,
    required this.retornoAcao,
    this.showDetalhado = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final percentFormat = NumberFormat.decimalPercentPattern(
      locale: 'pt_BR',
      decimalDigits: 2,
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildComparativoBarras(currencyFormat, percentFormat),
            if (showDetalhado) ...[
              const SizedBox(height: 20),
              _buildTabelaComparativa(currencyFormat, percentFormat),
            ],
            const SizedBox(height: 16),
            _buildAnalise(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.trending_up, color: Colors.blue[700], size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comparação com Renda Fixa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Poupança vs CDI (líquido)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getMelhorInvestimentoColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getMelhorInvestimentoColor().withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 12, color: _getMelhorInvestimentoColor()),
              const SizedBox(width: 4),
              Text(
                'Melhor: ${comparativo.melhorInvestimento}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _getMelhorInvestimentoColor(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparativoBarras(
    NumberFormat currencyFormat,
    NumberFormat percentFormat,
  ) {
    // Converte todos os valores para double explicitamente
    final double retornoAcaoDouble = retornoAcao.toDouble();
    final double poupancaDouble = comparativo.percentualPoupanca.toDouble();
    final double cdiDouble = comparativo.percentualCDI.toDouble();

    // Encontra o maior percentual para escala
    final maxPercent = [
      retornoAcaoDouble.abs(),
      poupancaDouble.abs(),
      cdiDouble.abs(),
    ].reduce((a, b) => a > b ? a : b);

    final escala = maxPercent > 0 ? maxPercent / 100 : 1.0;

    return Column(
      children: [
        _buildBarraComparativa(
          label: 'Sua Ação',
          percentual: retornoAcaoDouble,
          valor: comparativo.valorInicial * (1 + retornoAcaoDouble / 100),
          cor: retornoAcaoDouble >= 0 ? Colors.green : Colors.red,
          escala: escala,
          currencyFormat: currencyFormat,
          percentFormat: percentFormat,
        ),
        const SizedBox(height: 12),
        _buildBarraComparativa(
          label: 'Poupança',
          percentual: poupancaDouble,
          valor: comparativo.valorFinalPoupanca,
          cor: Colors.blue,
          escala: escala,
          currencyFormat: currencyFormat,
          percentFormat: percentFormat,
        ),
        const SizedBox(height: 12),
        _buildBarraComparativa(
          label: '100% CDI (líq.)',
          percentual: cdiDouble,
          valor: comparativo.valorFinalCDI,
          cor: Colors.indigo,
          escala: escala,
          currencyFormat: currencyFormat,
          percentFormat: percentFormat,
        ),
      ],
    );
  }

  Widget _buildBarraComparativa({
    required String label,
    required double percentual,
    required double valor,
    required Color cor,
    required double escala,
    required NumberFormat currencyFormat,
    required NumberFormat percentFormat,
  }) {
    // Garante que percentual é double e calcula largura
    final double percentualAbs = percentual.abs();
    final double barraWidth = escala > 0
        ? (percentualAbs / (escala * 100)).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Row(
              children: [
                Text(
                  percentFormat.format(percentual / 100),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: percentual >= 0
                        ? Colors.green[700]
                        : Colors.red[700],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '· ${currencyFormat.format(valor)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            // Barra de fundo
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Barra de progresso
            FractionallySizedBox(
              widthFactor: barraWidth,
              alignment: Alignment.centerLeft,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [cor.withOpacity(0.7), cor]),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: cor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabelaComparativa(
    NumberFormat currencyFormat,
    NumberFormat percentFormat,
  ) {
    // Converte valores para double
    final double retornoAcaoDouble = retornoAcao.toDouble();
    final double poupancaDouble = comparativo.percentualPoupanca.toDouble();
    final double cdiDouble = comparativo.percentualCDI.toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.5),
        },
        children: [
          _buildTableRow(
            'Investimento',
            'Valor Final',
            'Rentabilidade',
            isHeader: true,
          ),
          _buildTableRow(
            'Sua Ação',
            currencyFormat.format(
              comparativo.valorInicial * (1 + retornoAcaoDouble / 100),
            ),
            percentFormat.format(retornoAcaoDouble / 100),
            corValor: retornoAcaoDouble >= 0
                ? Colors.green[700]
                : Colors.red[700],
          ),
          _buildTableRow(
            'Poupança',
            currencyFormat.format(comparativo.valorFinalPoupanca),
            percentFormat.format(poupancaDouble / 100),
            corValor: poupancaDouble >= 0 ? Colors.green[700] : Colors.red[700],
          ),
          _buildTableRow(
            'CDI (100%)',
            currencyFormat.format(comparativo.valorFinalCDI),
            percentFormat.format(cdiDouble / 100),
            corValor: cdiDouble >= 0 ? Colors.green[700] : Colors.red[700],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(
    String label,
    String valor,
    String percentual, {
    bool isHeader = false,
    Color? corValor,
  }) {
    final style = isHeader
        ? TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          )
        : TextStyle(fontSize: 13, color: Colors.grey[800]);

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Text(label, style: style),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            valor,
            style: style.copyWith(
              fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
              color: isHeader ? null : corValor,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Text(
            percentual,
            style: style.copyWith(
              fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
              color: isHeader ? null : corValor,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalise() {
    // Converte para double para comparações seguras
    final double retornoAcaoDouble = retornoAcao.toDouble();
    final double poupancaDouble = comparativo.percentualPoupanca.toDouble();
    final double cdiDouble = comparativo.percentualCDI.toDouble();

    final String mensagem;
    final Color cor;
    final IconData icone;

    if (retornoAcaoDouble > cdiDouble && retornoAcaoDouble > poupancaDouble) {
      mensagem = 'Sua ação superou tanto a Poupança quanto o CDI!';
      cor = Colors.green[700]!;
      icone = Icons.emoji_events;
    } else if (retornoAcaoDouble > poupancaDouble) {
      mensagem = 'Sua ação superou a Poupança, mas ficou abaixo do CDI.';
      cor = Colors.orange[700]!;
      icone = Icons.trending_up;
    } else if (retornoAcaoDouble > 0) {
      mensagem = 'Sua ação teve retorno positivo, mas abaixo da renda fixa.';
      cor = Colors.blue[700]!;
      icone = Icons.info;
    } else {
      mensagem = 'Sua ação teve desempenho inferior à renda fixa.';
      cor = Colors.red[700]!;
      icone = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 16, color: cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensagem,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMelhorInvestimentoColor() {
    switch (comparativo.melhorInvestimento) {
      case 'Poupança':
        return Colors.blue;
      case 'CDI':
        return Colors.indigo;
      default:
        return Colors.green;
    }
  }
}
