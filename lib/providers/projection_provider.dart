import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../finance.dart' as finance;
import '../models/year_projection.dart';
import 'user_profile_provider.dart';
import 'goals_provider.dart';
import 'purchases_provider.dart';
import 'assumptions_provider.dart';
import 'income_provider.dart';

/// A boolean provider that indicates if calculation is currently debouncing.
final projectionRecalculatingProvider = StateProvider<bool>((ref) => false);

/// Computed list of year-by-year projections (year 0–20).
/// Re-computes with a 300ms debounce whenever profile, goals, purchases, assumptions, or income sources change.
final projectionProvider = StateNotifierProvider<ProjectionNotifier, List<YearProjection>>((ref) {
  return ProjectionNotifier(ref);
});

class ProjectionNotifier extends StateNotifier<List<YearProjection>> {
  final Ref _ref;
  Timer? _debounceTimer;

  ProjectionNotifier(this._ref) : super([]) {
    // Watch/Listen to dependent providers
    _ref.listen(userProfileProvider, (prev, next) => _triggerDebouncedUpdate());
    _ref.listen(goalsProvider, (prev, next) => _triggerDebouncedUpdate());
    _ref.listen(purchasesProvider, (prev, next) => _triggerDebouncedUpdate());
    _ref.listen(assumptionsProvider, (prev, next) => _triggerDebouncedUpdate());
    _ref.listen(incomeSourcesProvider, (prev, next) => _triggerDebouncedUpdate());

    // Initial sync compute
    _updateNow();
  }

  void _triggerDebouncedUpdate() {
    _debounceTimer?.cancel();
    _ref.read(projectionRecalculatingProvider.notifier).state = true;
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _updateNow();
    });
  }

  void _updateNow() {
    _ref.read(projectionRecalculatingProvider.notifier).state = false;
    final profile = _ref.read(userProfileProvider);
    final goals = _ref.read(goalsProvider);
    final purchases = _ref.read(purchasesProvider);
    final assumptions = _ref.read(assumptionsProvider);
    final incomeSources = _ref.read(incomeSourcesProvider);

    if (profile == null) {
      state = [];
    } else {
      state = finance.generateProjection(
        profile,
        goals,
        purchases,
        assumptions,
        incomeSources: incomeSources,
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Convenience provider for a single year's projection.
final yearProjectionProvider =
    Provider.family<YearProjection?, int>((ref, year) {
  final projections = ref.watch(projectionProvider);
  try {
    return projections.firstWhere((p) => p.year == year);
  } catch (_) {
    return null;
  }
});
