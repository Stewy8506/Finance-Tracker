import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../finance.dart' as finance;
import '../../../models/goal.dart';
import '../../../models/assumptions.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/assumptions_provider.dart';
import '../../../providers/projection_provider.dart';
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

    final assumptions = ref.watch(assumptionsProvider);
    final projections = ref.watch(projectionProvider);

    final priorityColor = goal.priority == 'high'
        ? colors.high
        : goal.priority == 'medium'
            ? colors.warning
            : colors.success;

    int fundedYear = 0;
    for (final p in projections) {
      if (p.fundedGoalIds.contains(goal.id)) {
        fundedYear = p.year;
        break;
      }
    }
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
      onDismissed: (_) {
        onDelete();
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
          color: const Color(0xFF111215),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2128)),
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
                    color: const Color(0xFF1F2128),
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
            const SizedBox(height: 12),
            _GoalSparkline(
              goal: goal,
              projections: projections,
              assumptions: assumptions,
              colors: colors,
              primaryColor: theme.colorScheme.primary,
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
        color: const Color(0xFF1F2128),
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

class _GoalSparkline extends StatelessWidget {
  final Goal goal;
  final List<dynamic> projections;
  final Assumptions assumptions;
  final LedgerColors colors;
  final Color primaryColor;

  const _GoalSparkline({
    required this.goal,
    required this.projections,
    required this.assumptions,
    required this.colors,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (projections.isEmpty) return const SizedBox.shrink();

    final corpusSpots = projections.map((p) {
      return FlSpot(p.year.toDouble(), p.corpus / 100000);
    }).toList();

    final targetSpots = projections.map((p) {
      final targetAtYear = goal.adjustForInflation == true
          ? goal.targetAmount * math.pow(1 + assumptions.expenseInflation, p.year)
          : goal.targetAmount;
      return FlSpot(p.year.toDouble(), targetAtYear / 100000);
    }).toList();

    int intersectionYear = 0;
    for (final p in projections) {
      final targetAtYear = goal.adjustForInflation == true
          ? goal.targetAmount * math.pow(1 + assumptions.expenseInflation, p.year)
          : goal.targetAmount;
      if (p.corpus >= targetAtYear) {
        intersectionYear = p.year;
        break;
      }
    }

    final maxCorpus = corpusSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final maxTarget = targetSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final maxY = math.max(maxCorpus, maxTarget) * 1.1;

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 20,
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            // Target Curve
            LineChartBarData(
              spots: targetSpots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: colors.success.withValues(alpha: 0.5),
              barWidth: 1.5,
              dashArray: [4, 4],
              dotData: const FlDotData(show: false),
            ),
            // Corpus Curve
            LineChartBarData(
              spots: corpusSpots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: primaryColor,
              barWidth: 2,
              dotData: FlDotData(
                show: intersectionYear > 0,
                checkToShowDot: (spot, _) => spot.x.toInt() == intersectionYear,
                getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                  radius: 3.5,
                  color: colors.success,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
