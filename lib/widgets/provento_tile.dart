// lib/widgets/provento_tile.dart
import 'package:flutter/material.dart';
import '../models/provento.dart';

class ProventoTile extends StatelessWidget {
  final Provento provento;

  const ProventoTile({Key? key, required this.provento}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getCorTipo().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getIconeTipo(), color: _getCorTipo()),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provento.tipoFormatado,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Pagamento: ${DateTimeFormat(provento.dataPagamento).dataFormatada}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                provento.valorFormatado(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              if (provento.dataEx != null)
                Text(
                  'Ex: ${DateTimeFormat(provento.dataEx!).dataFormatada}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCorTipo() {
    switch (provento.tipo) {
      case TipoProvento.dividendo:
        return Colors.blue;
      case TipoProvento.jcp:
        return Colors.purple;
      case TipoProvento.rendimento:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconeTipo() {
    switch (provento.tipo) {
      case TipoProvento.dividendo:
        return Icons.attach_money;
      case TipoProvento.jcp:
        return Icons.percent;
      case TipoProvento.rendimento:
        return Icons.trending_up;
      default:
        return Icons.payments;
    }
  }
}

// extension on DateTime {
//   String get dataFormatada =>
//       '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
// }
