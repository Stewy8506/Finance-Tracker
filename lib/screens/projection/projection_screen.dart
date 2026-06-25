import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../finance.dart' as finance;
import '../../providers/projection_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/purchases_provider.dart';
import '../../providers/assumptions_provider.dart';
import '../../theme.dart';
import '../../utils/currency_formatter.dart';

class ProjectionScreen extends ConsumerStatefulWidget {
  const ProjectionScreen({super.key});

  @override
  ConsumerState<ProjectionScreen> createState() => _ProjectionScreenState();
}

class _ProjectionScreenState extends ConsumerState<ProjectionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projection'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Corpus'),
            Tab(text: 'Year-by-Year'),
            Tab(text: 'What-If'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CorpusTab(),
          _TableTab(),
          _WhatIfTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: CORPUS LINE CHART
// ─────────────────────────────────────────────────────────────────────────────
class _CorpusTab extends ConsumerStatefulWidget {
  const _CorpusTab();

  @override
  ConsumerState<_CorpusTab> createState() => _CorpusTabState();
}

class _CorpusTabState extends ConsumerState<_CorpusTab> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;
    final projections = ref.watch(projectionProvider);
    final goals = ref.watch(goalsProvider);
    final profile = ref.watch(userProfileProvider);
    final purchases = ref.watch(purchasesProvider);
    final assumptions = ref.watch(assumptionsProvider);

    if (projections.isEmpty || profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final spots = projections
        .map((p) => FlSpot(p.year.toDouble(), p.corpus / 100000))
        .toList();

    final maxY = projections.isEmpty
        ? 100.0
        : (projections.map((p) => p.corpus / 100000).reduce((a, b) => a > b ? a : b) * 1.2);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 20,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (v, _) => Text(
                        _axisLabel(v * 100000),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        'Yr ${v.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      interval: 5,
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    getTooltipItems: (spots) => spots.map((s) {
                      final proj = projections.firstWhere(
                          (p) => p.year == s.x.toInt(),
                          orElse: () => projections.first);
                      return LineTooltipItem(
                        'Year ${s.x.toInt()}\n'
                        'Corpus: ${formatLakhsCrores(proj.corpus)}\n'
                        'CTC: ${formatLpa(proj.ctcLpa)}',
                        const TextStyle(
                            color: Colors.white, fontSize: 12),
                      );
                    }).toList(),
                  ),
                  touchCallback: (event, response) {
                    if (response?.lineBarSpots != null) {
                      setState(() {
                        _touchedIndex =
                            response!.lineBarSpots!.first.x.toInt();
                      });
                    }
                  },
                ),
                // Goal horizontal lines
                extraLinesData: ExtraLinesData(
                  horizontalLines: goals.map((g) {
                    final c = g.priority == 'high'
                        ? colors.high
                        : g.priority == 'medium'
                            ? colors.warning
                            : colors.success;
                    return HorizontalLine(
                      y: g.targetAmount / 100000,
                      color: c.withValues(alpha: 0.6),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (_) => g.name,
                        style: TextStyle(
                            color: c, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  verticalLines: goals.map((g) {
                    final fundedYear = finance.yearsToGoal(
                        g, profile, purchases, assumptions);
                    if (fundedYear == 0) return null;
                    final c = g.priority == 'high'
                        ? colors.high
                        : g.priority == 'medium'
                            ? colors.warning
                            : colors.success;
                    return VerticalLine(
                      x: fundedYear.toDouble(),
                      color: c.withValues(alpha: 0.4),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  }).whereType<VerticalLine>().toList(),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) =>
                          spot.x.toInt() == _touchedIndex ||
                          spot.x.toInt() % 5 == 0,
                      getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                        radius: 4,
                        color: theme.colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.25),
                          theme.colorScheme.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LegendItem(
                  color: theme.colorScheme.primary, label: 'Total Corpus'),
              ...goals.map((g) {
                final c = g.priority == 'high'
                    ? colors.high
                    : g.priority == 'medium'
                        ? colors.warning
                        : colors.success;
                return _LegendItem(
                    color: c, label: g.name, dashed: true);
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _axisLabel(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(0)}Cr';
    } else if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(0)}L';
    }
    return '₹${value.toInt()}';
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendItem(
      {required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(2),
            border:
                dashed ? Border.all(color: color, width: 1) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: YEAR-BY-YEAR TABLE
// ─────────────────────────────────────────────────────────────────────────────
class _TableTab extends ConsumerWidget {
  const _TableTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projections = ref.watch(projectionProvider);
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;

    if (projections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowColor:
              WidgetStateProperty.all(theme.colorScheme.primary.withValues(alpha: 0.1)),
          columns: const [
            DataColumn(label: Text('Yr')),
            DataColumn(label: Text('CTC')),
            DataColumn(label: Text('Take-Home')),
            DataColumn(label: Text('SIP/mo')),
            DataColumn(label: Text('Tech Spend')),
            DataColumn(label: Text('Corpus')),
            DataColumn(label: Text('Goals')),
          ],
          rows: projections.map((p) {
            final hasGoal = p.goalsFunded.isNotEmpty;
            return DataRow(
              color: hasGoal
                  ? WidgetStateProperty.all(
                      colors.success.withValues(alpha: 0.06))
                  : null,
              cells: [
                DataCell(Container(
                  padding: const EdgeInsets.only(left: 4),
                  decoration: hasGoal
                      ? BoxDecoration(
                          border: Border(
                              left: BorderSide(
                                  color: colors.success, width: 3)),
                        )
                      : null,
                  child: Text('${p.year}'),
                )),
                DataCell(Text(formatLpa(p.ctcLpa))),
                DataCell(Text(formatLakhsCrores(p.takeHomeMonthly * 12))),
                DataCell(Text(formatLakhsCrores(p.sipMonthly))),
                DataCell(Text(p.techSpendAnnual > 0
                    ? formatLakhsCrores(p.techSpendAnnual)
                    : '—')),
                DataCell(Text(
                  formatLakhsCrores(p.corpus),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                )),
                DataCell(
                  p.goalsFunded.isNotEmpty
                      ? Tooltip(
                          message: p.goalsFunded.join(', '),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag,
                                  color: colors.success, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${p.goalsFunded.length}',
                                style: TextStyle(
                                    color: colors.success,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                      : const Text('—'),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: WHAT-IF EXPLORER
// ─────────────────────────────────────────────────────────────────────────────
class _WhatIfTab extends ConsumerStatefulWidget {
  const _WhatIfTab();

  @override
  ConsumerState<_WhatIfTab> createState() => _WhatIfTabState();
}

class _WhatIfTabState extends ConsumerState<_WhatIfTab> {
  double _hikeOverride = 12;
  double _sipOverride = 15;
  double _houseTarget = 15000000;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;

    final profile = ref.watch(userProfileProvider);
    final goals = ref.watch(goalsProvider);
    final purchases = ref.watch(purchasesProvider);
    final assumptions = ref.watch(assumptionsProvider);
    final baseProjections = ref.watch(projectionProvider);

    if (profile == null || baseProjections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Generate what-if projection (ephemeral, not saved)
    final whatIfProfile = profile.copyWith(
      annualHikePct: _hikeOverride / 100,
      sipRatePct: _sipOverride / 100,
    );
    final whatIfProjections = finance.generateProjection(
        whatIfProfile, goals, purchases, assumptions);

    final baseCorpus10 =
        baseProjections.firstWhere((p) => p.year == 10).corpus;
    final whatIfCorpus10 =
        whatIfProjections.firstWhere((p) => p.year == 10).corpus;
    final delta = whatIfCorpus10 - baseCorpus10;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What-If Explorer',
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Adjust parameters to see the impact (not saved to profile)',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),

          // Delta card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (delta >= 0 ? colors.success : colors.high)
                      .withValues(alpha: 0.12),
                  theme.colorScheme.primary.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: (delta >= 0 ? colors.success : colors.high)
                      .withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  delta >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: delta >= 0 ? colors.success : colors.high,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${delta >= 0 ? '+' : ''}${formatLakhsCrores(delta)} corpus at Year 10',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: delta >= 0 ? colors.success : colors.high,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'vs your current plan (${formatLakhsCrores(baseCorpus10)})',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sliders
          _SliderRow(
            label: 'Salary Hike',
            value: _hikeOverride,
            min: 8,
            max: 30,
            divisions: 22,
            format: (v) => '${v.toInt()}%',
            onChanged: (v) => setState(() => _hikeOverride = v),
            accentColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 20),
          _SliderRow(
            label: 'SIP Rate (% of take-home)',
            value: _sipOverride,
            min: 10,
            max: 30,
            divisions: 20,
            format: (v) => '${v.toInt()}%',
            onChanged: (v) => setState(() => _sipOverride = v),
            accentColor: colors.success,
          ),
          const SizedBox(height: 20),
          _SliderRow(
            label: 'House Target',
            value: _houseTarget,
            min: 5000000,
            max: 50000000,
            divisions: 45,
            format: (v) => formatLakhsCrores(v),
            onChanged: (v) => setState(() => _houseTarget = v),
            accentColor: colors.warning,
          ),
          const SizedBox(height: 24),

          // Mini chart
          Text('Corpus Growth (What-If vs Actual)',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 20,
                minY: 0,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) =>
                          Text('Yr${v.toInt()}', style: const TextStyle(fontSize: 9)),
                      interval: 5,
                    ),
                  ),
                ),
                lineBarsData: [
                  // Actual
                  LineChartBarData(
                    spots: baseProjections
                        .map((p) =>
                            FlSpot(p.year.toDouble(), p.corpus / 100000))
                        .toList(),
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    barWidth: 2,
                    isCurved: true,
                    dotData: const FlDotData(show: false),
                  ),
                  // What-if
                  LineChartBarData(
                    spots: whatIfProjections
                        .map((p) =>
                            FlSpot(p.year.toDouble(), p.corpus / 100000))
                        .toList(),
                    color: colors.success,
                    barWidth: 2.5,
                    isCurved: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [0],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendItem2(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  label: 'Current Plan'),
              const SizedBox(width: 16),
              _LegendItem2(color: colors.success, label: 'What-If'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;
  final Color accentColor;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.titleMedium),
            Text(
              format(value),
              style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accentColor,
            thumbColor: accentColor,
            overlayColor: accentColor.withValues(alpha: 0.12),
            inactiveTrackColor: accentColor.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _LegendItem2 extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem2({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }
}
