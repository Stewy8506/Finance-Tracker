import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/finance.dart' as finance;
import 'package:ledger/models/goal.dart';
import 'package:ledger/models/user_profile.dart';
import 'package:ledger/models/recurring_purchase.dart';
import 'package:ledger/models/assumptions.dart';
import 'package:ledger/models/income_source.dart';

void main() {
  group('Finance Engine Tests', () {
    test('calculateAnnualTax - new regime 87A rebate boundary', () {
      // 10 LPA CTC under new regime should be fully rebate exempted
      final tax = finance.calculateAnnualTax(10.0, 'new');
      expect(tax, equals(0.0));
    });

    test('calculateAnnualTax - old regime 87A rebate boundary', () {
      // 5 LPA CTC under old regime should be fully rebate exempted
      final tax = finance.calculateAnnualTax(5.0, 'old');
      expect(tax, equals(0.0));
    });

    test('calculateAnnualTax - high CTC taxable check', () {
      // 20 LPA CTC under new regime should be taxable
      final tax = finance.calculateAnnualTax(20.0, 'new');
      expect(tax, greaterThan(0.0));
    });

    test('calculateTakeHome matches ctc tax deduction', () {
      final takeHome = finance.calculateTakeHome(12.0, 'new');
      expect(takeHome, greaterThan(0));
      expect(takeHome * 12, lessThan(1200000)); // take-home should be less than CTC
    });

    test('sipFutureValue math validation', () {
      // 10k monthly for 10 years at 12% return
      final fv = finance.sipFutureValue(10000, 120, 0.12);
      expect(fv, greaterThan(2300000));
      expect(fv, lessThan(2400000));
    });

    test('monthlyEmi standard home loan', () {
      // 1Cr home loan at 8.5% for 20 years
      final emi = finance.monthlyEmi(10000000, 0.085, 20);
      expect(emi, greaterThan(86000));
      expect(emi, lessThan(88000));
    });

    test('yearsToGoal - inflation adjustment effect', () {
      final profile = UserProfile(
        startingCtcLpa: 15.0,
        annualHikePct: 0.10,
        taxRegime: 'new',
        cityPreset: 'metro',
        monthlyRent: 20000,
        monthlyFood: 10000,
        monthlyTransport: 5000,
        monthlyMisc: 5000,
        sipRatePct: 0.20,
        onboardingComplete: true,
      );

      final assumptions = Assumptions(
        sipReturnRate: 0.12,
        cashSavingsRate: 0.06,
        expenseInflation: 0.06,
        homeLoanRate: 0.085,
        loanTenureYears: 20,
      );

      final purchases = <RecurringPurchase>[];

      final goalNoInflation = Goal(
        id: 'g1',
        name: 'House (Fixed)',
        targetAmount: 5000000,
        targetYear: 10,
        type: 'down_payment',
        priority: 'high',
        adjustForInflation: false,
      );

      final goalWithInflation = Goal(
        id: 'g2',
        name: 'House (Inflated)',
        targetAmount: 5000000,
        targetYear: 10,
        type: 'down_payment',
        priority: 'high',
        adjustForInflation: true,
      );

      final yearsNoInf = finance.yearsToGoal(goalNoInflation, profile, purchases, assumptions);
      final yearsWithInf = finance.yearsToGoal(goalWithInflation, profile, purchases, assumptions);

      expect(yearsNoInf, isPositive);
      expect(yearsWithInf, isPositive);
      // With inflation adjustment, the target amount is higher, so it should take at least as long or longer
      expect(yearsWithInf, greaterThanOrEqualTo(yearsNoInf));
    });

    test('stepped salary hike logic', () {
      final profile = UserProfile(
        startingCtcLpa: 10.0,
        annualHikePct: 0.12,
        taxRegime: 'new',
        cityPreset: 'custom',
        monthlyRent: 0,
        monthlyFood: 0,
        monthlyTransport: 0,
        monthlyMisc: 0,
        sipRatePct: 0.20,
        onboardingComplete: true,
        hikeBracketsRaw: [
          {'fromYear': 1, 'toYear': 3, 'hikePct': 0.20},
          {'fromYear': 4, 'toYear': 99, 'hikePct': 0.10},
        ],
      );

      // ctcAtYear(0) should be starting ctc = 10.0
      expect(finance.ctcAtYear(profile, 0), equals(10.0));
      // ctcAtYear(1) should be 10.0 * 1.20 = 12.0
      expect(finance.ctcAtYear(profile, 1), closeTo(12.0, 0.001));
      // ctcAtYear(2) should be 12.0 * 1.20 = 14.4
      expect(finance.ctcAtYear(profile, 2), closeTo(14.4, 0.001));
      // ctcAtYear(3) should be 14.4 * 1.20 = 17.28
      expect(finance.ctcAtYear(profile, 3), closeTo(17.28, 0.001));
      // ctcAtYear(4) should be 17.28 * 1.10 = 19.008
      expect(finance.ctcAtYear(profile, 4), closeTo(19.008, 0.001));
    });

    test('multiple income sources total income', () {
      final sources = [
        IncomeSource(id: 's1', label: 'Freelance', monthlyAmount: 20000, annualGrowthPct: 0.10),
        IncomeSource(id: 's2', label: 'Rent', monthlyAmount: 10000, annualGrowthPct: 0.05),
      ];

      // At year 0, additional income is monthlyAmount sum = 30000
      expect(finance.additionalMonthlyIncome(sources, 0), equals(30000));

      // At year 1, first year is grown by 0% (amountAtYear(1) = monthlyAmount)
      expect(finance.additionalMonthlyIncome(sources, 1), equals(30000));

      // At year 2, grown by 1 year: 20000 * 1.10 + 10000 * 1.05 = 22000 + 10500 = 32500
      expect(finance.additionalMonthlyIncome(sources, 2), equals(32500));
    });

    test('emergency fund months coverage', () {
      final profile = UserProfile(
        startingCtcLpa: 10.0,
        annualHikePct: 0.10,
        taxRegime: 'new',
        cityPreset: 'custom',
        monthlyRent: 15000,
        monthlyFood: 10000,
        monthlyTransport: 5000,
        monthlyMisc: 10000, // Total monthly expenses = 40000
        sipRatePct: 0.20,
        onboardingComplete: true,
        emergencyFundBalance: 120000,
      );

      // Months covered = 120000 / 40000 = 3.0
      expect(finance.emergencyFundMonths(profile), equals(3.0));
    });
  });
}
