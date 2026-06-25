import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../finance.dart' as finance;
import '../../models/year_projection.dart';
import '../../models/goal.dart';
import '../../models/assumptions.dart';
import '../../models/user_profile.dart';
import '../../models/recurring_purchase.dart';
import '../../models/income_source.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/projection_provider.dart';
import '../../providers/purchases_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/assumptions_provider.dart';
import '../../providers/income_provider.dart';
import '../../theme.dart';
import '../../utils/currency_formatter.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int? _tappedPieIndex;
  bool _showWaterfall = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;
    final profile = ref.watch(userProfileProvider);
    final projections = ref.watch(projectionProvider);
    final purchases = ref.watch(purchasesProvider);
    final goals = ref.watch(goalsProvider);
    final assumptions = ref.watch(assumptionsProvider);
    final incomeSources = ref.watch(incomeSourcesProvider);

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
    final techSpendMonthly = year1.techSpendAnnual / 12;
    final freeCash = year1.freeCashMonthly - techSpendMonthly;
    final takeHome = year1.totalIncome > 0 ? year1.totalIncome : year1.takeHomeMonthly;
    final hasExtraIncome = year1.additionalIncome > 0;
    final emergencyMonths = finance.emergencyFundMonths(profile);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            pinned: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Color(0xFFF4F4F6)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/settings');
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2128),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.grid_view_outlined,
                        color: Color(0xFFF4F4F6), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Dashboard',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: const Color(0xFFF4F4F6),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Net Worth summary card ───────────────────────────────
                _NetWorthCard(
                  netWorth: (projections.first.corpus) +
                      (profile.emergencyFundBalance ?? 0) +
                      (profile.otherAssets ?? 0) -
                      (profile.liabilities ?? 0),
                  emergencyFund: profile.emergencyFundBalance ?? 0,
                  otherAssets: profile.otherAssets ?? 0,
                  liabilities: profile.liabilities ?? 0,
                  investedCorpus: projections.first.corpus,
                  trendPercent: () {
                    final nw0 = (projections.first.corpus) +
                        (profile.emergencyFundBalance ?? 0) +
                        (profile.otherAssets ?? 0) -
                        (profile.liabilities ?? 0);
                    final nw1 = (projections.firstWhere((p) => p.year == 1, orElse: () => projections.first).corpus) +
                        (profile.emergencyFundBalance ?? 0) +
                        (profile.otherAssets ?? 0) -
                        (profile.liabilities ?? 0);
                    return nw0 > 0 ? ((nw1 - nw0) / nw0) * 100 : 0.0;
                  }(),
                ),
                const SizedBox(height: 12),

                // ── Quick Actions ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.flag_outlined,
                          label: 'Goals Tracker',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/goals');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Spend Planner',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/purchases');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Financial Health Score Card ──────────────────────────
                _FinancialHealthScoreCard(
                  score: finance.financialHealthScore(
                    profile,
                    assumptions,
                    goals,
                    purchases,
                    incomeSources,
                    projections,
                  ),
                  profile: profile,
                  assumptions: assumptions,
                  goals: goals,
                  purchases: purchases,
                  incomeSources: incomeSources,
                  projections: projections,
                ),
                const SizedBox(height: 16),

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
                      label: hasExtraIncome ? 'Total Income' : 'Monthly Take-Home',
                      numericValue: takeHome,
                      icon: Icons.account_balance_wallet_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    _StatCard(
                      label: 'Monthly SIP',
                      numericValue: sip,
                      icon: Icons.trending_up,
                      color: colors.success,
                    ),
                    _StatCard(
                      label: 'Free Cash / Month',
                      numericValue: freeCash > 0 ? freeCash : 0,
                      icon: Icons.savings_outlined,
                      color: colors.warning,
                    ),
                    _StatCard(
                      label: 'Corpus at Year 5',
                      numericValue: year5.corpus,
                      isLakhsCrores: true,
                      icon: Icons.auto_graph,
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Emergency fund card ─────────────────────────────────
                _EmergencyFundCard(
                  balance: profile.emergencyFundBalance ?? 0,
                  coverageMonths: emergencyMonths,
                  onUpdate: () => _showEmergencyFundDialog(context, ref, profile),
                ),
                const SizedBox(height: 24),

                 // ── Monthly budget pie chart ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionHeader('Monthly Budget'),
                    Row(
                      children: [
                         ChoiceChip(
                          label: const Text('Pie'),
                          selected: !_showWaterfall,
                          onSelected: (val) {
                            if (val) {
                              HapticFeedback.lightImpact();
                              setState(() => _showWaterfall = false);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Waterfall'),
                          selected: _showWaterfall,
                          onSelected: (val) {
                            if (val) {
                              HapticFeedback.lightImpact();
                              setState(() => _showWaterfall = true);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_showWaterfall)
                  _BudgetPieChart(
                    expenses: expenses,
                    sip: sip,
                    purchases: techSpendMonthly,
                    freeCash: freeCash > 0 ? freeCash : 0,
                    total: takeHome,
                    tappedIndex: _tappedPieIndex,
                    onTap: (i) =>
                        setState(() => _tappedPieIndex = i == _tappedPieIndex ? null : i),
                  )
                else
                  _CashFlowWaterfall(
                    takeHome: takeHome,
                    expenses: expenses,
                    sip: sip,
                    purchases: techSpendMonthly,
                    freeCash: freeCash > 0 ? freeCash : 0,
                  ),
                const SizedBox(height: 24),

                // ── Spend calendar ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionHeader("This Year's Spend Calendar"),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.push('/purchases');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        children: [
                          Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF818CF8), fontWeight: FontWeight.w700)),
                          Icon(Icons.chevron_right, size: 16, color: Color(0xFF818CF8)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SpendCalendar(purchases: purchases),
                const SizedBox(height: 24),

                // ── Milestone card ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionHeader('Next Milestone'),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.push('/goals');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        children: [
                          Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF818CF8), fontWeight: FontWeight.w700)),
                          Icon(Icons.chevron_right, size: 16, color: Color(0xFF818CF8)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MilestoneCard(
                  projections: projections,
                  goals: goals,
                  assumptions: assumptions,
                  profile: profile,
                  purchases: purchases,
                  incomeSources: incomeSources,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyFundDialog(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    final ctrl = TextEditingController(
        text: (profile.emergencyFundBalance ?? 0).toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Emergency Fund'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Current Balance',
            prefixText: '₹ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && val >= 0) {
                ref.read(userProfileProvider.notifier).save(
                      profile.copyWith(emergencyFundBalance: val),
                    );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
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
  final double numericValue;
  final bool isLakhsCrores;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.numericValue,
    this.isLakhsCrores = false,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111215),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2128),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey(numericValue),
                tween: Tween<double>(begin: 0, end: numericValue),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, val, child) {
                  final formatted = isLakhsCrores
                      ? formatLakhsCrores(val)
                      : formatCurrency(val);
                  return Text(
                    formatted,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: theme.textTheme.bodySmall),
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
  final double purchases;
  final double freeCash;
  final double total;
  final int? tappedIndex;
  final ValueChanged<int> onTap;

  const _BudgetPieChart({
    required this.expenses,
    required this.sip,
    required this.purchases,
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
      _PieSegment('Purchases', purchases, colors.warning),
      _PieSegment('Free Cash', freeCash, colors.success),
    ];

    final tapped = tappedIndex != null && tappedIndex! < segments.length
        ? segments[tappedIndex!]
        : null;

    return Container(
      height: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111215),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF1F2128)),
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
                          if (idx != null) {
                            HapticFeedback.lightImpact();
                            onTap(idx);
                          }
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
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTap(i);
                    },
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

    final purchasesList = widget.purchases.cast<RecurringPurchase>();

    // Group purchases by month deterministically based on p.id hash
    final purchasesByMonth = List.generate(12, (_) => <RecurringPurchase>[]);
    for (final p in purchasesList) {
      if (p.firstYear == 1 && p.targetMonth != null) {
        purchasesByMonth[p.targetMonth!].add(p);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            itemBuilder: (context, i) {
              final hasDot = purchasesByMonth[i].isNotEmpty;
              final isSelected = _tappedMonth == i;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _tappedMonth = isSelected ? null : i;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1F2128)
                        : const Color(0xFF111215),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF4F4F6)
                          : const Color(0xFF1F2128),
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
        ),
        if (_tappedMonth != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111215),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1F2128)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planned Spend in ${months[_tappedMonth!]} (Year 1)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                if (purchasesByMonth[_tappedMonth!].isEmpty)
                  Text(
                    'No planned purchases this month.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFFA0A0A0)),
                  )
                else
                  ...purchasesByMonth[_tappedMonth!].map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBBF24),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)),
                                    if (p.note != null && p.note!.isNotEmpty)
                                      Text(p.note!,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                              color: const Color(0xFFA0A0A0))),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              formatCurrency(p.amount),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ],
      ],
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
  final List<dynamic> incomeSources;

  const _MilestoneCard({
    required this.projections,
    required this.goals,
    required this.assumptions,
    required this.profile,
    required this.purchases,
    this.incomeSources = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;

    if (goals.isEmpty) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/goals');
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111215),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1F2128)),
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
    int fundedYear = 0;
    for (final p in projections) {
      if (p.fundedGoalIds.contains(goal.id)) {
        fundedYear = p.year;
        break;
      }
    }
    final startYear = profile.startYear ?? DateTime.now().year;
    final fundedLabel = fundedYear > 0
        ? 'by ${startYear + fundedYear}'
        : '30+ yrs';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/goals');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
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
                    color: const Color(0xFF1F2128),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fundedLabel,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMERGENCY FUND CARD
