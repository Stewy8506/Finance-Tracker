import 'dart:math' as math;

import 'models/user_profile.dart';
import 'models/goal.dart';
import 'models/recurring_purchase.dart';
import 'models/assumptions.dart';
import 'models/income_source.dart';
import 'models/year_projection.dart';
import 'models/suggestion.dart';
import 'models/sip_restore.dart';
import 'models/simulation_result.dart';
import 'finance.dart' as finance;

/// Helper to calculate EMI monthly payments
double _calculateEmi(double principal, double monthlyRate, int months) {
  if (monthlyRate == 0) return principal / months;
  final factor = math.pow(1 + monthlyRate, months);
  return principal * monthlyRate * factor / (factor - 1);
}

/// SIP Future Value: P * ((1+r)^n - 1) / r * (1+r)
double _sipFutureValue(double monthlyAmount, int months, double annualRate) {
  if (monthlyAmount <= 0 || months <= 0) return 0;
  final r = annualRate / 12;
  return monthlyAmount *
      (math.pow(1 + r, months) - 1) /
      r *
      (1 + r);
}

/// Generates a monthly spend breakdown (12-element list) for a given year.
List<double> monthlySpendBreakdown(List<RecurringPurchase> purchases, int year) {
  final monthlySpend = List<double>.filled(12, 0.0);

  for (final p in purchases) {
    if (year < p.firstYear) continue;

    final startYear = p.firstYear;
    final startMonth = p.targetMonth ?? 0;

    if (p.emiMonths != null && p.emiMonths! > 0) {
      final emiMonths = p.emiMonths!;
      final r = (p.emiInterestRate ?? 0) / 12;
      final emiAmount = _calculateEmi(p.amount, r, emiMonths);

      if (p.recurEveryNYears == null) {
        _addEmiToMonths(monthlySpend, year, startYear, startMonth, emiMonths, emiAmount);
      } else {
        for (int instanceYear = startYear;
            instanceYear <= year;
            instanceYear += p.recurEveryNYears!) {
          _addEmiToMonths(monthlySpend, year, instanceYear, startMonth, emiMonths, emiAmount);
        }
      }
    } else {
      if (p.recurEveryNYears == null) {
        if (year == p.firstYear) {
          monthlySpend[startMonth] += p.amount;
        }
      } else {
        final elapsed = year - p.firstYear;
        if (elapsed >= 0 && elapsed % p.recurEveryNYears! == 0) {
          monthlySpend[startMonth] += p.amount;
        }
      }
    }
  }

  return monthlySpend;
}

void _addEmiToMonths(
    List<double> monthlySpend,
    int currentYear,
    int emiStartYear,
    int startMonth,
    int totalEmiMonths,
    double emiAmount) {
  if (currentYear < emiStartYear) return;

  final yearStartMonthIndex = (currentYear - emiStartYear) * 12;
  final emiEndMonthIndex = startMonth + totalEmiMonths - 1;

  for (int month = 0; month < 12; month++) {
    final absMonthIndex = yearStartMonthIndex + month;
    if (absMonthIndex >= startMonth && absMonthIndex <= emiEndMonthIndex) {
      monthlySpend[month] += emiAmount;
    }
  }
}

/// Month name list for user-friendly descriptions
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

/// Formats currency values in Lakhs (L) or thousands (K)
String _formatCurrency(double amount) {
  if (amount >= 100000) {
    return '₹${(amount / 100000).toStringAsFixed(1)}L';
  } else if (amount >= 1000) {
    return '₹${(amount / 1000).toStringAsFixed(0)}K';
  } else {
    return '₹${amount.toStringAsFixed(0)}';
  }
}

/// Safely clones a purchase and applies a suggestion's fields
RecurringPurchase cloneAndApplySuggestion(RecurringPurchase p, Suggestion s) {
  final copy = RecurringPurchase(
    id: p.id,
    name: p.name,
    amount: p.amount,
    firstYear: s.suggestedFirstYear ?? p.firstYear,
    recurEveryNYears: p.recurEveryNYears,
    category: p.category,
    note: p.note,
    targetMonth: s.suggestedTargetMonth ?? p.targetMonth,
    emiMonths: p.emiMonths,
    emiInterestRate: p.emiInterestRate,
  );
  if (s.suggestedEmiMonths != null) {
    if (s.suggestedEmiMonths == 0) {
      copy.emiMonths = null;
      copy.emiInterestRate = null;
    } else {
      copy.emiMonths = s.suggestedEmiMonths;
      copy.emiInterestRate = s.suggestedEmiRate ?? p.emiInterestRate;
    }
  }
  return copy;
}

