import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class IndianCurrencyFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final intValue = int.tryParse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (intValue == null) {
      return oldValue;
    }

    final newText = _formatter.format(intValue).trim();

    // Preserve cursor position relative to the end of the text
    final oldOffsetFromEnd = oldValue.text.length - oldValue.selection.end;
    var newOffset = newText.length - oldOffsetFromEnd;
    
    // Adjust if cursor ends up before 0 somehow
    if (newOffset < 0) newOffset = newText.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
