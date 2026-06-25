import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../finance.dart' as finance;
import '../../../models/goal.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/purchases_provider.dart';
import '../../../providers/assumptions_provider.dart';
import '../../../theme.dart';
import '../../../utils/currency_formatter.dart';

class GoalCard extends ConsumerWidget {
  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GoalCard({
    super.key,
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
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E2E2E)),
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
                    color: const Color(0xFF262626),
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
                InfoChip(
                    icon: Icons.attach_money,
                    label: formatLakhsCrores(goal.targetAmount),
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                InfoChip(
                    icon: Icons.calendar_today,
                    label: 'Year ${goal.targetYear}',
                    color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                InfoChip(
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
                    child: DetailRow(
                      'Property Value',
                      formatLakhsCrores(goal.propertyValue ?? 0),
                    ),
                  ),
                  Expanded(
                    child: DetailRow(
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
                    child: DetailRow('EMI (est.)', formatCurrency(emi)),
                  ),
                  Expanded(
                    child: DetailRow(
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

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
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

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow(this.label, this.value, {super.key});

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
