// lib/utils/formatadores.dart

import 'package:intl/intl.dart';

class Formatadores {
  // Formatadores sem depender do locale global
  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat monthFormat = DateFormat('MM/yyyy');
  static final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  static final NumberFormat percentFormat = NumberFormat.decimalPercentPattern(
    locale: 'pt_BR',
    decimalDigits: 2,
  );

  // Métodos auxiliares
  static String formatDate(DateTime date) => dateFormat.format(date);
  static String formatCurrency(double value) => currencyFormat.format(value);
  static String formatPercent(double value) =>
      percentFormat.format(value / 100);
}
