import 'package:flutter/services.dart';

import 'formatters.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) {
      return const TextEditingValue();
    }

    if (!RegExp(r'^\d*\.?\d*$').hasMatch(raw)) {
      return oldValue;
    }

    final parts = raw.split('.');
    final integerDigits = parts[0];
    final formattedInteger =
        integerDigits.isEmpty ? '' : formatIntegerWithCommas(integerDigits);

    var formatted = formattedInteger;
    if (parts.length > 1) {
      formatted = '$formattedInteger.${parts[1]}';
    } else if (raw.endsWith('.')) {
      formatted = '$formattedInteger.';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class MaxValueInputFormatter extends TextInputFormatter {
  MaxValueInputFormatter(this.max);

  final double max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '').trim();
    if (raw.isEmpty) return newValue;

    final value = double.tryParse(raw);
    if (value == null) return oldValue;
    if (value > max) return oldValue;
    return newValue;
  }
}

String formatIntegerWithCommas(String digits) {
  return digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

String formatInputNumber(double value) {
  if (value == 0) return '';
  return formatNumber(value);
}
