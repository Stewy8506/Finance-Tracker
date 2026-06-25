/// Pure finance calculation functions — no Flutter dependencies.
/// All monetary values in Indian Rupees (₹).
library;

import 'dart:math' as math;

import 'models/user_profile.dart';
import 'models/goal.dart';
import 'models/recurring_purchase.dart';
import 'models/assumptions.dart';
import 'models/income_source.dart';
import 'models/year_projection.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TAX CALCULATION
// ─────────────────────────────────────────────────────────────────────────────

double _applySlabs(
    double income, List<List<double>> slabs, double topRate) {
  double tax = 0;
  double prev = 0;
  for (final slab in slabs) {
    final limit = slab[0];
    final rate = slab[1];
    if (income <= prev) break;
    final taxable = (income > limit ? limit : income) - prev;
    tax += taxable * rate;
    prev = limit;
  }
  if (income > prev) {
    tax += (income - prev) * topRate;
  }
  return tax;
}

double _calcSlabTax(double taxableIncome, String regime) {
  if (regime == 'new') {
    const slabs = [
      [400000.0, 0.0],
      [800000.0, 0.05],
      [1200000.0, 0.10],
      [1600000.0, 0.15],
      [2000000.0, 0.20],
      [2400000.0, 0.25],
    ];
    return _applySlabs(taxableIncome, slabs, 0.30);
  } else {
    const slabs = [
      [250000.0, 0.0],
      [500000.0, 0.05],
      [1000000.0, 0.20],
    ];
    return _applySlabs(taxableIncome, slabs, 0.30);
  }
}

/// Annual tax including cess, after 87A rebate.
double calculateAnnualTax(double ctcLpa, String regime) {
  final ctc = ctcLpa * 100000;
  final basic = ctc * 0.40;
  final pfEmployee = basic * 0.12;
  final stdDeduction = regime == 'new' ? 75000.0 : 50000.0;
  final taxableIncome = math.max(0.0, ctc - pfEmployee - stdDeduction);

  double tax = _calcSlabTax(taxableIncome, regime);

  // Section 87A rebate
  if (regime == 'new' && taxableIncome <= 1200000) {
    tax = 0;
  } else if (regime == 'old' && taxableIncome <= 500000) {
    tax = 0;
  }

  return tax * 1.04; // 4% health & education cess
}

/// Monthly take-home = (CTC - PF employee - Tax - Cess) / 12
double calculateTakeHome(double ctcLpa, String regime) {
  final ctc = ctcLpa * 100000;
  final basic = ctc * 0.40;
  final pfEmployee = basic * 0.12;
  final annualTax = calculateAnnualTax(ctcLpa, regime);
  return (ctc - pfEmployee - annualTax) / 12;
}

// ─────────────────────────────────────────────────────────────────────────────
// STEPPED SALARY HIKES
// ─────────────────────────────────────────────────────────────────────────────

/// Computes CTC at a given year using stepped hike brackets.
/// Year 0 = starting CTC, year 1 = first hike applied, etc.
double ctcAtYear(UserProfile profile, int year) {
  double ctc = profile.startingCtcLpa;
  for (int y = 1; y <= year; y++) {
    ctc *= (1 + profile.hikeRateForYear(y));
  }
  return ctc;
}

// ─────────────────────────────────────────────────────────────────────────────
// MULTIPLE INCOME SOURCES
// ─────────────────────────────────────────────────────────────────────────────

/// Total additional monthly income at a given year from all extra sources.
double additionalMonthlyIncome(List<IncomeSource> sources, int year) {
  double total = 0;
  for (final s in sources) {
    total += s.amountAtYear(year);
  }
  return total;
}

/// Total monthly income (salary take-home + additional sources) at a given year.
double totalMonthlyIncome(
  UserProfile profile,
  List<IncomeSource> incomeSources,
  int year,
) {
  final ctc = ctcAtYear(profile, year);
  final salaryTakeHome = calculateTakeHome(ctc, profile.taxRegime);
  return salaryTakeHome + additionalMonthlyIncome(incomeSources, year);
}

// ─────────────────────────────────────────────────────────────────────────────
// EMERGENCY FUND
// ─────────────────────────────────────────────────────────────────────────────

/// Emergency fund coverage in months of current expenses.
double emergencyFundMonths(UserProfile profile) {
  final monthlyExpenses = _baseMonthlyExpenses(profile);
  if (monthlyExpenses <= 0) return 0;
  return (profile.emergencyFundBalance ?? 0) / monthlyExpenses;
}

