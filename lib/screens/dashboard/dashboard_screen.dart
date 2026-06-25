import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../finance.dart' as finance;
import '../../models/year_projection.dart';
import '../../models/goal.dart';
import '../../models/assumptions.dart';
import '../../models/user_profile.dart';
import '../../models/recurring_purchase.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/projection_provider.dart';
import '../../providers/purchases_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/assumptions_provider.dart';
import '../../theme.dart';
import '../../utils/currency_formatter.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int? _tappedPieIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;
    final profile = ref.watch(userProfileProvider);
    final projections = ref.watch(projectionProvider);
    final purchases = ref.watch(purchasesProvider);
    final goals = ref.watch(goalsProvider);
    final assumptions = ref.watch(assumptionsProvider);

    if (profile == null || projections.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final year1 = projections.firstWhere((p) => p.year == 1,
        orElse: () => projections.first);
    final year5 = projections.firstWhere((p) => p.year == 5,
        orElse: () => projections.last);

    final expenses = year1.expensesMonthly;
    final sip = year1.sipMonthly;
    final freeCash = year1.freeCashMonthly;
    final takeHome = year1.takeHomeMonthly;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Ledger',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── 4 stat cards ──────────────────────────────────────────
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      label: 'Monthly Take-Home',
                      value: formatCurrency(takeHome),
                      icon: Icons.account_balance_wallet_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    _StatCard(
                      label: 'Monthly SIP',
                      value: formatCurrency(sip),
                      icon: Icons.trending_up,
                      color: colors.success,
                    ),
                    _StatCard(
                      label: 'Free Cash / Month',
                      value: formatCurrency(freeCash > 0 ? freeCash : 0),
                      icon: Icons.savings_outlined,
                      color: colors.warning,
                    ),
                    _StatCard(
                      label: 'Corpus at Year 5',
                      value: formatLakhsCrores(year5.corpus),
                      icon: Icons.auto_graph,
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Monthly budget pie chart ───────────────────────────────
                _SectionHeader('Monthly Budget'),
                const SizedBox(height: 12),
                _BudgetPieChart(
                  expenses: expenses,
                  sip: sip,
                  freeCash: freeCash > 0 ? freeCash : 0,
                  total: takeHome,
                  tappedIndex: _tappedPieIndex,
                  onTap: (i) =>
                      setState(() => _tappedPieIndex = i == _tappedPieIndex ? null : i),
                ),
                const SizedBox(height: 24),

                // ── Spend calendar ─────────────────────────────────────────
                _SectionHeader('This Year\'s Spend Calendar'),
                const SizedBox(height: 12),
                _SpendCalendar(purchases: purchases),
                const SizedBox(height: 24),

                // ── Milestone card ─────────────────────────────────────────
                _SectionHeader('Next Milestone'),
                const SizedBox(height: 12),
                _MilestoneCard(
                  projections: projections,
                  goals: goals,
                  assumptions: assumptions,
                  profile: profile,
                  purchases: purchases,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E2E),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
              const SizedBox(height: 2),
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: color.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUDGET PIE CHART
// ─────────────────────────────────────────────────────────────────────────────
class _BudgetPieChart extends StatelessWidget {
  final double expenses;
  final double sip;
  final double freeCash;
  final double total;
  final int? tappedIndex;
  final ValueChanged<int> onTap;

  const _BudgetPieChart({
    required this.expenses,
    required this.sip,
    required this.freeCash,
    required this.total,
    required this.tappedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;

    final segments = [
      _PieSegment('Expenses', expenses, colors.high),
      _PieSegment('SIP', sip, theme.colorScheme.primary),
      _PieSegment('Free Cash', freeCash, colors.success),
    ];

    final tapped = tappedIndex != null && tappedIndex! < segments.length
        ? segments[tappedIndex!]
        : null;

    return Container(
      height: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 54,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (event is FlTapUpEvent) {
                          final idx = response
                              ?.touchedSection?.touchedSectionIndex;
                          if (idx != null) onTap(idx);
                        }
                      },
                    ),
                    sections: segments.asMap().entries.map((e) {
                      final i = e.key;
                      final s = e.value;
                      final isSelected = tappedIndex == i;
                      return PieChartSectionData(
                        value: s.amount,
                        color: s.color,
                        radius: isSelected ? 60 : 52,
                        title: '',
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tapped != null
                          ? formatCurrency(tapped.amount)
                          : formatCurrency(total),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      tapped != null
                          ? '${(tapped.amount / total * 100).toStringAsFixed(0)}%'
                          : 'Total',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (tapped != null)
                      Text(
                        tapped.label,
                        style: TextStyle(
                            color: tapped.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: segments.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final pct =
                    total > 0 ? s.amount / total * 100 : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.label,
                                  style: theme.textTheme.bodySmall),
                              Text(
                                '${pct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: s.color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PieSegment {
  final String label;
  final double amount;
  final Color color;
  const _PieSegment(this.label, this.amount, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// SPEND CALENDAR
// ─────────────────────────────────────────────────────────────────────────────
class _SpendCalendar extends StatefulWidget {
  final List purchases;

  const _SpendCalendar({required this.purchases});

  @override
  State<_SpendCalendar> createState() => _SpendCalendarState();
}

class _SpendCalendarState extends State<_SpendCalendar> {
  int? _tappedMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    // Year 1 purchases occur in first year — show them spread across calendar
    // For simplicity, show all year-1 purchases on month 1 and recurring on month 1
    final hasPurchaseInYear1 = widget.purchases.isNotEmpty;

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (context, i) {
          // Show dot for month 1 (first purchase month) and every 3rd month for recurring
          final hasDot = hasPurchaseInYear1 && (i == 0 || i == 2 || i == 5 || i == 8 || i == 11);
          final isSelected = _tappedMonth == i;

          return GestureDetector(
            onTap: () => setState(() {
              _tappedMonth = isSelected ? null : i;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                    : const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : const Color(0xFF2D2D42),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(months[i],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : null,
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      )),
                  const SizedBox(height: 6),
                  if (hasDot)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  else
                    const SizedBox(height: 7),
                  if (isSelected && hasDot)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Spend',
                        style: TextStyle(
                          fontSize: 9,
                          color: const Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MILESTONE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _MilestoneCard extends StatelessWidget {
  final List<YearProjection> projections;
  final List<Goal> goals;
  final Assumptions assumptions;
  final UserProfile profile;
  final List<RecurringPurchase> purchases;

  const _MilestoneCard({
    required this.projections,
    required this.goals,
    required this.assumptions,
    required this.profile,
    required this.purchases,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;

    if (goals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2D2D42)),
        ),
        child: Row(
          children: [
            Icon(Icons.flag_outlined,
                color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Text('Add a goal to see your next milestone.',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    // Find next unfunded goal
    final currentCorpus =
        projections.isNotEmpty ? projections.last.corpus : 0.0;
    final goal = goals.first;
    final progress =
        currentCorpus > 0 && goal.targetAmount > 0
            ? (currentCorpus / goal.targetAmount).clamp(0.0, 1.0)
            : 0.0;
    final fundedYear = finance.yearsToGoal(
        goal, profile, purchases, assumptions);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.high.withValues(alpha: 0.08),
            theme.colorScheme.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.high.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: colors.high, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (fundedYear > 0 && fundedYear <= goal.targetYear
                          ? colors.success
                          : colors.high)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  fundedYear > 0
                      ? 'Year $fundedYear'
                      : '30+ yrs',
                  style: TextStyle(
                    color: fundedYear > 0 && fundedYear <= goal.targetYear
                        ? colors.success
                        : colors.high,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target: ${formatLakhsCrores(goal.targetAmount)}',
                  style: theme.textTheme.bodySmall),
              Text(
                  '${(progress * 100).toStringAsFixed(0)}% funded',
                  style:
                      TextStyle(color: colors.success, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? colors.success : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
