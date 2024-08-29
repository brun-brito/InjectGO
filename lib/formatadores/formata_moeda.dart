
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '0,00');
    }

    double value = double.parse(newValue.text.replaceAll(RegExp(r'[^\d]'), ''));

    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2);
    String newText = formatter.format(value / 100);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}