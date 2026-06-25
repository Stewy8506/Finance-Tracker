import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/suggestion.dart';
import '../../../models/recurring_purchase.dart';
import '../../../models/sip_restore.dart';
import '../../../models/suggestion_history.dart';
import '../../../providers/suggestions_provider.dart';
import '../../../providers/purchases_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/sip_restore_provider.dart';
import '../../../providers/suggestion_history_provider.dart';
import '../../../suggestion_engine.dart';
import 'suggestion_card.dart';

class SuggestionsPanel extends ConsumerStatefulWidget {
  const SuggestionsPanel({super.key});

  @override
  ConsumerState<SuggestionsPanel> createState() => _SuggestionsPanelState();
}

class _SuggestionsPanelState extends ConsumerState<SuggestionsPanel> {
  bool _isExpanded = true;

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

  void _applyAll(BuildContext context, List<Suggestion> actionable) async {
    final purchases = ref.read(purchasesProvider);
    final previousPurchases = <String, RecurringPurchase>{};
    final profile = ref.read(userProfileProvider);
    final previousSipRate = profile?.sipRatePct;

    final updatedPurchases = <String, RecurringPurchase>{};
    double? newSipRate;
    int? newSipRestoreYear;

    // Flatten combos to their child suggestions
    final flattenedActionable = <Suggestion>[];
    for (final s in actionable) {
      if (s.type == SuggestionType.combo && s.comboChildren != null) {
        flattenedActionable.addAll(s.comboChildren!);
      } else {
        flattenedActionable.add(s);
      }
    }

    for (final s in flattenedActionable) {
      if (s.type == SuggestionType.reduceSip) {
        newSipRate = s.suggestedSipPct;
        newSipRestoreYear = s.sipRestoreYear;
      } else {
        final p = purchases.firstWhere((p) => p.id == s.purchaseId, orElse: () => purchases.first);
        if (!previousPurchases.containsKey(p.id)) {
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

        final current = updatedPurchases[p.id] ?? p;
        final updatedP = cloneAndApplySuggestion(current, s);
        updatedPurchases[p.id] = updatedP;
      }
    }

    // Apply updates
    if (updatedPurchases.isNotEmpty) {
      await ref.read(purchasesProvider.notifier).addAll(updatedPurchases.values.toList());
    }

    if (newSipRate != null && profile != null) {
      await ref.read(userProfileProvider.notifier).update((p) => p.copyWith(
        sipRatePct: newSipRate,
      ));
      if (newSipRestoreYear != null && previousSipRate != null) {
        final restore = SipRestore(
          originalSipPct: previousSipRate,
          restoreYear: newSipRestoreYear,
        );
        await ref.read(sipRestoreProvider.notifier).add(restore);
      }
    }

    // Log to history
    for (final s in actionable) {
      final historyEntry = SuggestionHistoryEntry(
        suggestionTitle: s.title,
        type: s.type.name,
        impactScore: s.impactScore,
        appliedAt: DateTime.now(),
        cashFlowImpact: _parseCashFlowImpact(s.impact),
      );
      await ref.read(suggestionHistoryProvider.notifier).add(historyEntry);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text('Applied ${actionable.length} suggestions'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Theme.of(context).colorScheme.primary,
            onPressed: () async {
              if (previousPurchases.isNotEmpty) {
                await ref.read(purchasesProvider.notifier).addAll(previousPurchases.values.toList());
              }
              if (newSipRate != null && previousSipRate != null) {
                await ref.read(userProfileProvider.notifier).update((p) => p.copyWith(
                  sipRatePct: previousSipRate,
                ));
                await ref.read(sipRestoreProvider.notifier).clearAll();
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = ref.watch(suggestionsProvider);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final actionable = suggestions.where((s) =>
      s.type != SuggestionType.opportunityCost &&
      s.type != SuggestionType.skipAndInvest
    ).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111215),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2128), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              key: const Key('smart_suggestions_header'),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '✨',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Smart Suggestions',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${suggestions.length}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (actionable.isNotEmpty) ...[
                    FilledButton.icon(
                      onPressed: () => _applyAll(context, actionable),
                      icon: const Icon(Icons.done_all, size: 14),
                      label: const Text('Apply All', style: TextStyle(fontSize: 11)),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: const Color(0xFF08090A),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: suggestions
                    .map((s) => SuggestionCard(
                          key: Key('${s.purchaseId}_${s.type.name}'),
                          suggestion: s,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

