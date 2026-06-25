import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/suggestion.dart';
import '../suggestion_engine.dart';
import 'user_profile_provider.dart';
import 'goals_provider.dart';
import 'purchases_provider.dart';
import 'assumptions_provider.dart';
import 'income_provider.dart';
import 'projection_provider.dart';

/// Stores the set of unique keys (e.g. "purchaseId_suggestionType") of suggestions that the user has dismissed.
final dismissedSuggestionsProvider = StateProvider<Set<String>>((ref) => {});

/// Provider that exposes the active list of financial suggestions, sorted and filtered of dismissed items.
final suggestionsProvider = Provider<List<Suggestion>>((ref) {
  final profile = ref.watch(userProfileProvider);
  final goals = ref.watch(goalsProvider);
  final purchases = ref.watch(purchasesProvider);
  final assumptions = ref.watch(assumptionsProvider);
  final incomeSources = ref.watch(incomeSourcesProvider);
  final projections = ref.watch(projectionProvider);
  final dismissed = ref.watch(dismissedSuggestionsProvider);

  if (profile == null || projections.isEmpty) {
    return const [];
  }

  final allSuggestions = generateSuggestions(
    profile: profile,
    purchases: purchases,
    goals: goals,
    assumptions: assumptions,
    incomeSources: incomeSources,
    projections: projections,
  );

  return allSuggestions.where((s) {
    final key = '${s.purchaseId}_${s.type.name}';
    return !dismissed.contains(key);
  }).toList();
});
