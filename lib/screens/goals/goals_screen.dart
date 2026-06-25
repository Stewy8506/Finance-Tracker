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
              backgroundColor: const Color(0xFF1F2128),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
    ref.read(goalsProvider.notifier).delete(goal.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Goal "${goal.name}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              ref.read(goalsProvider.notifier).add(goal),
        ),
      ),
    );
  }

  void _showGoalSheet(BuildContext context, WidgetRef ref, Goal? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111215),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => GoalForm(existing: existing),
    );
  }
}