// ─────────────────────────────────────────────────────────────────────────────
// SIP
// ─────────────────────────────────────────────────────────────────────────────

/// SIP Future Value: P * ((1+r)^n - 1) / r * (1+r)
double sipFutureValue(double monthlyAmount, int months, double annualRate) {
  if (monthlyAmount <= 0 || months <= 0) return 0;
  final r = annualRate / 12;
  return monthlyAmount *
      (math.pow(1 + r, months) - 1) /
      r *
      (1 + r);
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPENSES
// ─────────────────────────────────────────────────────────────────────────────

double _baseMonthlyExpenses(UserProfile profile) =>
    profile.monthlyRent +
    profile.monthlyFood +
    profile.monthlyTransport +
    profile.monthlyMisc;

/// Monthly expenses at a given year (inflated).
double getMonthlyExpenses(UserProfile profile, int year, double inflation) {
  final base = _baseMonthlyExpenses(profile);
  return base * math.pow(1 + inflation, year);
}

// ─────────────────────────────────────────────────────────────────────────────
// PURCHASES
// ─────────────────────────────────────────────────────────────────────────────

/// Total discretionary spend in [year] across all recurring purchases.
double annualPurchaseSpend(List<RecurringPurchase> purchases, int year) {
  double total = 0;
  for (final p in purchases) {
    if (year < p.firstYear) continue;
    if (p.recurEveryNYears == null) {
      if (year == p.firstYear) total += p.amount;
    } else {
      final elapsed = year - p.firstYear;
      if (elapsed >= 0 && elapsed % p.recurEveryNYears! == 0) {
        total += p.amount;
      }
    }
  }
  return total;
}

/// Total spend across [horizonYears] for a single purchase (for UI preview).
double totalSpendOverYears(RecurringPurchase p, int horizonYears) {
  double total = 0;
  for (int y = 1; y <= horizonYears; y++) {
    if (y < p.firstYear) continue;
    if (p.recurEveryNYears == null) {
      if (y == p.firstYear) total += p.amount;
    } else {
      final elapsed = y - p.firstYear;
      if (elapsed >= 0 && elapsed % p.recurEveryNYears! == 0) {
        total += p.amount;
      }
    }
  }
  return total;
}

// ─────────────────────────────────────────────────────────────────────────────
// CORPUS
// ─────────────────────────────────────────────────────────────────────────────

/// Cumulative corpus at end of [targetYear].
/// Now uses stepped hike brackets and additional income sources.
double corpusAtYear(
  int targetYear,
  UserProfile profile,
  List<RecurringPurchase> purchases,
  Assumptions assumptions, {
  List<IncomeSource> incomeSources = const [],
}) {
  double sipCorpus = 0;
  double cashCorpus = 0;

  for (int y = 1; y <= targetYear; y++) {
    final ctcThisYear = ctcAtYear(profile, y - 1);
    final salaryTakeHome = calculateTakeHome(ctcThisYear, profile.taxRegime);
    final extraIncome = additionalMonthlyIncome(incomeSources, y);
    final totalIncome = salaryTakeHome + extraIncome;

    final expenses =
        getMonthlyExpenses(profile, y - 1, assumptions.expenseInflation);
    final sipMonthly = totalIncome * profile.sipRatePct;
    final freeCash = totalIncome - expenses - sipMonthly;
    final discretionary = annualPurchaseSpend(purchases, y);

    // SIP invested this year, compounded for remaining years
    final monthsRemaining = (targetYear - y) * 12;
    final sipThisYear = sipFutureValue(sipMonthly, 12, assumptions.sipReturnRate);
    sipCorpus +=
        sipThisYear * math.pow(1 + assumptions.sipReturnRate / 12, monthsRemaining);

    // Cash savings
    final annualFreeCash = (freeCash * 12) - discretionary;
    if (annualFreeCash > 0) {
      cashCorpus += annualFreeCash *
          math.pow(1 + assumptions.cashSavingsRate, targetYear - y);
    }
  }

  return sipCorpus + cashCorpus;
}

/// Year corpus first crosses goal.targetAmount (0 if never within 30 years).
int yearsToGoal(
  Goal goal,
  UserProfile profile,
  List<RecurringPurchase> purchases,
  Assumptions assumptions, {
  List<IncomeSource> incomeSources = const [],
}) {
  for (int y = 1; y <= 30; y++) {
    final corpus = corpusAtYear(y, profile, purchases, assumptions,
        incomeSources: incomeSources);
    final target = goal.adjustForInflation == true
        ? goal.targetAmount * math.pow(1 + assumptions.expenseInflation, y)
        : goal.targetAmount;
    if (corpus >= target) return y;
  }
  return 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// EMI
// ─────────────────────────────────────────────────────────────────────────────

/// Standard EMI: P * r * (1+r)^n / ((1+r)^n - 1)
double monthlyEmi(double loanAmount, double annualRate, int tenureYears) {
  if (loanAmount <= 0) return 0;
  final r = annualRate / 12;
  final n = tenureYears * 12;
  if (r == 0) return loanAmount / n;
  final factor = math.pow(1 + r, n);
  return loanAmount * r * factor / (factor - 1);
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL PROJECTION
// ─────────────────────────────────────────────────────────────────────────────

List<YearProjection> generateProjection(
  UserProfile profile,
  List<Goal> goals,
  List<RecurringPurchase> purchases,
  Assumptions assumptions, {
  List<IncomeSource> incomeSources = const [],
}) {
  final projections = <YearProjection>[];
  final fundedGoals = <String>{};

  for (int y = 0; y <= 20; y++) {
    final ctcThisYear = ctcAtYear(profile, y);
    final salaryTakeHome = calculateTakeHome(ctcThisYear, profile.taxRegime);
    final extraIncome = additionalMonthlyIncome(incomeSources, y);
    final totalIncome = salaryTakeHome + extraIncome;

    final sipMonthly = totalIncome * profile.sipRatePct;
    final expenses =
        getMonthlyExpenses(profile, y, assumptions.expenseInflation);
    final freeCash = totalIncome - expenses - sipMonthly;
    final techSpend = annualPurchaseSpend(purchases, y);
    final corpus = y == 0
        ? 0.0
        : corpusAtYear(y, profile, purchases, assumptions,
            incomeSources: incomeSources);

    final newlyFunded = <String>[];
    for (final goal in goals) {
      final target = goal.adjustForInflation == true
          ? goal.targetAmount * math.pow(1 + assumptions.expenseInflation, y)
          : goal.targetAmount;
      if (!fundedGoals.contains(goal.id) && corpus >= target) {
        fundedGoals.add(goal.id);
        newlyFunded.add(goal.name);
      }
    }

    projections.add(YearProjection(
      year: y,
      ctcLpa: ctcThisYear,
      takeHomeMonthly: salaryTakeHome,
      sipMonthly: sipMonthly,
      techSpendAnnual: techSpend,
      corpus: corpus,
      goalsFunded: newlyFunded,
      expensesMonthly: expenses,
      freeCashMonthly: freeCash,
      additionalIncome: extraIncome,
      totalIncome: totalIncome,
    ));
  }

  return projections;
}

// ─────────────────────────────────────────────────────────────────────────────
// VERIFICATION ASSERTIONS (run in debug mode only)
// ─────────────────────────────────────────────────────────────────────────────

void verifyFinanceEngine() {
  // Tax: ₹10L CTC, new regime → under 87A rebate → ₹0 tax
  final tax10L = calculateAnnualTax(10.0, 'new');
  assert(tax10L == 0, 'Expected ₹0 tax for ₹10L CTC (new regime), got $tax10L');

  // SIP: ₹10K/mo at 12% for 10yr ≈ ₹23.2L
  final sipFv = sipFutureValue(10000, 120, 0.12);
  assert(sipFv > 2300000 && sipFv < 2400000,
      'Expected ~₹23.2L SIP FV, got $sipFv');

  // EMI: ₹1Cr at 8.5% for 20yr ≈ ₹86,849
  final emi = monthlyEmi(10000000, 0.085, 20);
  assert(emi > 86000 && emi < 88000, 'Expected ~₹86849 EMI, got $emi');

  // Stepped hike: verify ctcAtYear uses brackets
  final testProfile = UserProfile(
    startingCtcLpa: 10.0,
    annualHikePct: 0.12,
    taxRegime: 'new',
    cityPreset: 'custom',
    monthlyRent: 0,
    monthlyFood: 8000,
    monthlyTransport: 3000,
    monthlyMisc: 5000,
    sipRatePct: 0.15,
    onboardingComplete: true,
    hikeBracketsRaw: [
      {'fromYear': 1, 'toYear': 3, 'hikePct': 0.20},
      {'fromYear': 4, 'toYear': 99, 'hikePct': 0.10},
    ],
  );
  // Year 0 = 10 LPA, Year 1 = 10 * 1.20 = 12 LPA
  final ctcY1 = ctcAtYear(testProfile, 1);
  assert(ctcY1 > 11.9 && ctcY1 < 12.1,
      'Expected ~12 LPA at year 1 with 20% bracket, got $ctcY1');
}
