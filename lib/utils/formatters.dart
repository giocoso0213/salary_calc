String formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return _addCommas(value.toStringAsFixed(0));
  }
  return _addCommas(value.toStringAsFixed(2));
}

String formatCurrency(double value) => '${formatNumber(value.roundToDouble())}원';

String formatManwon(double value) => '${formatNumber(value)}만 원';

String maskCurrency() => '***,***원';

String maskPercentile() => '***';

String _addCommas(String number) {
  final parts = number.split('.');
  final integerPart = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  if (parts.length == 1) return integerPart;
  return '$integerPart.${parts[1]}';
}

String formatDateTime(DateTime dateTime) {
  final year = dateTime.year.toString();
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$year.$month.$day $hour:$minute';
}
