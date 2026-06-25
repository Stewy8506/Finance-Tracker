import 'dart:math' as math;

import 'models/user_profile.dart';
import 'models/goal.dart';
import 'models/recurring_purchase.dart';
import 'models/assumptions.dart';
import 'models/income_source.dart';
import 'models/year_projection.dart';
import 'models/goal_suggestion.dart';
import 'models/goal_simulation_result.dart';
import 'finance.dart' as finance;

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

/// Generates suggestions to achieve goals that are delayed.
List<GoalSuggestion> generateGoalSuggestions({
  required UserProfile profile,
  required List<RecurringPurchase> purchases,
  required List<Goal> goals,
  required Assumptions assumptions,
  required List<IncomeSource> incomeSources,
  required List<YearProjection> projections,
}) {
  final suggestions = <GoalSuggestion>[];

  // Map each goal to the year it was funded (if at all)
  final fundedYears = <String, int>{};
  for (final proj in projections) {
    for (final gid in proj.fundedGoalIds) {
      fundedYears[gid] = proj.year;
    }
  }

  for (final goal in goals) {
    final fundedYear = fundedYears[goal.id];
    
    // Check if goal is delayed (not funded, or funded after targetYear)
    final isDelayed = fundedYear == null || fundedYear > goal.targetYear;
    if (!isDelayed) continue; // Goal is on track

    // 1. Suggest Delay Goal
    if (fundedYear != null) {
      suggestions.add(GoalSuggestion(
        goalId: goal.id,
        goalName: goal.name,
        type: GoalSuggestionType.delayGoal,
        title: 'Delay ${goal.name} to Year $fundedYear',
        description: 'Current projections show this goal will be funded in Year $fundedYear. Update your target year to make it realistic.',
        impact: 'Aligns expectations with realistic growth.',
        impactScore: 50.0,
        targetYear: goal.targetYear,
        suggestedTargetYear: fundedYear,
      ));
    }

    // 2. Suggest Increase SIP
    final sipSuggestion = _analyzeSipIncrease(
      goal: goal,
      profile: profile,
      purchases: purchases,
      goals: goals,
      assumptions: assumptions,
      incomeSources: incomeSources,
      fundedYear: fundedYear,
    );
    if (sipSuggestion != null) suggestions.add(sipSuggestion);

    // 3. Suggest Reduce Target Amount
    final reduceTargetSuggestion = _analyzeTargetReduction(
      goal: goal,
      projections: projections,
      assumptions: assumptions,
    );
    if (reduceTargetSuggestion != null) suggestions.add(reduceTargetSuggestion);

    // 4. Suggest Delay Discretionary Purchases
    final delayPurchasesSuggestions = _analyzePurchaseSacrifice(
      goal: goal,
      profile: profile,
      purchases: purchases,
      goals: goals,
      assumptions: assumptions,
      incomeSources: incomeSources,
    );
    suggestions.addAll(delayPurchasesSuggestions);
  }

  // Deduplicate and rank
  final Map<String, List<GoalSuggestion>> grouped = {};
  for (final s in suggestions) {
    grouped.putIfAbsent('${s.goalId}_${s.type.name}', () => []).add(s);
  }

  final deduped = <GoalSuggestion>[];
  for (final entry in grouped.entries) {
    final list = entry.value;
    list.sort((a, b) => b.impactScore.compareTo(a.impactScore));
    deduped.add(list.first);
  }

  deduped.sort((a, b) => b.impactScore.compareTo(a.impactScore));
  return deduped.take(8).toList();
}

