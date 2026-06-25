import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal_suggestion.dart';
import '../goal_suggestion_engine.dart';
import 'user_profile_provider.dart';
import 'goals_provider.dart';
import 'purchases_provider.dart';
import 'assumptions_provider.dart';
import 'income_provider.dart';
import 'projection_provider.dart';

final dismissedGoalSuggestionsProvider = StateProvider<Set<String>>((ref) => {});

final goalSuggestionsProvider = Provider<List<GoalSuggestion>>((ref) {
  final profile = ref.watch(userProfileProvider);
  final goals = ref.watch(goalsProvider);
  final purchases = ref.watch(purchasesProvider);
  final assumptions = ref.watch(assumptionsProvider);
  final incomeSources = ref.watch(incomeSourcesProvider);
  final projections = ref.watch(projectionProvider);
  final dismissed = ref.watch(dismissedGoalSuggestionsProvider);

  if (profile == null || projections.isEmpty) {
    return const [];
  }

  final allSuggestions = generateGoalSuggestions(
    profile: profile,
    purchases: purchases,
    goals: goals,
    assumptions: assumptions,
    incomeSources: incomeSources,
    projections: projections,
  );

  return allSuggestions.where((s) {
    final key = '${s.goalId}_${s.type.name}';
    return !dismissed.contains(key);
  }).toList();
});
