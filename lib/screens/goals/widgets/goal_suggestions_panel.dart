import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/goal_suggestions_provider.dart';
import 'goal_suggestion_card.dart';

class GoalSuggestionsPanel extends ConsumerStatefulWidget {
  const GoalSuggestionsPanel({super.key});

  @override
  ConsumerState<GoalSuggestionsPanel> createState() => _GoalSuggestionsPanelState();
}

class _GoalSuggestionsPanelState extends ConsumerState<GoalSuggestionsPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = ref.watch(goalSuggestionsProvider);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

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
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Goal Recovery Suggestions',
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
                    .map((s) => GoalSuggestionCard(
                          key: Key('${s.goalId}_${s.type.name}'),
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
