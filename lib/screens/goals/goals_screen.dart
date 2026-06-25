import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/goal.dart';
import '../../providers/goals_provider.dart';
import 'widgets/empty_goals.dart';
import 'widgets/goal_card.dart';
import 'widgets/goal_form.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text('${goals.length} goals'),
              backgroundColor: const Color(0xFF262626),
              labelStyle: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGoalSheet(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
      ),
      body: goals.isEmpty
          ? EmptyGoals(onAdd: () => _showGoalSheet(context, ref, null))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: goals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => GoalCard(
                goal: goals[i],
                onEdit: () => _showGoalSheet(context, ref, goals[i]),
                onDelete: () => _deleteGoal(context, ref, goals[i]),
              ),
            ),
    );
  }

  Future<void> _deleteGoal(
      BuildContext context, WidgetRef ref, Goal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "${goal.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(goalsProvider.notifier).delete(goal.id);
    }
  }

  void _showGoalSheet(BuildContext context, WidgetRef ref, Goal? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => GoalForm(existing: existing),
    );
  }
}
