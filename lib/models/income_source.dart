import 'package:hive/hive.dart';

part 'income_source.g.dart';

/// An additional income stream beyond salary (freelance, rental, dividends, etc.).
@HiveType(typeId: 4)
class IncomeSource extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String label; // e.g. 'Freelance', 'Rental Income'

  @HiveField(2)
  double monthlyAmount; // ₹ per month

  @HiveField(3)
  double annualGrowthPct; // e.g. 0.05 for 5% growth per year

  IncomeSource({
    required this.id,
    required this.label,
    required this.monthlyAmount,
    required this.annualGrowthPct,
  });

  IncomeSource copyWith({
    String? id,
    String? label,
    double? monthlyAmount,
    double? annualGrowthPct,
  }) {
    return IncomeSource(
      id: id ?? this.id,
      label: label ?? this.label,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      annualGrowthPct: annualGrowthPct ?? this.annualGrowthPct,
    );
  }

  /// Monthly income at a given year, grown by annual growth rate.
  double amountAtYear(int year) {
    if (year <= 0) return monthlyAmount;
    return monthlyAmount * _pow(1 + annualGrowthPct, year - 1);
  }

  static double _pow(double base, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
