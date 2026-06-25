import 'package:intl/intl.dart';

final _inrFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

final _inrDecimalFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

/// Format as Indian rupee: ₹1,23,456
String formatCurrency(double amount) {
  return _inrFormat.format(amount);
}

/// Format with 2 decimal places
String formatCurrencyDecimal(double amount) {
  return _inrDecimalFormat.format(amount);
}

/// Format in Lakhs/Crores shorthand: ₹45L, ₹1.2Cr
String formatLakhsCrores(double amount) {
  if (amount >= 10000000) {
    final cr = amount / 10000000;
    if (cr == cr.truncateToDouble()) {
      return '₹${cr.toInt()}Cr';
    }
    return '₹${cr.toStringAsFixed(1)}Cr';
  } else if (amount >= 100000) {
    final lakh = amount / 100000;
    if (lakh == lakh.truncateToDouble()) {
      return '₹${lakh.toInt()}L';
    }
    return '₹${lakh.toStringAsFixed(1)}L';
  } else if (amount >= 1000) {
    final k = amount / 1000;
    return '₹${k.toStringAsFixed(1)}K';
  }
  return formatCurrency(amount);
}

/// Format as percentage: 12.5%
String formatPercent(double value, {int decimals = 1}) {
  return '${(value * 100).toStringAsFixed(decimals)}%';
}

/// Format as LPA: 12.5 LPA
String formatLpa(double lpa) {
  return '${lpa.toStringAsFixed(1)} LPA';
}
