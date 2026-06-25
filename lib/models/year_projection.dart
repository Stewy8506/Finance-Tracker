/// Plain Dart class — not persisted in Hive.
/// Computed each time by the finance engine from UserProfile + Goals + Purchases.
class YearProjection {
  final int year;
  final double ctcLpa;
  final double takeHomeMonthly;
  final double sipMonthly;
  final double techSpendAnnual;
  final double corpus;
  final List<String> goalsFunded;
  final List<String> fundedGoalIds;
  final double expensesMonthly;
  final double freeCashMonthly;

  /// Additional income from non-salary sources at this year.
  final double additionalIncome;

  /// Total monthly income (salary take-home + additional).
  final double totalIncome;

  const YearProjection({
    required this.year,
    required this.ctcLpa,
    required this.takeHomeMonthly,
    required this.sipMonthly,
    required this.techSpendAnnual,
    required this.corpus,
    required this.goalsFunded,
    this.fundedGoalIds = const [],
    required this.expensesMonthly,
    required this.freeCashMonthly,
    this.additionalIncome = 0,
    this.totalIncome = 0,
  });
}
