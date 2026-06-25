import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../finance.dart' as finance;
import '../models/year_projection.dart';
import 'user_profile_provider.dart';
import 'goals_provider.dart';
import 'purchases_provider.dart';
import 'assumptions_provider.dart';

/// Computed list of year-by-year projections (year 0–20).
/// Re-computes whenever profile, goals, purchases, or assumptions change.
final projectionProvider = Provider<List<YearProjection>>((ref) {
  final profile = ref.watch(userProfileProvider);
  final goals = ref.watch(goalsProvider);
  final purchases = ref.watch(purchasesProvider);
  final assumptions = ref.watch(assumptionsProvider);

  if (profile == null) return [];

  return finance.generateProjection(profile, goals, purchases, assumptions);
});

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
