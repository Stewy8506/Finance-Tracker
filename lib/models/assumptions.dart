import 'package:hive/hive.dart';

part 'assumptions.g.dart';

@HiveType(typeId: 3)
class Assumptions extends HiveObject {
  @HiveField(0)
  double sipReturnRate; // default 0.12

  @HiveField(1)
  double cashSavingsRate; // default 0.06

  @HiveField(2)
  double expenseInflation; // default 0.06

  @HiveField(3)
  double homeLoanRate; // default 0.085

  @HiveField(4)
  int loanTenureYears; // default 20

  Assumptions({
    required this.sipReturnRate,
    required this.cashSavingsRate,
    required this.expenseInflation,
    required this.homeLoanRate,
    required this.loanTenureYears,
  });

  factory Assumptions.defaults() => Assumptions(
        sipReturnRate: 0.12,
        cashSavingsRate: 0.06,
        expenseInflation: 0.06,
        homeLoanRate: 0.085,
        loanTenureYears: 20,
      );

  Assumptions copyWith({
    double? sipReturnRate,
    double? cashSavingsRate,
    double? expenseInflation,
    double? homeLoanRate,
    int? loanTenureYears,
  }) {
    return Assumptions(
      sipReturnRate: sipReturnRate ?? this.sipReturnRate,
      cashSavingsRate: cashSavingsRate ?? this.cashSavingsRate,
      expenseInflation: expenseInflation ?? this.expenseInflation,
      homeLoanRate: homeLoanRate ?? this.homeLoanRate,
      loanTenureYears: loanTenureYears ?? this.loanTenureYears,
    );
  }
}