GoalSuggestion? _analyzeSipIncrease({
  required Goal goal,
  required UserProfile profile,
  required List<RecurringPurchase> purchases,
  required List<Goal> goals,
  required Assumptions assumptions,
  required List<IncomeSource> incomeSources,
  int? fundedYear,
}) {
  // If SIP is already very high (>50%), don't suggest increasing it further realistically
  if (profile.sipRatePct >= 0.50) return null;

  // Try increments of 5% up to 50%
  for (double testSip = profile.sipRatePct + 0.05; testSip <= 0.50; testSip += 0.05) {
    final testProfile = profile.copyWith(sipRatePct: testSip);
    final testProjections = finance.generateProjection(
      testProfile,
      goals,
      purchases,
      assumptions,
      incomeSources: incomeSources,
      maxYears: 30,
    );

    int? newFundedYear;
    for (final proj in testProjections) {
      if (proj.fundedGoalIds.contains(goal.id)) {
        newFundedYear = proj.year;
        break;
      }
    }

    if (newFundedYear != null && newFundedYear <= goal.targetYear) {
      final extraSipPct = ((testSip - profile.sipRatePct) * 100).toStringAsFixed(0);
      return GoalSuggestion(
        goalId: goal.id,
        goalName: goal.name,
        type: GoalSuggestionType.increaseSip,
        title: 'Increase SIP by $extraSipPct% to achieve ${goal.name}',
        description: 'Your SIP rate is currently ${(profile.sipRatePct * 100).toStringAsFixed(0)}%. Increasing it to ${(testSip * 100).toStringAsFixed(0)}% will allow you to fund ${goal.name} on time in Year ${goal.targetYear}.',
        impact: 'Achieves goal on time in Year ${goal.targetYear}.',
        impactScore: 80.0,
        targetYear: goal.targetYear,
        suggestedSipPct: testSip,
      );
    }
  }

  return null;
}

GoalSuggestion? _analyzeTargetReduction({
  required Goal goal,
  required List<YearProjection> projections,
  required Assumptions assumptions,
}) {
  if (goal.targetYear >= projections.length) return null;

  final targetYearProj = projections[goal.targetYear];
  // Calculate total corpus available in that year (assuming we don't fund this goal yet)
  // Actually, we can just look at the corpus available. 
  // We'll estimate realistic corpus size.
  // The goal might be competing with other goals. If it's just this goal, corpus is targetYearProj.corpus.
  double availableCorpus = targetYearProj.corpus;
  
  if (availableCorpus < 50000) return null; // Too small to matter

  final newTargetAmount = (availableCorpus * 0.95).floorToDouble(); // 95% of available
  if (newTargetAmount < goal.targetAmount * 0.5) return null; // Don't suggest cutting it by more than half

  final inflationAdjustedCurrentTarget = goal.adjustForInflation == true
      ? goal.targetAmount * math.pow(1 + assumptions.expenseInflation, goal.targetYear)
      : goal.targetAmount;

  if (availableCorpus >= inflationAdjustedCurrentTarget) return null; // It's actually funded?

  return GoalSuggestion(
    goalId: goal.id,
    goalName: goal.name,
    type: GoalSuggestionType.reduceTargetAmount,
    title: 'Reduce ${goal.name} target to ${_formatCurrency(newTargetAmount)}',
    description: 'You will have around ${_formatCurrency(availableCorpus)} available in Year ${goal.targetYear}. Reducing your goal target makes it achievable on time.',
    impact: 'Reduces shortfall by ${_formatCurrency(goal.targetAmount - newTargetAmount)}',
    impactScore: 60.0,
    targetYear: goal.targetYear,
    suggestedTargetAmount: newTargetAmount,
  );
}

List<GoalSuggestion> _analyzePurchaseSacrifice({
  required Goal goal,
  required UserProfile profile,
  required List<RecurringPurchase> purchases,
  required List<Goal> goals,
  required Assumptions assumptions,
  required List<IncomeSource> incomeSources,
}) {
  final list = <GoalSuggestion>[];

  // Find non-essential purchases scheduled before or in the target year
  final discretionary = purchases.where((p) =>
      p.firstYear <= goal.targetYear &&
      (p.category == 'Tech' || p.category == 'Travel' || p.category == 'Lifestyle' || p.category == 'Misc')).toList();

  if (discretionary.isEmpty) return list;

  // We can try removing/delaying the largest purchase and see if it funds the goal
  discretionary.sort((a, b) => b.amount.compareTo(a.amount));
  
  for (final p in discretionary) {
    if (p.amount < 50000) continue;

    // Simulate delaying this purchase by 3 years
    final modifiedPurchases = purchases.map((orig) {
      if (orig.id == p.id) {
        return RecurringPurchase(
          id: orig.id,
          name: orig.name,
          amount: orig.amount,
          firstYear: orig.firstYear + 3,
          recurEveryNYears: orig.recurEveryNYears,
          category: orig.category,
          note: orig.note,
          targetMonth: orig.targetMonth,
          emiMonths: orig.emiMonths,
          emiInterestRate: orig.emiInterestRate,
        );
      }
      return orig;
    }).toList();

    final testProjections = finance.generateProjection(
      profile,
      goals,
      modifiedPurchases,
      assumptions,
      incomeSources: incomeSources,
      maxYears: 30,
    );

    int? newFundedYear;
    for (final proj in testProjections) {
      if (proj.fundedGoalIds.contains(goal.id)) {
        newFundedYear = proj.year;
        break;
      }
    }

    if (newFundedYear != null && newFundedYear <= goal.targetYear) {
      list.add(GoalSuggestion(
        goalId: goal.id,
        goalName: goal.name,
        type: GoalSuggestionType.delayPurchases,
        title: 'Delay ${p.name} to fund ${goal.name}',
        description: 'Delaying ${p.name} by 3 years frees up enough corpus growth to fund ${goal.name} on time.',
        impact: 'Achieves goal on time in Year ${goal.targetYear}.',
        impactScore: 70.0,
        targetYear: goal.targetYear,
        purchasesToDelay: [p.id],
      ));
      break; // Found a working sacrifice
    }
  }

  return list;
}