/// Generates ranked financial optimization suggestions
List<Suggestion> generateSuggestions({
  required UserProfile profile,
  required List<RecurringPurchase> purchases,
  required List<Goal> goals,
  required Assumptions assumptions,
  required List<IncomeSource> incomeSources,
  required List<YearProjection> projections,
}) {
  final suggestions = <Suggestion>[];

  // 1. 🔴 Deficit Resolver
  suggestions.addAll(_analyzeDeficits(projections, purchases));

  // 2. 📅 Monthly Clustering Detector (multi-year upgrade)
  suggestions.addAll(_analyzeMonthlyClustering(purchases));

  // 3. 💸 EMI Optimization
  suggestions.addAll(_analyzeEmiOptimization(projections, purchases));

  // 4. 📈 Income-Timing Optimizer (multi-year upgrade)
  suggestions.addAll(_analyzeIncomeTiming(projections, purchases));

  // 5. 🏔️ Spending Spike Detector
  suggestions.addAll(_analyzeSpendingSpikes(purchases));

  // 6. 🎯 Goal Conflict Detector
  suggestions.addAll(_analyzeGoalConflicts(goals, purchases));

  // 8. 📊 Opportunity Cost Calculator (new analyzer #8)
  suggestions.addAll(_analyzeOpportunityCost(profile, purchases, assumptions));

  // 9. 🚫 Skip & Invest Advisor (new analyzer #9)
  suggestions.addAll(_analyzeSkipAndInvest(projections, purchases, assumptions));

  // 10. 💰 SIP Flex Advisor (new analyzer #10)
  suggestions.addAll(_analyzeSipFlex(profile, projections, assumptions));

  // 7. 🧠 Combo Suggestion Solver (new analyzer #7, run on raw suggestions before dedup)
  final comboSuggestions = _analyzeComboSolutions(projections, purchases, suggestions);
  suggestions.addAll(comboSuggestions);

  // Rank, deduplicate per purchase, and cap at 8
  return _rankAndDeduplicate(suggestions);
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Deficit Resolver
// ─────────────────────────────────────────────────────────────────────────────
List<Suggestion> _analyzeDeficits(
  List<YearProjection> projections,
  List<RecurringPurchase> purchases,
) {
  final list = <Suggestion>[];

  // Find the first year with a deficit (if any)
  YearProjection? deficitYearProj;
  for (final proj in projections) {
    if (proj.year > 0 && proj.cashFlowDeficit > 0) {
      deficitYearProj = proj;
      break;
    }
  }

  if (deficitYearProj == null) return list;

  final deficitYear = deficitYearProj.year;
  final deficitAmount = deficitYearProj.cashFlowDeficit;

  // Find purchases happening or active in that year
  for (final p in purchases) {
    // Check if the purchase has any spend in the deficit year
    final spendInYear = _getPurchaseSpendInYear(p, deficitYear);
    if (spendInYear <= 0) continue;

    // Suggestion A: Convert cash to EMI
    if (p.emiMonths == null || p.emiMonths == 0) {
      // Convert to 12 months EMI at 12% default rate
      const suggestedMonths = 12;
      const suggestedRate = 0.12;
      final emiAmount = _calculateEmi(p.amount, suggestedRate / 12, suggestedMonths);
      final newSpendInDeficitYear = _getEmiSpendInYear(
        p.amount,
        suggestedRate,
        suggestedMonths,
        p.firstYear,
        p.targetMonth ?? 0,
        deficitYear,
        p.recurEveryNYears,
      );

      final cashFlowImprovement = spendInYear - newSpendInDeficitYear;
      if (cashFlowImprovement > 0) {
        list.add(Suggestion(
          purchaseId: p.id,
          purchaseName: p.name,
          type: SuggestionType.convertToEmi,
          title: 'Convert ${p.name} to EMI',
          description: 'Convert this cash purchase to a 12-month EMI (assumed 12% interest) to resolve the Year $deficitYear deficit.',
          impact: 'Frees up ${_formatCurrency(cashFlowImprovement)} in Year $deficitYear (₹${_formatCurrency(emiAmount)}/mo)',
          impactScore: _calculateScore(
            cashFlowImprovement: cashFlowImprovement,
            urgency: 100,
            simplicity: 50,
            interestSavings: 0,
            denominator: deficitAmount,
          ),
          targetYear: deficitYear,
          suggestedEmiMonths: suggestedMonths,
          suggestedEmiRate: suggestedRate,
        ));
      }

      // Suggestion B: Delay purchase by 1 year
      final delayedYear = p.firstYear + 1;
      final delayedImprovement = spendInYear; // We completely remove spend from this year
      list.add(Suggestion(
        purchaseId: p.id,
        purchaseName: p.name,
        type: SuggestionType.delayPurchase,
        title: 'Delay ${p.name} to Year $delayedYear',
        description: 'Postpone this purchase by 1 year to avoid the cash flow deficit in Year $deficitYear.',
        impact: 'Saves ${_formatCurrency(delayedImprovement)} in Year $deficitYear',
        impactScore: _calculateScore(
          cashFlowImprovement: delayedImprovement,
          urgency: 100,
          simplicity: 100,
          interestSavings: 0,
          denominator: deficitAmount,
        ),
        targetYear: deficitYear,
        suggestedFirstYear: delayedYear,
      ));
    } else {
      // Suggestion C: Extend existing EMI duration (try 24 or 36)
      final currentMonths = p.emiMonths!;
      if (currentMonths < 36) {
        final newMonths = currentMonths <= 12 ? 24 : 36;
        final currentRate = p.emiInterestRate ?? 0.12;

        final oldEmi = _calculateEmi(p.amount, currentRate / 12, currentMonths);
        final newEmi = _calculateEmi(p.amount, currentRate / 12, newMonths);

        final oldSpend = _getEmiSpendInYear(
          p.amount,
          currentRate,
          currentMonths,
          p.firstYear,
          p.targetMonth ?? 0,
          deficitYear,
          p.recurEveryNYears,
        );
        final newSpend = _getEmiSpendInYear(
          p.amount,
          currentRate,
          newMonths,
          p.firstYear,
          p.targetMonth ?? 0,
          deficitYear,
          p.recurEveryNYears,
        );

        final cashFlowImprovement = oldSpend - newSpend;
        if (cashFlowImprovement > 0) {
          list.add(Suggestion(
            purchaseId: p.id,
            purchaseName: p.name,
            type: SuggestionType.extendEmi,
            title: 'Extend ${p.name} EMI to $newMonths months',
            description: 'Stretch EMI from $currentMonths to $newMonths months to reduce Year $deficitYear cash outflow.',
            impact: 'Frees up ${_formatCurrency(cashFlowImprovement)} in Year $deficitYear (drops payment by ₹${_formatCurrency(oldEmi - newEmi)}/mo)',
            impactScore: _calculateScore(
              cashFlowImprovement: cashFlowImprovement,
              urgency: 100,
              simplicity: 100,
              interestSavings: 0,
              denominator: deficitAmount,
            ),
            targetYear: deficitYear,
            suggestedEmiMonths: newMonths,
            suggestedEmiRate: currentRate,
          ));
        }
      }
    }
  }

  return list;
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Monthly Clustering Detector (multi-year loop upgraded)
// ─────────────────────────────────────────────────────────────────────────────
List<Suggestion> _analyzeMonthlyClustering(List<RecurringPurchase> purchases) {
  final list = <Suggestion>[];

  // Loop clustering analyzer over all years 1-10
  for (int targetYear = 1; targetYear <= 10; targetYear++) {
    final monthlySpend = monthlySpendBreakdown(purchases, targetYear);
    final monthlyCount = List<int>.filled(12, 0);
    final monthlyPurchases = List<List<RecurringPurchase>>.generate(12, (_) => []);

    for (final p in purchases) {
      if (p.firstYear == targetYear) {
        final month = p.targetMonth ?? 0;
        monthlyCount[month]++;
        monthlyPurchases[month].add(p);
      }
    }

    int maxMonth = -1;
    int maxCount = 0;
    for (int m = 0; m < 12; m++) {
      if (monthlyCount[m] > maxCount) {
        maxCount = monthlyCount[m];
        maxMonth = m;
      }
    }

    if (maxCount >= 2 && maxMonth != -1) {
      int emptiestMonth = 0;
      double minSpend = double.infinity;
      for (int m = 0; m < 12; m++) {
        if (monthlySpend[m] < minSpend) {
          minSpend = monthlySpend[m];
          emptiestMonth = m;
        }
      }

      final clustered = monthlyPurchases[maxMonth]..sort((a, b) => b.amount.compareTo(a.amount));
      if (clustered.isNotEmpty) {
        final p = clustered.first;
        final monthName = _monthNames[maxMonth];
        final emptiestMonthName = _monthNames[emptiestMonth];

        list.add(Suggestion(
          purchaseId: p.id,
          purchaseName: p.name,
          type: SuggestionType.spreadMonths,
          title: 'Spread out your $monthName purchases (Year $targetYear)',
          description: 'Move ${p.name} from $monthName to $emptiestMonthName in Year $targetYear. You already have other purchases planned in $monthName.',
          impact: 'Frees up ${_formatCurrency(p.amount)} in $monthName',
          impactScore: _calculateScore(
            cashFlowImprovement: p.amount,
            urgency: 40,
            simplicity: 100,
            interestSavings: 0,
          ),
          targetYear: targetYear,
          suggestedTargetMonth: emptiestMonth,
        ));
      }
    }
  }

  return list;
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. EMI Optimization
// ─────────────────────────────────────────────────────────────────────────────
List<Suggestion> _analyzeEmiOptimization(
  List<YearProjection> projections,
  List<RecurringPurchase> purchases,
) {
  final list = <Suggestion>[];

  for (final p in purchases) {
    if (p.emiMonths == null || p.emiMonths! <= 0) continue;

    final rate = p.emiInterestRate ?? 0.0;
    final emiMonths = p.emiMonths!;
    final emiAmount = _calculateEmi(p.amount, rate / 12, emiMonths);

    // Rule A: EMI monthly payment is > 40% of free cash (in the year it starts)
    final startYear = p.firstYear;
    if (startYear < projections.length) {
      final proj = projections[startYear];
      final freeCashBeforeEmi = proj.freeCashMonthly + emiAmount;

      if (freeCashBeforeEmi > 0 && emiAmount > 0.40 * freeCashBeforeEmi) {
        // Suggest stretching EMI
        if (emiMonths < 36) {
          final newMonths = emiMonths <= 12 ? 24 : 36;
          final newEmi = _calculateEmi(p.amount, rate / 12, newMonths);
          final diff = emiAmount - newEmi;

          list.add(Suggestion(
            purchaseId: p.id,
            purchaseName: p.name,
            type: SuggestionType.extendEmi,
            title: 'Stretch ${p.name} EMI to reduce burden',
            description: 'Your monthly EMI for ${p.name} consumes a large portion of your free cash. Stretch from $emiMonths to $newMonths months to lower the monthly payment.',
            impact: 'Frees up ${_formatCurrency(diff)}/month of cash flow',
            impactScore: _calculateScore(
              cashFlowImprovement: diff * 12,
              urgency: 20,
              simplicity: 100,
              interestSavings: 0,
            ),
            targetYear: startYear,
            suggestedEmiMonths: newMonths,
            suggestedEmiRate: rate,
          ));
        }
      }
    }

    // Rule B: High interest (> 15%) on small purchase (< ₹50,000)
    if (p.amount < 50000 && rate > 0.15) {
      final totalCost = emiAmount * emiMonths;
      final interestSaved = totalCost - p.amount;

      if (interestSaved > 0) {
        list.add(Suggestion(
          purchaseId: p.id,
          purchaseName: p.name,
          type: SuggestionType.reduceInterest,
          title: 'Pay cash for ${p.name} to save interest',
          description: 'This purchase has a high interest rate of ${(rate * 100).toStringAsFixed(0)}%. Pay in cash to save ${_formatCurrency(interestSaved)} in interest.',
          impact: 'Saves ${_formatCurrency(interestSaved)} in interest fees',
          impactScore: _calculateScore(
            cashFlowImprovement: 0,
            urgency: 20,
            simplicity: 100,
            interestSavings: interestSaved,
          ),
          targetYear: p.firstYear,
          suggestedEmiMonths: 0, // 0 or null represents cash
          suggestedEmiRate: 0.0,
        ));
      }
    }
  }

  // Rule C: Overlapping EMIs stagger detection
  for (int i = 0; i < purchases.length; i++) {
    for (int j = i + 1; j < purchases.length; j++) {
      final p1 = purchases[i];
      final p2 = purchases[j];

      if (p1.emiMonths != null &&
          p1.emiMonths! > 0 &&
          p2.emiMonths != null &&
          p2.emiMonths! > 0) {
        // Calculate absolute start/end month indexes relative to Year 1
        final start1 = (p1.firstYear - 1) * 12 + (p1.targetMonth ?? 0);
        final end1 = start1 + p1.emiMonths! - 1;

        final start2 = (p2.firstYear - 1) * 12 + (p2.targetMonth ?? 0);
        final end2 = start2 + p2.emiMonths! - 1;

        // Check if they overlap
        final overlapStart = math.max(start1, start2);
        final overlapEnd = math.min(end1, end2);

        if (overlapStart <= overlapEnd) {
          final overlapMonths = overlapEnd - overlapStart + 1;
          if (overlapMonths >= 3) {
            // Determine which to stagger (the later one, or if same start, the one with smaller amount)
            final targetPurchase = (start2 >= start1) ? p2 : p1;
            
            final targetStart = (targetPurchase.id == p2.id) ? start2 : start1;
            final newStart = targetStart + overlapMonths;
            final suggestedYear = (newStart ~/ 12) + 1;
            final suggestedMonth = newStart % 12;

            final emi1 = _calculateEmi(p1.amount, (p1.emiInterestRate ?? 0) / 12, p1.emiMonths!);
            final emi2 = _calculateEmi(p2.amount, (p2.emiInterestRate ?? 0) / 12, p2.emiMonths!);
            final combinedEmi = emi1 + emi2;

            list.add(Suggestion(
              purchaseId: targetPurchase.id,
              purchaseName: targetPurchase.name,
              type: SuggestionType.staggerEmis,
              title: 'Stagger EMIs for ${targetPurchase.name}',
              description: 'Your ${p1.name} and ${p2.name} EMIs overlap for $overlapMonths months. Delay ${targetPurchase.name} by $overlapMonths months to avoid a combined ₹${_formatCurrency(combinedEmi)}/mo drain.',
              impact: 'Staggers EMIs to save ₹${_formatCurrency(combinedEmi)}/mo peak outflow',
              impactScore: _calculateScore(
                cashFlowImprovement: combinedEmi * 12,
                urgency: 20,
                simplicity: 50,
                interestSavings: 0,
              ),
              targetYear: targetPurchase.firstYear,
              suggestedFirstYear: suggestedYear,
              suggestedTargetMonth: suggestedMonth,
            ));
          }
        }
      }
    }
  }

  return list;
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Income-Timing Optimizer (multi-year upgraded)
// ─────────────────────────────────────────────────────────────────────────────
List<Suggestion> _analyzeIncomeTiming(
  List<YearProjection> projections,
  List<RecurringPurchase> purchases,
) {
  final list = <Suggestion>[];

  // Compare each year Y (1-9) with Y+1
  for (int y = 1; y < projections.length - 1; y++) {
    final incomeY = projections[y].totalIncome;
    final incomeYNext = projections[y + 1].totalIncome;

    // Trigger: Year Y+1 monthly income is >= 15% higher than Year Y
    if (incomeY > 0 && incomeYNext >= 1.15 * incomeY) {
      final hikePct = ((incomeYNext - incomeY) / incomeY * 100).toStringAsFixed(0);
      final diff = incomeYNext - incomeY;

      for (final p in purchases) {
        // Trigger: Large purchase planned in Year Y
        if (p.firstYear == y && (p.amount > 100000 || p.amount > 2 * incomeY)) {
          list.add(Suggestion(
            purchaseId: p.id,
            purchaseName: p.name,
            type: SuggestionType.incomeAlign,
            title: 'Delay ${p.name} to match salary hike',
            description: 'Delay this purchase to Year ${y + 1}. Your monthly income grows by $hikePct% (+₹${_formatCurrency(diff)}/mo) in Year ${y + 1}, making this purchase much more affordable.',
            impact: 'Monthly income is ₹${_formatCurrency(diff)} higher in Year ${y + 1}',
            impactScore: _calculateScore(
              cashFlowImprovement: p.amount,
              urgency: 20,
              simplicity: 100,
              interestSavings: 0,
            ),
            targetYear: y,
            suggestedFirstYear: y + 1,
          ));
        }
      }
    }
  }

  return list;
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Spending Spike Detector
// ─────────────────────────────────────────────────────────────────────────────
List<Suggestion> _analyzeSpendingSpikes(List<RecurringPurchase> purchases) {
  final list = <Suggestion>[];

  // We analyze spikes from Year 2 up to Year 10
  const maxSearchYears = 10;
  final annualSpends = List<double>.filled(maxSearchYears + 2, 0.0);

  for (int y = 1; y <= maxSearchYears + 1; y++) {
    for (final p in purchases) {
      annualSpends[y] += _getPurchaseSpendInYear(p, y);
    }
  }

  for (int y = 2; y <= maxSearchYears; y++) {
    final spendY = annualSpends[y];
    final avgAdjacent = (annualSpends[y - 1] + annualSpends[y + 1]) / 2;

    // Trigger: Year y spend is > 200,000 AND > 2x the average of adjacent years
    if (spendY > 200000 && spendY > 2 * avgAdjacent) {
      // Find the largest purchase starting in that year to move to the next year
      RecurringPurchase? largestPurchase;
      double maxAmt = 0;

      for (final p in purchases) {
        if (p.firstYear == y) {
          if (p.amount > maxAmt) {
            maxAmt = p.amount;
            largestPurchase = p;
          }
        }
      }

      if (largestPurchase != null) {
        final nextYear = y + 1;
        list.add(Suggestion(
          purchaseId: largestPurchase.id,
          purchaseName: largestPurchase.name,
          type: SuggestionType.levelSpike,
          title: 'Smooth out spending spike in Year $y',
          description: 'Year $y has ₹${_formatCurrency(spendY)} in purchases vs a ₹${_formatCurrency(avgAdjacent)} average of adjacent years. Shift ${largestPurchase.name} to Year $nextYear.',
          impact: 'Reduces Year $y discretionary spend by ₹${_formatCurrency(largestPurchase.amount)}',
          impactScore: _calculateScore(
            cashFlowImprovement: largestPurchase.amount,
            urgency: 60,
            simplicity: 100,
            interestSavings: 0,
          ),
          targetYear: y,
          suggestedFirstYear: nextYear,
        ));
      }
    }
  }

  return list;
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Goal Conflict Detector
// ─────────────────────────────────────────────────────────────────────────────
List<Suggestion> _analyzeGoalConflicts(
  List<Goal> goals,
  List<RecurringPurchase> purchases,
) {
  final list = <Suggestion>[];

  for (final g in goals) {
    // Only triggers for high priority goals
    if (g.priority != 'high') continue;

    final targetYear = g.targetYear;

    for (final p in purchases) {
      // Large purchase (amount > ₹1,00,000) starting in the same year
      if (p.firstYear == targetYear && p.amount > 100000) {
        final delayedYear = targetYear + 1;

        list.add(Suggestion(
          purchaseId: p.id,
          purchaseName: p.name,
          type: SuggestionType.goalConflict,
          title: 'Resolve conflict with ${g.name} goal',
          description: 'Your ${p.name} purchase in Year $targetYear could delay funding your high-priority "${g.name}" goal. Delay the purchase to Year $delayedYear.',
          impact: 'Protects funding for ${g.name} (${_formatCurrency(g.targetAmount)})',
          impactScore: _calculateScore(
            cashFlowImprovement: p.amount,
            urgency: 60,
            simplicity: 100,
            interestSavings: 0,
          ),
          targetYear: targetYear,
          suggestedFirstYear: delayedYear,
        ));
      }
    }
  }

  return list;
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. Combo Suggestion Solver (new analyzer #7)
// ─────────────────────────────────────────────────────────────────────────────
List<Suggestion> _analyzeComboSolutions(
  List<YearProjection> projections,
  List<RecurringPurchase> purchases,
  List<Suggestion> rawSuggestions,
) {
  final list = <Suggestion>[];

  for (final proj in projections) {
    if (proj.year <= 0 || proj.cashFlowDeficit <= 0) continue;
    final deficitYear = proj.year;
    final deficitAmount = proj.cashFlowDeficit;

    final candidates = rawSuggestions.where((s) {
      if (s.targetYear != deficitYear) return false;
      if (s.type == SuggestionType.opportunityCost ||
          s.type == SuggestionType.skipAndInvest ||
          s.type == SuggestionType.reduceSip ||
          s.type == SuggestionType.combo) {
        return false;
      }
      return true;
    }).toList();

    if (candidates.length < 2) continue;

    Suggestion? bestA;
    Suggestion? bestB;
    double bestResolution = 0.0;
    double bestCashFlowImprovement = 0.0;

    for (int i = 0; i < candidates.length; i++) {
      for (int j = i + 1; j < candidates.length; j++) {
        final a = candidates[i];
        final b = candidates[j];
        if (a.purchaseId == b.purchaseId) continue;

        final pA = purchases.firstWhere((p) => p.id == a.purchaseId, orElse: () => purchases.first);
        final pB = purchases.firstWhere((p) => p.id == b.purchaseId, orElse: () => purchases.first);

        final originalSpendA = _getPurchaseSpendInYear(pA, deficitYear);
        final originalSpendB = _getPurchaseSpendInYear(pB, deficitYear);

        final modifiedPA = cloneAndApplySuggestion(pA, a);
        final modifiedPB = cloneAndApplySuggestion(pB, b);

        final simulatedSpendA = _getPurchaseSpendInYear(modifiedPA, deficitYear);
        final simulatedSpendB = _getPurchaseSpendInYear(modifiedPB, deficitYear);

        final improvementA = originalSpendA - simulatedSpendA;
        final improvementB = originalSpendB - simulatedSpendB;
        final totalImprovement = improvementA + improvementB;

        if (totalImprovement <= 0) continue;

        final resolution = math.min(1.0, totalImprovement / deficitAmount);
        if (resolution > bestResolution) {
          bestResolution = resolution;
          bestCashFlowImprovement = totalImprovement;
          bestA = a;
          bestB = b;
        }
      }
    }

    if (bestA != null && bestB != null) {
      double maxIndividualImprovement = 0.0;
      for (final s in candidates) {
        final p = purchases.firstWhere((p) => p.id == s.purchaseId, orElse: () => purchases.first);
        final originalSpend = _getPurchaseSpendInYear(p, deficitYear);
        final modifiedP = cloneAndApplySuggestion(p, s);
        final simulatedSpend = _getPurchaseSpendInYear(modifiedP, deficitYear);
        final improvement = originalSpend - simulatedSpend;
        if (improvement > maxIndividualImprovement) {
          maxIndividualImprovement = improvement;
        }
      }

      if (bestCashFlowImprovement > maxIndividualImprovement) {
        final comboTitle = bestResolution >= 1.0
            ? 'Fully resolve Year $deficitYear deficit'
            : 'Significantly reduce Year $deficitYear deficit';

        final String comboDesc;
        final String comboImpact;
        if (bestResolution >= 1.0) {
          comboDesc = 'Combine two actions to fully resolve the Year $deficitYear deficit of ${_formatCurrency(deficitAmount)}:\n1. ${bestA.title}\n2. ${bestB.title}';
          comboImpact = 'Fully resolves Year $deficitYear deficit (saves ${_formatCurrency(bestCashFlowImprovement)})';
        } else {
          final residual = deficitAmount - bestCashFlowImprovement;
          comboDesc = 'Combine two actions to significantly reduce the Year $deficitYear deficit of ${_formatCurrency(deficitAmount)}:\n1. ${bestA.title}\n2. ${bestB.title}';
          comboImpact = 'Reduces Year $deficitYear deficit by ${_formatCurrency(bestCashFlowImprovement)}, leaving ${_formatCurrency(residual)} unresolved';
        }

        list.add(Suggestion(
          purchaseId: '${bestA.purchaseId}+${bestB.purchaseId}',
          purchaseName: 'Combo Solution',
          type: SuggestionType.combo,
          title: comboTitle,
          description: comboDesc,
          impact: comboImpact,
          impactScore: _calculateScore(
            cashFlowImprovement: bestCashFlowImprovement,
            urgency: 100,
            simplicity: 50,
            interestSavings: 0,
            denominator: deficitAmount,
          ),
          targetYear: deficitYear,
          comboChildren: [bestA, bestB],
        ));
      }
    }
  }

  return list;
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. Opportunity Cost Calculator (new analyzer #8)
// ─────────────────────────────────────────────────────────────────────────────
List<Suggestion> _analyzeOpportunityCost(
  UserProfile profile,
  List<RecurringPurchase> purchases,
  Assumptions assumptions,
) {
  final list = <Suggestion>[];
  if (profile.showOpportunityCost == false) return list;

  final candidates = purchases.where((p) =>
    (p.emiMonths == null || p.emiMonths == 0) && p.amount > 25000
  ).toList();

  candidates.sort((a, b) => b.amount.compareTo(a.amount));
  final topCandidates = candidates.take(2);

  for (final p in topCandidates) {
    final monthlyAmt = p.amount / 12;
    final rate = assumptions.sipReturnRate;
    final fv = _sipFutureValue(monthlyAmt, 120, rate);

    list.add(Suggestion(
      purchaseId: p.id,
      purchaseName: p.name,
      type: SuggestionType.opportunityCost,
      title: 'Opportunity cost of ${p.name}',
      description: 'Your ${_formatCurrency(p.amount)} cash purchase costs you ${_formatCurrency(fv)} in lost investment growth over 10 years (at ${(rate * 100).toStringAsFixed(0)}% SIP returns).',
      impact: 'Lost growth: ${_formatCurrency(fv - p.amount)}',
      impactScore: 10.0,
      targetYear: p.firstYear,
    ));
  }

  return list;
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. Skip & Invest Advisor (new analyzer #9)
// ─────────────────────────────────────────────────────────────────────────────
List<Suggestion> _analyzeSkipAndInvest(
  List<YearProjection> projections,
  List<RecurringPurchase> purchases,
  Assumptions assumptions,
) {
  final list = <Suggestion>[];

  for (final proj in projections) {
    if (proj.year <= 0 || proj.cashFlowDeficit <= 0) continue;
    final deficitYear = proj.year;
    final deficitAmount = proj.cashFlowDeficit;

    for (final p in purchases) {
      if (p.firstYear != deficitYear) continue;
      if (p.category == 'Health' || p.category == 'Education') continue;
      if (p.amount >= 0.50 * deficitAmount) continue;
      if (p.category != 'Tech' && p.category != 'Travel' && p.category != 'Lifestyle') continue;

      final monthlyAmt = p.amount / 12;
      final fv = _sipFutureValue(monthlyAmt, 120, assumptions.sipReturnRate);

      list.add(Suggestion(
        purchaseId: p.id,
        purchaseName: p.name,
        type: SuggestionType.skipAndInvest,
        title: 'Skip ${p.name} and invest instead',
        description: 'Skip buying ${p.name} in Year $deficitYear and invest the ${_formatCurrency(p.amount)} instead. That money grows to ${_formatCurrency(fv)} in 10 years, AND resolves ${_formatCurrency(p.amount)} of your Year $deficitYear deficit.',
        impact: 'Resolves ${_formatCurrency(p.amount)} of deficit & grows to ${_formatCurrency(fv)}',
        impactScore: _calculateScore(
          cashFlowImprovement: p.amount,
          urgency: 80,
          simplicity: 100,
          interestSavings: 0,
          denominator: deficitAmount,
        ),
        targetYear: deficitYear,
      ));
    }
  }

  return list;
}

// ─────────────────────────────────────────────────────────────────────────────
// 10. SIP Flex Advisor (new analyzer #10)
// ─────────────────────────────────────────────────────────────────────────────
List<Suggestion> _analyzeSipFlex(
  UserProfile profile,
  List<YearProjection> projections,
  Assumptions assumptions,
) {
  final list = <Suggestion>[];
  final sipRatePct = profile.sipRatePct;
  if (sipRatePct <= 0.05) return list;

  for (final proj in projections) {
    if (proj.year <= 0 || proj.cashFlowDeficit <= 0) continue;
    final deficitYear = proj.year;
    final deficitAmount = proj.cashFlowDeficit;

    final totalIncome = proj.totalIncome;
    if (totalIncome <= 0) continue;

    final sipReductionNeeded = deficitAmount / 12;
    final suggestedSipPct = math.max(0.05, sipRatePct - (sipReductionNeeded / totalIncome));
    final reductionPctPoints = sipRatePct - suggestedSipPct;

    if (reductionPctPoints <= 0) continue;
    if (reductionPctPoints > 0.05) continue;

    final currentSipMonthly = proj.sipMonthly;
    final reducedSipMonthly = suggestedSipPct * (currentSipMonthly / sipRatePct);

    final sipReturnRate = assumptions.sipReturnRate;
    final remainingYears = math.max(0, 10 - deficitYear);
    final reductionMonthly = currentSipMonthly - reducedSipMonthly;
    final corpusImpact = _sipFutureValue(reductionMonthly, 12, sipReturnRate) * math.pow(1 + sipReturnRate, remainingYears);

    if (corpusImpact > 3 * deficitAmount) continue;

    final restoreYear = deficitYear + 1;

    list.add(Suggestion(
      purchaseId: 'sip_flex_year_$deficitYear',
      purchaseName: 'SIP Flex',
      type: SuggestionType.reduceSip,
      title: 'Temporarily reduce SIP for Year $deficitYear',
      description: 'Reduce SIP from ${(sipRatePct * 100).toStringAsFixed(0)}% to ${(suggestedSipPct * 100).toStringAsFixed(0)}% for Year $deficitYear only, and restore it to ${(sipRatePct * 100).toStringAsFixed(0)}% in Year $restoreYear.',
      impact: 'Costs ${_formatCurrency(corpusImpact)} in 10-year corpus growth to resolve a ${_formatCurrency(deficitAmount)} deficit',
      impactScore: _calculateScore(
        cashFlowImprovement: deficitAmount,
        urgency: 100,
        simplicity: 80,
        interestSavings: 0,
        denominator: deficitAmount,
      ),
      targetYear: deficitYear,
      suggestedSipPct: suggestedSipPct,
      sipRestoreYear: restoreYear,
    ));
  }

  return list;
}

// ─────────────────────────────────────────────────────────────────────────────
// Core Scoring and Deduplication Logic
// ─────────────────────────────────────────────────────────────────────────────
double _calculateScore({
  required double cashFlowImprovement,
  required double urgency,
  required double simplicity,
  required double interestSavings,
  double? denominator,
}) {
  double improvementScore = 0.0;
  if (denominator != null && denominator > 0) {
    improvementScore = (cashFlowImprovement / denominator).clamp(0.0, 1.0) * 100;
  } else {
    improvementScore = (cashFlowImprovement / 100000).clamp(0.0, 1.0) * 100;
  }

  final interestSavingsScore = (interestSavings / 20000).clamp(0.0, 1.0) * 100;

  return (improvementScore * 0.40) +
      (urgency * 0.30) +
      (simplicity * 0.15) +
      (interestSavingsScore * 0.15);
}

List<Suggestion> _rankAndDeduplicate(List<Suggestion> suggestions) {
  final Map<String, List<Suggestion>> grouped = {};
  for (final s in suggestions) {
    final key = (s.type == SuggestionType.opportunityCost || s.type == SuggestionType.skipAndInvest)
        ? '${s.purchaseId}_${s.type.name}'
        : s.purchaseId;
    grouped.putIfAbsent(key, () => []).add(s);
  }

  final deduped = <Suggestion>[];

  for (final entry in grouped.entries) {
    final list = entry.value;
    list.sort((a, b) => b.impactScore.compareTo(a.impactScore));
    deduped.add(list.first);
  }

  deduped.sort((a, b) => b.impactScore.compareTo(a.impactScore));

  return deduped.take(8).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 2 & 3 Public Engine Additions
// ─────────────────────────────────────────────────────────────────────────────

/// Simulates the impact of applying a suggestion.
SimulationResult simulateSuggestion({
  required Suggestion suggestion,
  required UserProfile profile,
  required List<RecurringPurchase> purchases,
  required List<Goal> goals,
  required Assumptions assumptions,
  required List<IncomeSource> incomeSources,
  List<SipRestore> sipRestores = const [],
}) {
  List<RecurringPurchase> modifiedPurchases = purchases.map((p) {
    return RecurringPurchase(
      id: p.id,
      name: p.name,
      amount: p.amount,
      firstYear: p.firstYear,
      recurEveryNYears: p.recurEveryNYears,
      category: p.category,
      note: p.note,
      targetMonth: p.targetMonth,
      emiMonths: p.emiMonths,
      emiInterestRate: p.emiInterestRate,
    );
  }).toList();

  UserProfile modifiedProfile = profile.copyWith();
  List<SipRestore> modifiedSipRestores = List.from(sipRestores);

  void applyOne(Suggestion s) {
    if (s.type == SuggestionType.reduceSip) {
      modifiedProfile = modifiedProfile.copyWith(sipRatePct: s.suggestedSipPct);
      if (s.sipRestoreYear != null) {
        modifiedSipRestores.add(SipRestore(
          originalSipPct: profile.sipRatePct,
          restoreYear: s.sipRestoreYear!,
        ));
      }
    } else {
      final idx = modifiedPurchases.indexWhere((p) => p.id == s.purchaseId);
      if (idx != -1) {
        final p = modifiedPurchases[idx];
        final modifiedP = cloneAndApplySuggestion(p, s);
        modifiedPurchases[idx] = modifiedP;
      }
    }
  }

  if (suggestion.type == SuggestionType.combo && suggestion.comboChildren != null) {
    for (final child in suggestion.comboChildren!) {
      applyOne(child);
    }
  } else {
    applyOne(suggestion);
  }

  final projectionsBefore = finance.generateProjection(
    profile,
    goals,
    purchases,
    assumptions,
    incomeSources: incomeSources,
    sipRestores: sipRestores,
  );

  final projectionsAfter = finance.generateProjection(
    modifiedProfile,
    goals,
    modifiedPurchases,
    assumptions,
    incomeSources: incomeSources,
    sipRestores: modifiedSipRestores,
  );

  double getCorpus(List<YearProjection> projs, int year) {
    if (year < projs.length) {
      return projs[year].corpus;
    }
    return projs.isNotEmpty ? projs.last.corpus : 0.0;
  }

  final corpus5Before = getCorpus(projectionsBefore, 5);
  final corpus5After = getCorpus(projectionsAfter, 5);
  final corpus10Before = getCorpus(projectionsBefore, 10);
  final corpus10After = getCorpus(projectionsAfter, 10);

  final deficitBefore = projectionsBefore
      .where((p) => p.cashFlowDeficit > 0)
      .map((p) => p.year)
      .toList();
  final deficitAfter = projectionsAfter
      .where((p) => p.cashFlowDeficit > 0)
      .map((p) => p.year)
      .toList();

  final fundedBefore = <String, int>{};
  for (final proj in projectionsBefore) {
    for (final gid in proj.fundedGoalIds) {
      fundedBefore[gid] = proj.year;
    }
  }

  final fundedAfter = <String, int>{};
  for (final proj in projectionsAfter) {
    for (final gid in proj.fundedGoalIds) {
      fundedAfter[gid] = proj.year;
    }
  }

  final goalsDelayed = <String>[];
  final goalsAccelerated = <String>[];

  for (final goal in goals) {
    final yBefore = fundedBefore[goal.id];
    final yAfter = fundedAfter[goal.id];

    if (yBefore != null && yAfter == null) {
      goalsDelayed.add(goal.name);
    } else if (yBefore == null && yAfter != null) {
      goalsAccelerated.add(goal.name);
    } else if (yBefore != null && yAfter != null) {
      if (yAfter > yBefore) {
        goalsDelayed.add(goal.name);
      } else if (yAfter < yBefore) {
        goalsAccelerated.add(goal.name);
      }
    }
  }

  return SimulationResult(
    corpusYear5Before: corpus5Before,
    corpusYear5After: corpus5After,
    corpusYear10Before: corpus10Before,
    corpusYear10After: corpus10After,
    deficitYearsBefore: deficitBefore,
    deficitYearsAfter: deficitAfter,
    goalsDelayed: goalsDelayed,
    goalsAccelerated: goalsAccelerated,
  );
}

/// Passive health score (0-100) for a purchase
double purchaseAffordabilityScore(RecurringPurchase p, List<YearProjection> projections) {
  if (p.firstYear >= projections.length || p.firstYear < 0) return 100.0;
  final proj = projections[p.firstYear];

  final purchaseSpendInYear = _getPurchaseSpendInYear(p, p.firstYear);
  final annualFreeCash = proj.freeCashMonthly * 12;
  final purchaseAsPercentOfFreeCash = purchaseSpendInYear / math.max(annualFreeCash, 1.0);

  double emiAmount = 0.0;
  if (p.emiMonths != null && p.emiMonths! > 0) {
    final r = (p.emiInterestRate ?? 0) / 12;
    emiAmount = _calculateEmi(p.amount, r, p.emiMonths!);
  }
  final monthlyEmiAsPercentOfIncome = emiAmount / math.max(proj.totalIncome, 1.0);

  double deficitPenalty = 0.0;
  if (proj.cashFlowDeficit > 0) {
    final totalSpendInYear = proj.techSpendAnnual;
    final contributionRatio = purchaseSpendInYear / math.max(totalSpendInYear, 1.0);
    deficitPenalty = contributionRatio * 40.0;
  }

  final score = 100.0 - (
    purchaseAsPercentOfFreeCash * 50.0 +
    monthlyEmiAsPercentOfIncome * 30.0 +
    deficitPenalty
  );

  return score.clamp(0.0, 100.0);
}

/// Tests all 12 months to find the one producing the lowest peak outflow.
int bestMonthForPurchase(RecurringPurchase p, List<RecurringPurchase> otherPurchases) {
  double minPeakSpend = double.infinity;
  int bestMonth = p.targetMonth ?? 0;

  for (int m = 0; m < 12; m++) {
    final tempPurchase = RecurringPurchase(
      id: p.id,
      name: p.name,
      amount: p.amount,
      firstYear: p.firstYear,
      recurEveryNYears: p.recurEveryNYears,
      category: p.category,
      note: p.note,
      targetMonth: m,
      emiMonths: p.emiMonths,
      emiInterestRate: p.emiInterestRate,
    );

    final tempPurchases = [...otherPurchases, tempPurchase];
    final breakdown = monthlySpendBreakdown(tempPurchases, p.firstYear);
    
    double peakSpend = 0.0;
    for (final s in breakdown) {
      if (s > peakSpend) peakSpend = s;
    }

    if (peakSpend < minPeakSpend) {
      minPeakSpend = peakSpend;
      bestMonth = m;
    }
  }

  return bestMonth;
}

// ── Low-level helper methods duplicated from finance.dart ────────────────────
double _getPurchaseSpendInYear(RecurringPurchase p, int year) {
  if (year < p.firstYear) return 0;
  final startYear = p.firstYear;

  if (p.emiMonths != null && p.emiMonths! > 0) {
    final emiMonths = p.emiMonths!;
    final r = (p.emiInterestRate ?? 0) / 12;
    final emiAmount = _calculateEmi(p.amount, r, emiMonths);
    final startMonth = p.targetMonth ?? 0;

    if (p.recurEveryNYears == null) {
      return _monthsInYearForEmi(year, startYear, startMonth, emiMonths) * emiAmount;
    } else {
      double total = 0;
      for (int instanceYear = startYear; instanceYear <= year; instanceYear += p.recurEveryNYears!) {
        total += _monthsInYearForEmi(year, instanceYear, startMonth, emiMonths) * emiAmount;
      }
      return total;
    }
  } else {
    if (p.recurEveryNYears == null) {
      return (year == p.firstYear) ? p.amount : 0;
    } else {
      final elapsed = year - p.firstYear;
      return (elapsed >= 0 && elapsed % p.recurEveryNYears! == 0) ? p.amount : 0;
    }
  }
}

double _getEmiSpendInYear(
  double principal,
  double annualRate,
  int emiMonths,
  int startYear,
  int startMonth,
  int checkYear,
  int? recurEveryNYears,
) {
  final r = annualRate / 12;
  final emiAmount = _calculateEmi(principal, r, emiMonths);

  if (recurEveryNYears == null) {
    return _monthsInYearForEmi(checkYear, startYear, startMonth, emiMonths) * emiAmount;
  } else {
    double total = 0;
    for (int instanceYear = startYear; instanceYear <= checkYear; instanceYear += recurEveryNYears) {
      total += _monthsInYearForEmi(checkYear, instanceYear, startMonth, emiMonths) * emiAmount;
    }
    return total;
  }
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
