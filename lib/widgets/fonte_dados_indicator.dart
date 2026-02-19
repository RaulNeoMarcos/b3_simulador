// widgets/fonte_dados_indicator.dart
import 'package:flutter/material.dart';

class FonteDadosIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance, size: 14, color: Colors.blue[700]),
          SizedBox(width: 4),
          Text(
            'Dados: BACEN / Brasil API',
            style: TextStyle(fontSize: 10, color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }
}
