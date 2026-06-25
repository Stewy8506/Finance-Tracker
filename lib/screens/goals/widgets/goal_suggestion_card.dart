import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/goal_suggestion.dart';
import '../../../models/goal_simulation_result.dart';
import '../../../models/recurring_purchase.dart';
import '../../../providers/goals_provider.dart';
import '../../../providers/purchases_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/assumptions_provider.dart';
import '../../../providers/income_provider.dart';
import '../../../providers/goal_suggestions_provider.dart';
import '../../../theme.dart';
import '../../../goal_suggestion_engine.dart';
import '../../../utils/currency_formatter.dart';

class GoalSuggestionCard extends ConsumerStatefulWidget {
  final GoalSuggestion suggestion;

  const GoalSuggestionCard({
    super.key,
    required this.suggestion,
  });

  @override
  ConsumerState<GoalSuggestionCard> createState() => _GoalSuggestionCardState();
}

class _GoalSuggestionCardState extends ConsumerState<GoalSuggestionCard> {
  bool _isExpanded = false;

  Map<String, dynamic> _getTypeConfig(GoalSuggestionType type, LedgerColors ledgerColors) {
    switch (type) {
      case GoalSuggestionType.increaseSip:
        return {
          'icon': Icons.trending_up,
          'color': ledgerColors.success,
          'bg': ledgerColors.success.withValues(alpha: 0.15),
          'label': 'Increase SIP',
        };
      case GoalSuggestionType.delayGoal:
        return {
          'icon': Icons.update,
          'color': ledgerColors.warning,
          'bg': ledgerColors.warning.withValues(alpha: 0.15),
          'label': 'Delay Goal',
        };
      case GoalSuggestionType.reduceTargetAmount:
        return {
          'icon': Icons.compress,
          'color': ledgerColors.warning,
          'bg': ledgerColors.warning.withValues(alpha: 0.15),
          'label': 'Reduce Target',
        };
      case GoalSuggestionType.delayPurchases:
        return {
          'icon': Icons.money_off,
          'color': ledgerColors.success,
          'bg': ledgerColors.success.withValues(alpha: 0.15),
          'label': 'Delay Purchases',
        };
    }
  }

  void _applySuggestion(BuildContext context) async {
    final s = widget.suggestion;

    if (s.type == GoalSuggestionType.increaseSip) {
      final profile = ref.read(userProfileProvider);
      if (profile == null) return;
      final prevSip = profile.sipRatePct;
      await ref.read(userProfileProvider.notifier).update((p) => p.copyWith(sipRatePct: s.suggestedSipPct));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied: Increased SIP to ${(s.suggestedSipPct! * 100).toStringAsFixed(0)}%'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                ref.read(userProfileProvider.notifier).update((p) => p.copyWith(sipRatePct: prevSip));
              },
            ),
          ),
        );
      }
    } else if (s.type == GoalSuggestionType.delayGoal) {
      final goals = ref.read(goalsProvider);
      final g = goals.firstWhere((g) => g.id == s.goalId);
      final prevTargetYear = g.targetYear;
      await ref.read(goalsProvider.notifier).update(g.copyWith(targetYear: s.suggestedTargetYear));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied: Delayed goal to Year ${s.suggestedTargetYear}'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                ref.read(goalsProvider.notifier).update(g.copyWith(targetYear: prevTargetYear));
              },
            ),
          ),
        );
      }
    } else if (s.type == GoalSuggestionType.reduceTargetAmount) {
      final goals = ref.read(goalsProvider);
      final g = goals.firstWhere((g) => g.id == s.goalId);
      final prevAmount = g.targetAmount;
      await ref.read(goalsProvider.notifier).update(g.copyWith(targetAmount: s.suggestedTargetAmount));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied: Reduced target to ${formatCurrency(s.suggestedTargetAmount!)}'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                ref.read(goalsProvider.notifier).update(g.copyWith(targetAmount: prevAmount));
              },
            ),
          ),
        );
      }
    } else if (s.type == GoalSuggestionType.delayPurchases) {
      final purchases = ref.read(purchasesProvider);
      final previousPurchases = <String, RecurringPurchase>{};

      final pIds = s.purchasesToDelay ?? [];
      for (final pid in pIds) {
        final p = purchases.firstWhere((p) => p.id == pid);
        previousPurchases[pid] = RecurringPurchase(
          id: p.id, name: p.name, amount: p.amount, firstYear: p.firstYear,
          recurEveryNYears: p.recurEveryNYears, category: p.category, note: p.note,
          targetMonth: p.targetMonth, emiMonths: p.emiMonths, emiInterestRate: p.emiInterestRate,
        );
        await ref.read(purchasesProvider.notifier).update(
          previousPurchases[pid]!.copyWith(firstYear: p.firstYear + 3)
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied: Delayed ${pIds.length} purchase(s)'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                for (final prev in previousPurchases.values) {
                  await ref.read(purchasesProvider.notifier).update(prev);
                }
              },
            ),
          ),
        );
      }
    }

    _dismissSuggestion();
  }

  void _dismissSuggestion() {
    final s = widget.suggestion;
    final key = '${s.goalId}_${s.type.name}';
    ref.read(dismissedGoalSuggestionsProvider.notifier).update((state) => {...state, key});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledgerColors = theme.extension<LedgerColors>() ?? LedgerColors.dark;
    final config = _getTypeConfig(widget.suggestion.type, ledgerColors);

    final IconData iconData = config['icon'];
    final Color itemColor = config['color'];
    final Color bgColor = config['bg'];
    final String label = config['label'];

    final profile = ref.watch(userProfileProvider);
    final goals = ref.watch(goalsProvider);
    final purchases = ref.watch(purchasesProvider);
    final assumptions = ref.watch(assumptionsProvider);
    final incomeSources = ref.watch(incomeSourcesProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111215).withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1F2128).withValues(alpha: 0.5), width: 0.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(iconData, color: itemColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              color: itemColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Score: ${widget.suggestion.impactScore.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Text(
                  widget.suggestion.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  widget.suggestion.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2128).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.flash_on, color: ledgerColors.success, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.suggestion.impact,
                          style: TextStyle(
                            color: ledgerColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2128),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (widget.suggestion.impactScore / 100.0).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              itemColor.withValues(alpha: 0.6),
                              itemColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                if (profile != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            _isExpanded ? 'Hide Impact Preview' : 'Preview Impact (What-If Analysis)',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isExpanded
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildSimulationPanel(
                              context: context,
                              theme: theme,
                              colors: ledgerColors,
                              result: simulateGoalSuggestion(
                                suggestion: widget.suggestion,
                                profile: profile,
                                purchases: purchases,
                                goals: goals,
                                assumptions: assumptions,
                                incomeSources: incomeSources,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _dismissSuggestion,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Dismiss'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _applySuggestion(context),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Apply'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: const Color(0xFF08090A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimulationPanel({
    required BuildContext context,
    required ThemeData theme,
    required LedgerColors colors,
    required GoalSimulationResult result,
  }) {
    final fundedBefore = result.fundedYearBefore;
    final fundedAfter = result.fundedYearAfter;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131418).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2128).withValues(alpha: 0.5), width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROJECTION SIMULATION',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Goal Funded Year',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fundedBefore != null ? 'Year $fundedBefore' : 'Not Funded',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                  const Icon(Icons.arrow_right_alt, color: Colors.grey, size: 16),
                  Text(
                    fundedAfter != null ? 'Year $fundedAfter' : 'Not Funded',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: (fundedAfter != null && (fundedBefore == null || fundedAfter < fundedBefore)) ? colors.success : colors.high,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
