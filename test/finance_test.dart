import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/finance.dart' as finance;
import 'package:ledger/models/goal.dart';
import 'package:ledger/models/user_profile.dart';
import 'package:ledger/models/recurring_purchase.dart';
import 'package:ledger/models/assumptions.dart';

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
  });
}