// ─────────────────────────────────────────────────────────────────────────────
class _EmergencyFundCard extends StatelessWidget {
  final double balance;
  final double coverageMonths;
  final VoidCallback onUpdate;

  const _EmergencyFundCard({
    required this.balance,
    required this.coverageMonths,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;

    // Color coding: red < 3 months, amber 3–6, green 6+
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;
    if (coverageMonths >= 6) {
      statusColor = colors.success;
      statusLabel = 'Healthy';
      statusIcon = Icons.check_circle_outline;
    } else if (coverageMonths >= 3) {
      statusColor = colors.warning;
      statusLabel = 'Building';
      statusIcon = Icons.warning_amber_outlined;
    } else {
      statusColor = colors.high;
      statusLabel = 'Critical';
      statusIcon = Icons.error_outline;
    }

    // Progress toward 6-month target
    final progress = (coverageMonths / 6.0).clamp(0.0, 1.0);

    return Container(
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2128),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shield_outlined, color: statusColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergency Fund',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                    Text(
                      '${coverageMonths.toStringAsFixed(1)} months covered',
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2128),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance: ${formatCurrency(balance)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Target: 6 months',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFF1F2128),
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onUpdate();
              },
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('Update', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  final double netWorth;
  final double emergencyFund;
  final double otherAssets;
  final double liabilities;
  final double investedCorpus;
  final double trendPercent;

  const _NetWorthCard({
    required this.netWorth,
    required this.emergencyFund,
    required this.otherAssets,
    required this.liabilities,
    required this.investedCorpus,
    required this.trendPercent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111215),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NET WORTH',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFA0A0A0),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  )),
              Tooltip(
                triggerMode: TooltipTriggerMode.tap,
                richMessage: TextSpan(
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  children: [
                    const TextSpan(text: 'Net Worth Breakdown:\n\n', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                    TextSpan(text: '• Invested Corpus: ${formatCurrency(investedCorpus)}\n'),
                    TextSpan(text: '• Emergency Fund: ${formatCurrency(emergencyFund)}\n'),
                    TextSpan(text: '• Other Assets: ${formatCurrency(otherAssets)}\n'),
                    TextSpan(text: '• Liabilities: -${formatCurrency(liabilities)}\n', style: TextStyle(color: colors.high, fontWeight: FontWeight.w600)),
                  ],
                ),
                child: const Icon(Icons.info_outline, size: 16, color: Color(0xFFA0A0A0)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatCurrency(netWorth),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Icon(
                    trendPercent >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: trendPercent >= 0 ? colors.success : colors.high,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${trendPercent >= 0 ? '+' : ''}${trendPercent.toStringAsFixed(1)}% (1-yr proj)',
                    style: TextStyle(
                      color: trendPercent >= 0 ? colors.success : colors.high,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

class _FinancialHealthScoreCard extends StatelessWidget {
  final int score;
  final UserProfile profile;
  final Assumptions assumptions;
  final List<Goal> goals;
  final List<RecurringPurchase> purchases;
  final List<IncomeSource> incomeSources;
  final List<YearProjection> projections;

  const _FinancialHealthScoreCard({
    required this.score,
    required this.profile,
    required this.assumptions,
    required this.goals,
    required this.purchases,
    required this.incomeSources,
    required this.projections,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;

    final Color statusColor;
    if (score >= 70) {
      statusColor = colors.success;
    } else if (score >= 40) {
      statusColor = colors.warning;
    } else {
      statusColor = colors.high;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showBreakdownDialog(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111215),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2128)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FINANCIAL HEALTH SCORE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFA0A0A0),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    'Your score is $score/100',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to view recommendations & breakdown',
                    style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 5,
                    backgroundColor: const Color(0xFF1F2128),
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                  Text(
                    '$score',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBreakdownDialog(BuildContext context) {
    final colors = Theme.of(context).extension<LedgerColors>()!;

    final year1 = projections.firstWhere((p) => p.year == 1, orElse: () => projections.first);
    final takeHome = year1.totalIncome > 0 ? year1.totalIncome : year1.takeHomeMonthly;
    final expenses = year1.expensesMonthly;

    final sipPct = profile.sipRatePct * 100;
    final sipPoints = sipPct >= 15 ? 25 : (sipPct >= 10 ? 15 : 5);

    final efMonths = finance.emergencyFundMonths(profile);
    final efPoints = efMonths >= 6 ? 20 : (efMonths >= 3 ? 12 : 5);

    final expRatio = takeHome > 0 ? (expenses / takeHome) : 1.0;
    final expPoints = expRatio < 0.40 ? 20 : (expRatio <= 0.60 ? 12 : 5);

    int goalPoints = 20;
    int onTrackCount = 0;
    if (goals.isNotEmpty) {
      for (final g in goals) {
        int fundedYear = 0;
        for (final p in projections) {
          if (p.fundedGoalIds.contains(g.id)) {
            fundedYear = p.year;
            break;
          }
        }
        if (fundedYear > 0 && fundedYear <= g.targetYear) {
          onTrackCount++;
        }
      }
      final ratio = onTrackCount / goals.length;
      goalPoints = ratio == 1.0 ? 20 : (ratio >= 0.5 ? 10 : 5);
    }

    int growthPoints = 5;
    final ctcYear1 = year1.ctcLpa * 100000;
    final corpusYear10 = projections.firstWhere((p) => p.year == 10, orElse: () => projections.last).corpus;
    if (ctcYear1 > 0) {
      final multiple = corpusYear10 / ctcYear1;
      growthPoints = multiple >= 5.0 ? 15 : (multiple >= 2.0 ? 10 : 5);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Financial Health Score'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreakdownRow('SIP Savings Rate', '$sipPoints/25', 'Target: 15%+', sipPoints >= 25 ? colors.success : colors.warning),
              _buildBreakdownRow('Emergency Fund', '$efPoints/20', 'Target: 6+ months', efPoints >= 20 ? colors.success : colors.warning),
              _buildBreakdownRow('Expense Ratio', '$expPoints/20', 'Target: <40% of income', expPoints >= 20 ? colors.success : colors.warning),
              _buildBreakdownRow('Goal Feasibility', '$goalPoints/20', 'Target: All goals on-track', goalPoints >= 20 ? colors.success : colors.warning),
              _buildBreakdownRow('10-Yr Corpus Growth', '$growthPoints/15', 'Target: >5x starting CTC', growthPoints >= 15 ? colors.success : colors.warning),
              const Divider(height: 24),
              const Text(
                'Recommendations:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              if (sipPoints < 25) const Text('• Increase your SIP rate to at least 15% to accelerate wealth growth.', style: TextStyle(fontSize: 12)),
              if (efPoints < 20) const Text('• Build your Emergency Fund up to at least 6 months of expenses.', style: TextStyle(fontSize: 12)),
              if (expPoints < 20) const Text('• Cut back on discretionary expenses to keep the expense ratio under 40%.', style: TextStyle(fontSize: 12)),
              if (goalPoints < 20) const Text('• Some goals are delayed. Consider delaying targets or increasing monthly SIP.', style: TextStyle(fontSize: 12)),
              if (growthPoints < 15) const Text('• Boost career hikes or add side incomes to exceed 5x CTC in 10 years.', style: TextStyle(fontSize: 12)),
              if (sipPoints >= 25 && efPoints >= 20 && expPoints >= 20 && goalPoints >= 20 && growthPoints >= 15)
                const Text('• You are in top financial shape! Keep tracking and compounding.', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String title, String points, String target, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Text(target, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          Text(points, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CashFlowWaterfall extends StatelessWidget {
  final double takeHome;
  final double expenses;
  final double sip;
  final double purchases;
  final double freeCash;

  const _CashFlowWaterfall({
    required this.takeHome,
    required this.expenses,
    required this.sip,
    required this.purchases,
    required this.freeCash,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;

    final items = [
      _WaterfallItem('Take-Home', takeHome, Colors.blueGrey, isTotal: true),
      _WaterfallItem('Expenses', expenses, colors.high),
      _WaterfallItem('SIP', sip, theme.colorScheme.primary),
      _WaterfallItem('Purchases', purchases, colors.warning),
      _WaterfallItem('Free Cash', freeCash > 0 ? freeCash : 0.0, colors.success),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111215),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          final pct = takeHome > 0 ? (item.amount / takeHome * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: item.isTotal ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      '${formatCurrency(item.amount)} (${pct.toStringAsFixed(0)}%)',
                      style: TextStyle(
                        color: item.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: (pct / 100).clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF1F2128),
                        valueColor: AlwaysStoppedAnimation(item.color),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WaterfallItem {
  final String label;
  final double amount;
  final Color color;
  final bool isTotal;

  _WaterfallItem(this.label, this.amount, this.color, {this.isTotal = false});
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF111215),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2128), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF818CF8), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFFF4F4F6),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
