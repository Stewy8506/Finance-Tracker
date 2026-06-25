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
import 'models/sip_restore.dart';

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

/// Computes CTC using stepped hike brackets after [hikes] number of hikes.
/// hikes = 0 -> starting CTC (Rate during Year 1)
/// hikes = 1 -> CTC after first hike (Rate during Year 2)
double ctcAtYear(UserProfile profile, int hikes) {
  double ctc = profile.startingCtcLpa;
  for (int y = 1; y <= hikes; y++) {
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

// (totalMonthlyIncome removed)

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

/// Monthly expenses after [inflations] number of years of inflation.
/// inflations = 0 -> current expenses (Rate during Year 1)
/// inflations = 1 -> expenses after 1 year of inflation (Rate during Year 2)
double getMonthlyExpenses(UserProfile profile, int inflations, double inflationRate) {
  final base = _baseMonthlyExpenses(profile);
  return base * math.pow(1 + inflationRate, inflations);
}

// ─────────────────────────────────────────────────────────────────────────────
// PURCHASES
// ─────────────────────────────────────────────────────────────────────────────

/// Total discretionary spend in [year] across all recurring purchases.
double annualPurchaseSpend(List<RecurringPurchase> purchases, int year) {
  double total = 0;
  for (final p in purchases) {
    if (year < p.firstYear) continue;

    final startYear = p.firstYear;
    
    if (p.emiMonths != null && p.emiMonths! > 0) {
      final emiMonths = p.emiMonths!;
      final r = (p.emiInterestRate ?? 0) / 12;
      final emiAmount = _calculateEmi(p.amount, r, emiMonths);
      
      final startMonth = p.targetMonth ?? 0;
      
      if (p.recurEveryNYears == null) {
        total += _monthsInYearForEmi(year, startYear, startMonth, emiMonths) * emiAmount;
      } else {
        for (int instanceYear = startYear; instanceYear <= year; instanceYear += p.recurEveryNYears!) {
          total += _monthsInYearForEmi(year, instanceYear, startMonth, emiMonths) * emiAmount;
        }
      }
    } else {
      if (p.recurEveryNYears == null) {
        if (year == p.firstYear) total += p.amount;
      } else {
        final elapsed = year - p.firstYear;
        if (elapsed >= 0 && elapsed % p.recurEveryNYears! == 0) {
          total += p.amount;
        }
      }
    }
  }
  return total;
}

double _calculateEmi(double principal, double monthlyRate, int months) {
  if (monthlyRate == 0) return principal / months;
  final factor = math.pow(1 + monthlyRate, months);
  return principal * monthlyRate * factor / (factor - 1);
}

int _monthsInYearForEmi(int currentYear, int emiStartYear, int startMonth, int totalEmiMonths) {
  if (currentYear < emiStartYear) return 0;
  final yearStartMonthIndex = (currentYear - emiStartYear) * 12;
  final emiEndMonthIndex = startMonth + totalEmiMonths - 1;
  final overlapStart = math.max(yearStartMonthIndex, startMonth);
  final overlapEnd = math.min(yearStartMonthIndex + 11, emiEndMonthIndex);
  
  if (overlapStart <= overlapEnd) {
    return (overlapEnd - overlapStart + 1).toInt();
  }
  return 0;
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
// PROJECTION ENGINE
// ─────────────────────────────────────────────────────────────────────────────

int _priorityScore(String p) {
  if (p == 'high') return 3;
  if (p == 'medium') return 2;
  return 1;
}

/// Computes the full financial projection and actively deducts funded goals from the corpus.
/// Uses Option B + Option C:
/// - Goals are funded in targetYear order (if multiple, Priority decides).
/// - If short, goal waits (delayed gratification) without going into negative debt.
List<YearProjection> generateProjection(
  UserProfile profile,
  List<Goal> goals,
  List<RecurringPurchase> purchases,
  Assumptions assumptions, {
  List<IncomeSource> incomeSources = const [],
  int maxYears = 30,
  List<SipRestore> sipRestores = const [],
}) {
  final projections = <YearProjection>[];
  final fundedGoals = <String>{};
  
  double cashCorpus = 0;
  double sipCorpus = 0;

  // Sort goals by targetYear ascending, then priority descending
  final sortedGoals = List<Goal>.from(goals)
    ..sort((a, b) {
      if (a.targetYear != b.targetYear) return a.targetYear.compareTo(b.targetYear);
      return _priorityScore(b.priority).compareTo(_priorityScore(a.priority));
    });

  for (int y = 0; y <= maxYears; y++) {
    if (y == 0) {
      projections.add(YearProjection(
        year: 0,
        ctcLpa: profile.startingCtcLpa,
        takeHomeMonthly: calculateTakeHome(profile.startingCtcLpa, profile.taxRegime),
        sipMonthly: 0,
        techSpendAnnual: 0,
        corpus: 0,
        goalsFunded: [],
        fundedGoalIds: [],
        expensesMonthly: getMonthlyExpenses(profile, 0, assumptions.expenseInflation),
        freeCashMonthly: 0,
        additionalIncome: 0,
        totalIncome: 0,
      ));
      continue;
    }

    final int rateIndex = y - 1;
    final ctcThisYear = ctcAtYear(profile, rateIndex);
    final salaryTakeHome = calculateTakeHome(ctcThisYear, profile.taxRegime);
    final extraIncome = additionalMonthlyIncome(incomeSources, y);
    final totalIncome = salaryTakeHome + extraIncome;

    double effectiveSipRate = profile.sipRatePct;
    for (final restore in sipRestores) {
      if (y >= restore.restoreYear) {
        effectiveSipRate = math.max(effectiveSipRate, restore.originalSipPct);
      }
    }

    final sipMonthly = totalIncome * effectiveSipRate;
    final expenses = getMonthlyExpenses(profile, rateIndex, assumptions.expenseInflation);
    final freeCash = totalIncome - expenses - sipMonthly;
    final discSpend = annualPurchaseSpend(purchases, y);

    // 1. Grow existing corpus
    cashCorpus *= (1 + assumptions.cashSavingsRate);
    sipCorpus *= (1 + assumptions.sipReturnRate);

    // 2. Add new cash
    final sipThisYear = sipFutureValue(sipMonthly, 12, assumptions.sipReturnRate);
    sipCorpus += sipThisYear;

    final annualFreeCash = (freeCash * 12) - discSpend;
    double cashFlowDeficit = 0;
    
    if (annualFreeCash > 0) {
      cashCorpus += annualFreeCash;
    } else if (annualFreeCash < 0) {
      cashFlowDeficit = -annualFreeCash;
    }

    // 3. Fund goals
    final newlyFundedNames = <String>[];
    final newlyFundedIds = <String>[];
    
    for (final goal in sortedGoals) {
      if (fundedGoals.contains(goal.id)) continue;
      
      // Goal is eligible if we reached its targetYear (or we are past it and it was delayed)
      if (y >= goal.targetYear) {
        final target = goal.adjustForInflation == true
            ? goal.targetAmount * math.pow(1 + assumptions.expenseInflation, y)
            : goal.targetAmount;
            
        final totalCorpus = cashCorpus + sipCorpus;
        
        if (totalCorpus >= target) {
          // Fund it! Deduct from corpus
          if (cashCorpus >= target) {
            cashCorpus -= target;
          } else {
            final remaining = target - cashCorpus;
            cashCorpus = 0;
            sipCorpus -= remaining;
          }
          
          fundedGoals.add(goal.id);
          newlyFundedNames.add(goal.name);
          newlyFundedIds.add(goal.id);
        }
      }
    }

    final currentCorpus = cashCorpus + sipCorpus;

    projections.add(YearProjection(
      year: y,
      ctcLpa: ctcThisYear,
      takeHomeMonthly: salaryTakeHome,
      sipMonthly: sipMonthly,
      techSpendAnnual: discSpend,
      corpus: currentCorpus,
      goalsFunded: newlyFundedNames,
      fundedGoalIds: newlyFundedIds,
      expensesMonthly: expenses,
      freeCashMonthly: freeCash,
      additionalIncome: extraIncome,
      totalIncome: totalIncome,
      cashFlowDeficit: cashFlowDeficit,
    ));
  }

  return projections;
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

/// Kept for backward compatibility, but runs a global simulation 
/// internally to find when a specific goal is funded.
int yearsToGoal(
  Goal goal,
  UserProfile profile,
  List<Goal> allGoals,
  List<RecurringPurchase> purchases,
  Assumptions assumptions, {
  List<IncomeSource> incomeSources = const [],
}) {
  final projections = generateProjection(
    profile,
    allGoals,
    purchases,
    assumptions,
    incomeSources: incomeSources,
    maxYears: 30,
  );
  
  for (final p in projections) {
    if (p.fundedGoalIds.contains(goal.id)) {
      return p.year;
    }
  }
  return 0;
}

/// Computes a unified financial health score from 0 to 100 based on weighted factors.
int financialHealthScore(
  UserProfile profile,
  Assumptions assumptions,
  List<Goal> goals,
  List<RecurringPurchase> purchases,
  List<IncomeSource> incomeSources,
  List<YearProjection> projections,
) {
  if (projections.isEmpty) return 0;

  final year1 = projections.firstWhere((p) => p.year == 1, orElse: () => projections.first);
  final takeHome = year1.totalIncome > 0 ? year1.totalIncome : year1.takeHomeMonthly;
  final expenses = year1.expensesMonthly;

  // 1. SIP Rate (25pts)
  int sipPoints = 5;
  final sipPct = profile.sipRatePct * 100;
  if (sipPct >= 15) {
    sipPoints = 25;
  } else if (sipPct >= 10) {
    sipPoints = 15;
  }

  // 2. Emergency Fund (20pts)
  int efPoints = 5;
  final efMonths = emergencyFundMonths(profile);
  if (efMonths >= 6) {
    efPoints = 20;
  } else if (efMonths >= 3) {
    efPoints = 12;
  }

  // 3. Expense Ratio (20pts)
  int expPoints = 5;
  final expRatio = takeHome > 0 ? (expenses / takeHome) : 1.0;
  if (expRatio < 0.40) {
    expPoints = 20;
  } else if (expRatio <= 0.60) {
    expPoints = 12;
  }

  // 4. Goal Feasibility (20pts)
  int goalPoints = 20;
  if (goals.isNotEmpty) {
    int onTrackCount = 0;
    for (final g in goals) {
      int fundedYear = 0;
      for (final p in projections) {
        if (p.fundedGoalIds.contains(g.id)) {
          fundedYear = p.year;
          break;
        }
      }
      if (fundedYear > 0 && fundedYear <= g.targetYear) {
        onTrackCount++;
      }
    }
    final ratio = onTrackCount / goals.length;
    if (ratio == 1.0) {
      goalPoints = 20;
    } else if (ratio >= 0.5) {
      goalPoints = 10;
    } else {
      goalPoints = 5;
    }
  }

  // 5. Savings Growth (15pts)
  int growthPoints = 5;
  final ctcYear1 = year1.ctcLpa * 100000;
  final corpusYear10 = projections.firstWhere((p) => p.year == 10, orElse: () => projections.last).corpus;
  if (ctcYear1 > 0) {
    final multiple = corpusYear10 / ctcYear1;
    if (multiple >= 5.0) {
      growthPoints = 15;
    } else if (multiple >= 2.0) {
      growthPoints = 10;
    }
  }

  return sipPoints + efPoints + expPoints + goalPoints + growthPoints;
}

/// Sustainable monthly SWP from a given corpus, growing with inflation.
double swpMonthly(double corpus, double annualReturn, double inflation, int years) {
  if (corpus <= 0 || years <= 0) return 0;
  final monthlyReturn = annualReturn / 12;
  final monthlyInflation = inflation / 12;
  final n = years * 12;
  
  final rReal = (monthlyReturn - monthlyInflation) / (1 + monthlyInflation);
  if (rReal == 0) return corpus / n;
  
  return corpus * rReal / (1 - math.pow(1 + rReal, -n));
}

/// Compares how many years a corpus will last given a starting monthly withdrawal.
int corpusDepletionYear(double corpus, double monthlyWithdrawal, double returnRate, double inflationRate) {
  double remaining = corpus;
  double withdrawal = monthlyWithdrawal;
  
  for (int y = 1; y <= 50; y++) {
    if (y > 1) {
      withdrawal *= (1 + inflationRate);
    }
    for (int m = 1; m <= 12; m++) {
      remaining = remaining * (1 + returnRate / 12) - withdrawal;
      if (remaining <= 0) return y;
    }
  }
  return 99;
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

  // Verify generateProjection alignment
  final projections = generateProjection(testProfile, [], [], Assumptions.defaults());
  final year1 = projections.firstWhere((p) => p.year == 1);
  final expectedTakeHome = calculateTakeHome(testProfile.startingCtcLpa, testProfile.taxRegime);
  assert(
    (year1.takeHomeMonthly - expectedTakeHome).abs() < 1.0,
    'Year 1 take-home (${year1.takeHomeMonthly}) should exactly match current CTC take-home ($expectedTakeHome)',
  );
}
