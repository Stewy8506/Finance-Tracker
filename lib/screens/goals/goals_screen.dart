import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../finance.dart' as finance;
import '../../models/goal.dart';
import '../../providers/goals_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/purchases_provider.dart';
import '../../providers/assumptions_provider.dart';
import '../../theme.dart';
import '../../utils/currency_formatter.dart';

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
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
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
          ? _EmptyGoals(onAdd: () => _showGoalSheet(context, ref, null))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: goals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _GoalCard(
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
                backgroundColor: const Color(0xFFF87171)),
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
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _GoalForm(existing: existing),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOAL CARD
// ─────────────────────────────────────────────────────────────────────────────
class _GoalCard extends ConsumerWidget {
  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;
    final profile = ref.watch(userProfileProvider);
    final purchases = ref.watch(purchasesProvider);
    final assumptions = ref.watch(assumptionsProvider);

    final priorityColor = goal.priority == 'high'
        ? colors.high
        : goal.priority == 'medium'
            ? colors.warning
            : colors.success;

    final fundedYear = profile != null
        ? finance.yearsToGoal(goal, profile, purchases, assumptions)
        : 0;
    final onTrack = fundedYear > 0 && fundedYear <= goal.targetYear;

    // EMI calc for down_payment goals
    double? emi;
    double? emiPct;
    if (goal.type == 'down_payment' &&
        goal.propertyValue != null &&
        goal.downPaymentPct != null &&
        profile != null) {
      final loanAmount =
          goal.propertyValue! * (1 - goal.downPaymentPct!);
      emi = finance.monthlyEmi(
          loanAmount, assumptions.homeLoanRate, assumptions.loanTenureYears);
      final takeHomeAtTarget = finance.calculateTakeHome(
        profile.startingCtcLpa *
            (1 + profile.annualHikePct) * goal.targetYear,
        profile.taxRegime,
      );
      emiPct = takeHomeAtTarget > 0 ? emi / takeHomeAtTarget : 0;
    }

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.high.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: colors.high),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: priorityColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    goal.priority.toUpperCase(),
                    style: TextStyle(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onEdit,
                  child: Icon(Icons.edit_outlined,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                    icon: Icons.attach_money,
                    label: formatLakhsCrores(goal.targetAmount),
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                _InfoChip(
                    icon: Icons.calendar_today,
                    label: 'Year ${goal.targetYear}',
                    color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: onTrack ? Icons.check_circle : Icons.warning_amber,
                  label: fundedYear > 0 ? 'Funded: Yr $fundedYear' : '30+ yrs',
                  color: onTrack ? colors.success : colors.high,
                ),
              ],
            ),
            // Down payment extras
            if (goal.type == 'down_payment' && emi != null) ...[
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _DetailRow(
                      'Property Value',
                      formatLakhsCrores(goal.propertyValue ?? 0),
                    ),
                  ),
                  Expanded(
                    child: _DetailRow(
                      'Down Payment',
                      '${((goal.downPaymentPct ?? 0.2) * 100).toInt()}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _DetailRow('EMI (est.)', formatCurrency(emi)),
                  ),
                  Expanded(
                    child: _DetailRow(
                      'EMI % of take-home',
                      '${((emiPct ?? 0) * 100).toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOAL FORM (bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────
class _GoalForm extends ConsumerStatefulWidget {
  final Goal? existing;

  const _GoalForm({this.existing});

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _propertyValueCtrl;
  late final TextEditingController _dpPctCtrl;

  String _type = 'purchase';
  String _priority = 'high';

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _amountCtrl = TextEditingController(
        text: g?.targetAmount.toInt().toString() ?? '');
    _yearCtrl =
        TextEditingController(text: g?.targetYear.toString() ?? '5');
    _propertyValueCtrl = TextEditingController(
        text: g?.propertyValue?.toInt().toString() ?? '');
    _dpPctCtrl = TextEditingController(
        text: ((g?.downPaymentPct ?? 0.2) * 100).toInt().toString());
    _type = g?.type ?? 'purchase';
    _priority = g?.priority ?? 'high';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _yearCtrl.dispose();
    _propertyValueCtrl.dispose();
    _dpPctCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final goal = Goal(
      id: widget.existing?.id ?? _uuid.v4(),
      name: _nameCtrl.text,
      targetAmount: double.parse(_amountCtrl.text),
      targetYear: int.parse(_yearCtrl.text),
      type: _type,
      priority: _priority,
      propertyValue: _type == 'down_payment'
          ? double.tryParse(_propertyValueCtrl.text)
          : null,
      downPaymentPct: _type == 'down_payment'
          ? (double.tryParse(_dpPctCtrl.text) ?? 20) / 100
          : null,
    );

    if (widget.existing != null) {
      ref.read(goalsProvider.notifier).update(goal);
    } else {
      ref.read(goalsProvider.notifier).add(goal);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.existing != null ? 'Edit Goal' : 'New Goal',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Goal Name'),
                validator: (v) =>
                    v?.isEmpty == true ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              // Type
              Text('Type', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['purchase', 'down_payment', 'corpus'].map((t) {
                  final labels = {
                    'purchase': 'Purchase',
                    'down_payment': 'Down Payment',
                    'corpus': 'Corpus Target',
                  };
                  return ChoiceChip(
                    label: Text(labels[t]!),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_type == 'down_payment') ...[
                TextFormField(
                  controller: _propertyValueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Property Value (₹)',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dpPctCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Down Payment %',
                    suffixText: '%',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Amount (₹)',
                  prefixText: '₹ ',
                ),
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Enter amount' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yearCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Year (from now)',
                  suffixText: 'years',
                ),
                validator: (v) =>
                    int.tryParse(v ?? '') == null ? 'Enter year' : null,
              ),
              const SizedBox(height: 16),
              // Priority
              Text('Priority', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                children:
                    ['high', 'medium', 'low'].map((p) {
                  final colors = {
                    'high': const Color(0xFFF87171),
                    'medium': const Color(0xFFFBBF24),
                    'low': const Color(0xFF34D399),
                  };
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p.toUpperCase()),
                      selected: _priority == p,
                      selectedColor: colors[p]!.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _priority = p),
                      labelStyle: TextStyle(
                        color: _priority == p ? colors[p] : null,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.existing != null ? 'Save Changes' : 'Add Goal',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyGoals extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyGoals({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No goals yet', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Add your first financial goal to get started.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Goal'),
          ),
        ],
      ),
    );
  }
}