GoalSimulationResult simulateGoalSuggestion({
  required GoalSuggestion suggestion,
  required UserProfile profile,
  required List<RecurringPurchase> purchases,
  required List<Goal> goals,
  required Assumptions assumptions,
  required List<IncomeSource> incomeSources,
}) {
  UserProfile modifiedProfile = profile.copyWith();
  List<Goal> modifiedGoals = List.from(goals);
  List<RecurringPurchase> modifiedPurchases = List.from(purchases);

  if (suggestion.type == GoalSuggestionType.increaseSip) {
    modifiedProfile = modifiedProfile.copyWith(sipRatePct: suggestion.suggestedSipPct);
  } else if (suggestion.type == GoalSuggestionType.delayGoal) {
    final idx = modifiedGoals.indexWhere((g) => g.id == suggestion.goalId);
    if (idx != -1) {
      modifiedGoals[idx] = modifiedGoals[idx].copyWith(targetYear: suggestion.suggestedTargetYear);
    }
  } else if (suggestion.type == GoalSuggestionType.reduceTargetAmount) {
    final idx = modifiedGoals.indexWhere((g) => g.id == suggestion.goalId);
    if (idx != -1) {
      modifiedGoals[idx] = modifiedGoals[idx].copyWith(targetAmount: suggestion.suggestedTargetAmount);
    }
  } else if (suggestion.type == GoalSuggestionType.delayPurchases) {
    final pIds = suggestion.purchasesToDelay ?? [];
    modifiedPurchases = modifiedPurchases.map((orig) {
      if (pIds.contains(orig.id)) {
        return RecurringPurchase(
          id: orig.id,
          name: orig.name,
          amount: orig.amount,
          firstYear: orig.firstYear + 3,
          recurEveryNYears: orig.recurEveryNYears,
          category: orig.category,
          note: orig.note,
          targetMonth: orig.targetMonth,
          emiMonths: orig.emiMonths,
          emiInterestRate: orig.emiInterestRate,
        );
      }
      return orig;
    }).toList();
  }

  final projsBefore = finance.generateProjection(
    profile,
    goals,
    purchases,
    assumptions,
    incomeSources: incomeSources,
  );

  final projsAfter = finance.generateProjection(
    modifiedProfile,
    modifiedGoals,
    modifiedPurchases,
    assumptions,
    incomeSources: incomeSources,
  );

  int? fundedBefore;
  for (final p in projsBefore) {
    if (p.fundedGoalIds.contains(suggestion.goalId)) {
      fundedBefore = p.year;
      break;
    }
  }

  int? fundedAfter;
  for (final p in projsAfter) {
    if (p.fundedGoalIds.contains(suggestion.goalId)) {
      fundedAfter = p.year;
      break;
    }
  }

  double getCorpus(List<YearProjection> projs, int year) {
    if (year < projs.length) return projs[year].corpus;
    return projs.isNotEmpty ? projs.last.corpus : 0.0;
  }

  return GoalSimulationResult(
    fundedYearBefore: fundedBefore,
    fundedYearAfter: fundedAfter,
    corpusYear5Before: getCorpus(projsBefore, 5),
    corpusYear5After: getCorpus(projsAfter, 5),
    corpusYear10Before: getCorpus(projsBefore, 10),
    corpusYear10After: getCorpus(projsAfter, 10),
  );
}
