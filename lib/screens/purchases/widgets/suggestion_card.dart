import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/suggestion.dart';
import '../../../models/recurring_purchase.dart';
import '../../../models/sip_restore.dart';
import '../../../models/suggestion_history.dart';
import '../../../models/simulation_result.dart';
import '../../../providers/purchases_provider.dart';
import '../../../providers/suggestions_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/goals_provider.dart';
import '../../../providers/assumptions_provider.dart';
import '../../../providers/income_provider.dart';
import '../../../providers/sip_restore_provider.dart';
import '../../../providers/suggestion_history_provider.dart';
import '../../../theme.dart';
import '../../../suggestion_engine.dart';
import '../../../utils/currency_formatter.dart';

class SuggestionCard extends ConsumerStatefulWidget {
  final Suggestion suggestion;

  const SuggestionCard({
    super.key,
    required this.suggestion,
  });

  @override
  ConsumerState<SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends ConsumerState<SuggestionCard> {
  bool _isExpanded = false;

  Map<String, dynamic> _getTypeConfig(SuggestionType type, LedgerColors ledgerColors) {
    switch (type) {
      case SuggestionType.convertToEmi:
        return {
          'icon': Icons.credit_card_outlined,
          'color': ledgerColors.high,
          'bg': ledgerColors.high.withValues(alpha: 0.15),
          'label': 'Deficit Resolver',
        };
      case SuggestionType.extendEmi:
        return {
          'icon': Icons.rotate_right_outlined,
          'color': ledgerColors.high,
          'bg': ledgerColors.high.withValues(alpha: 0.15),
          'label': 'Optimize EMI',
        };
      case SuggestionType.delayPurchase:
        return {
          'icon': Icons.date_range_outlined,
          'color': ledgerColors.high,
          'bg': ledgerColors.high.withValues(alpha: 0.15),
          'label': 'Deficit Resolver',
        };
      case SuggestionType.spreadMonths:
        return {
          'icon': Icons.grid_view_outlined,
          'color': ledgerColors.warning,
          'bg': ledgerColors.warning.withValues(alpha: 0.15),
          'label': 'Clustering',
        };
      case SuggestionType.reduceInterest:
        return {
          'icon': Icons.percent_outlined,
          'color': ledgerColors.success,
          'bg': ledgerColors.success.withValues(alpha: 0.15),
          'label': 'Save Interest',
        };
      case SuggestionType.staggerEmis:
        return {
          'icon': Icons.view_agenda_outlined,
          'color': ledgerColors.success,
          'bg': ledgerColors.success.withValues(alpha: 0.15),
          'label': 'Stagger EMIs',
        };
      case SuggestionType.incomeAlign:
        return {
          'icon': Icons.trending_up_outlined,
          'color': ledgerColors.success,
          'bg': ledgerColors.success.withValues(alpha: 0.15),
          'label': 'Income Timing',
        };
      case SuggestionType.levelSpike:
        return {
          'icon': Icons.bar_chart_outlined,
          'color': ledgerColors.warning,
          'bg': ledgerColors.warning.withValues(alpha: 0.15),
          'label': 'Spend Spike',
        };
      case SuggestionType.goalConflict:
        return {
          'icon': Icons.flag_outlined,
          'color': ledgerColors.warning,
          'bg': ledgerColors.warning.withValues(alpha: 0.15),
          'label': 'Goal Conflict',
        };
      case SuggestionType.combo:
        return {
          'icon': Icons.auto_awesome_outlined,
          'color': ledgerColors.success,
          'bg': ledgerColors.success.withValues(alpha: 0.15),
          'label': 'Combo Solution',
        };
      case SuggestionType.opportunityCost:
        return {
          'icon': Icons.pie_chart_outline,
          'color': Colors.blue,
          'bg': Colors.blue.withValues(alpha: 0.15),
          'label': 'Opportunity Cost',
        };
      case SuggestionType.skipAndInvest:
        return {
          'icon': Icons.savings_outlined,
          'color': Colors.blue,
          'bg': Colors.blue.withValues(alpha: 0.15),
          'label': 'Skip & Invest',
        };
      case SuggestionType.reduceSip:
        return {
          'icon': Icons.tune_outlined,
          'color': ledgerColors.warning,
          'bg': ledgerColors.warning.withValues(alpha: 0.15),
          'label': 'SIP Flex',
        };
    }
  }

  double _parseCashFlowImpact(String impact) {
    final regExp = RegExp(r'₹([\d\.]+)([LK]?)');
    final match = regExp.firstMatch(impact);
    if (match != null) {
      final valueStr = match.group(1)!;
      final multiplier = match.group(2);
      double val = double.tryParse(valueStr) ?? 0.0;
      if (multiplier == 'L') {
        val *= 100000;
      } else if (multiplier == 'K') {
        val *= 1000;
      }
      return val;
    }
    return 0.0;
  }

  void _applySuggestion(BuildContext context) async {
    final s = widget.suggestion;

    if (s.type == SuggestionType.reduceSip) {
      final profile = ref.read(userProfileProvider);
      if (profile == null) return;

      final previousSipRate = profile.sipRatePct;

      // Apply temporary SIP rate
      await ref.read(userProfileProvider.notifier).update((p) => p.copyWith(
        sipRatePct: s.suggestedSipPct,
      ));

      // Schedule restore
      if (s.sipRestoreYear != null) {
        final restore = SipRestore(
          originalSipPct: previousSipRate,
          restoreYear: s.sipRestoreYear!,
        );
        await ref.read(sipRestoreProvider.notifier).add(restore);
      }

      // Log to history
      final historyEntry = SuggestionHistoryEntry(
        suggestionTitle: s.title,
        type: s.type.name,
        impactScore: s.impactScore,
        appliedAt: DateTime.now(),
        cashFlowImpact: _parseCashFlowImpact(s.impact),
      );
      await ref.read(suggestionHistoryProvider.notifier).add(historyEntry);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text('Applied: "${s.title}" (SIP reduced to ${(s.suggestedSipPct! * 100).toStringAsFixed(0)}%)'),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Theme.of(context).colorScheme.primary,
              onPressed: () async {
                // Restore profile
                await ref.read(userProfileProvider.notifier).update((p) => p.copyWith(
                  sipRatePct: previousSipRate,
                ));
                // Clear restores
                await ref.read(sipRestoreProvider.notifier).clearAll();
              },
            ),
          ),
        );
      }
    } else if (s.type == SuggestionType.combo) {
      final purchases = ref.read(purchasesProvider);
      final previousPurchases = <String, RecurringPurchase>{};

      for (final child in s.comboChildren!) {
        final p = purchases.firstWhere((p) => p.id == child.purchaseId);
        previousPurchases[p.id] = RecurringPurchase(
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
      }

      for (final child in s.comboChildren!) {
        final p = purchases.firstWhere((p) => p.id == child.purchaseId);
        final updatedP = cloneAndApplySuggestion(p, child);
        await ref.read(purchasesProvider.notifier).update(updatedP);
      }

      final historyEntry = SuggestionHistoryEntry(
        suggestionTitle: s.title,
        type: s.type.name,
        impactScore: s.impactScore,
        appliedAt: DateTime.now(),
        cashFlowImpact: _parseCashFlowImpact(s.impact),
      );
      await ref.read(suggestionHistoryProvider.notifier).add(historyEntry);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text('Applied: "${s.title}"'),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Theme.of(context).colorScheme.primary,
              onPressed: () async {
                for (final prev in previousPurchases.values) {
                  await ref.read(purchasesProvider.notifier).update(prev);
                }
              },
            ),
          ),
        );
      }
    } else {
      final purchases = ref.read(purchasesProvider);
      final targetPurchase = purchases.firstWhere((p) => p.id == s.purchaseId);

      final previousCopy = RecurringPurchase(
        id: targetPurchase.id,
        name: targetPurchase.name,
        amount: targetPurchase.amount,
        firstYear: targetPurchase.firstYear,
        recurEveryNYears: targetPurchase.recurEveryNYears,
        category: targetPurchase.category,
        note: targetPurchase.note,
        targetMonth: targetPurchase.targetMonth,
        emiMonths: targetPurchase.emiMonths,
        emiInterestRate: targetPurchase.emiInterestRate,
      );

      final updatedPurchase = cloneAndApplySuggestion(targetPurchase, s);
      await ref.read(purchasesProvider.notifier).update(updatedPurchase);

      final historyEntry = SuggestionHistoryEntry(
        suggestionTitle: s.title,
        type: s.type.name,
        impactScore: s.impactScore,
        appliedAt: DateTime.now(),
        cashFlowImpact: _parseCashFlowImpact(s.impact),
      );
      await ref.read(suggestionHistoryProvider.notifier).add(historyEntry);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text('Applied: "${s.title}"'),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Theme.of(context).colorScheme.primary,
              onPressed: () async {
                await ref.read(purchasesProvider.notifier).update(previousCopy);
              },
            ),
          ),
        );
      }
    }
  }

  void _dismissSuggestion() {
    final s = widget.suggestion;
    final key = '${s.purchaseId}_${s.type.name}';
    ref.read(dismissedSuggestionsProvider.notifier).update((state) => {...state, key});
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

    final isInformational = widget.suggestion.type == SuggestionType.opportunityCost ||
        widget.suggestion.type == SuggestionType.skipAndInvest;

    // Simulation Preview Data
    final profile = ref.watch(userProfileProvider);
    final goals = ref.watch(goalsProvider);
    final purchases = ref.watch(purchasesProvider);
    final assumptions = ref.watch(assumptionsProvider);
    final incomeSources = ref.watch(incomeSourcesProvider);
    final sipRestores = ref.watch(sipRestoreProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2128), width: 0.8),
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
              color: const Color(0xFF1F2128),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isInformational ? Icons.info_outline : Icons.flash_on,
                  color: isInformational ? Colors.blue : ledgerColors.success,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.suggestion.impact,
                    style: TextStyle(
                      color: isInformational ? Colors.blue : ledgerColors.success,
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

          // Simulation Expand Button (not relevant/needed for purely informational cards without changes)
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
            if (_isExpanded) ...[
              const SizedBox(height: 8),
              _buildSimulationPanel(
                context: context,
                theme: theme,
                colors: ledgerColors,
                result: simulateSuggestion(
                  suggestion: widget.suggestion,
                  profile: profile,
                  purchases: purchases,
                  goals: goals,
                  assumptions: assumptions,
                  incomeSources: incomeSources,
                  sipRestores: sipRestores,
                ),
              ),
            ],
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
                child: Text(isInformational ? 'Got it' : 'Dismiss'),
              ),
              if (!isInformational) ...[
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationPanel({
    required BuildContext context,
    required ThemeData theme,
    required LedgerColors colors,
    required SimulationResult result,
  }) {
    final hasDeficitsBefore = result.deficitYearsBefore.isNotEmpty;
    final hasDeficitsAfter = result.deficitYearsAfter.isNotEmpty;
    final resolvedDeficitsCount = result.deficitYearsBefore.length - result.deficitYearsAfter.length;

    final corpusDiff10 = result.corpusYear10After - result.corpusYear10Before;
    final corpusDiffColor = corpusDiff10 >= 0 ? colors.success : colors.high;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131418),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2128), width: 0.8),
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

          // Deficit changes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deficit Status',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (!hasDeficitsBefore)
                Text(
                  'Healthy (No Deficits) ✅',
                  style: TextStyle(color: colors.success, fontSize: 12, fontWeight: FontWeight.bold),
                )
              else if (!hasDeficitsAfter)
                Text(
                  'All Deficits Resolved! ✅',
                  style: TextStyle(color: colors.success, fontSize: 12, fontWeight: FontWeight.bold),
                )
              else if (resolvedDeficitsCount > 0)
                Text(
                  'Deficits Reduced! 📉',
                  style: TextStyle(color: colors.warning, fontSize: 12, fontWeight: FontWeight.bold),
                )
              else
                Text(
                  'No change in deficits',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (hasDeficitsBefore) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Deficit Years: Year ${result.deficitYearsBefore.join(', ')} → '
                    '${result.deficitYearsAfter.isEmpty ? 'None' : 'Year ${result.deficitYearsAfter.join(', ')}'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const Divider(color: Color(0xFF1F2128), height: 16),

          // Corpus Year 10
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '10-Year Net Worth Projection',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  Text(
                    formatCurrency(result.corpusYear10Before),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                  const Icon(Icons.arrow_right_alt, color: Colors.grey, size: 16),
                  Text(
                    formatCurrency(result.corpusYear10After),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: corpusDiffColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (corpusDiff10 != 0) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${corpusDiff10 > 0 ? '+' : ''}${formatCurrency(corpusDiff10)}',
                  style: TextStyle(
                    color: corpusDiffColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],

          // Goal impact
          if (result.goalsDelayed.isNotEmpty || result.goalsAccelerated.isNotEmpty) ...[
            const Divider(color: Color(0xFF1F2128), height: 16),
            Text(
              'Goal Timeline Impact',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            if (result.goalsAccelerated.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, color: colors.success, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Accelerated: ${result.goalsAccelerated.join(', ')}',
                      style: TextStyle(color: colors.success, fontSize: 11),
                    ),
                  ),
                ],
              ),
            if (result.goalsDelayed.isNotEmpty) ...[
              if (result.goalsAccelerated.isNotEmpty) const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_outlined, color: colors.warning, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Delayed: ${result.goalsDelayed.join(', ')}',
                      style: TextStyle(color: colors.warning, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

