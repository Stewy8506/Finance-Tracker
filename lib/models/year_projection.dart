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
  final double expensesMonthly;
  final double freeCashMonthly;

  const YearProjection({
    required this.year,
    required this.ctcLpa,
    required this.takeHomeMonthly,
    required this.sipMonthly,
    required this.techSpendAnnual,
    required this.corpus,
    required this.goalsFunded,
    required this.expensesMonthly,
    required this.freeCashMonthly,
  });
}
