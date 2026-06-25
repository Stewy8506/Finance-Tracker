import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../../finance.dart' as finance;
import '../../models/user_profile.dart';
import '../../models/year_projection.dart';
import '../../providers/projection_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/purchases_provider.dart';
import '../../providers/assumptions_provider.dart';
import '../../providers/income_provider.dart';
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
  final GlobalKey _chartKey = GlobalKey();
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _lastIndex) {
        _lastIndex = _tabController.index;
        HapticFeedback.lightImpact();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _shareChart() async {
    try {
      final boundary = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final xFile = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'ledger_projection.png',
      );

      await Share.shareXFiles([xFile], text: 'My Ledger Financial Projection Chart');
    } catch (e) {
      debugPrint('Error sharing chart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final recalculating = ref.watch(projectionRecalculatingProvider);
    final isCorpusTab = _tabController.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Projection'),
            if (recalculating) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Goals Tracker',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/goals');
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            tooltip: 'Spend Planner',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/purchases');
            },
          ),
          if (isCorpusTab)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share Chart',
              onPressed: _shareChart,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Corpus'),
            Tab(text: 'Year-by-Year'),
            Tab(text: 'What-If'),
            Tab(text: 'Retirement'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CorpusTab(chartKey: _chartKey),
          const _TableTab(),
          const _WhatIfTab(),
          const _RetirementTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: CORPUS LINE CHART
// ─────────────────────────────────────────────────────────────────────────────
class _CorpusTab extends ConsumerStatefulWidget {
  final GlobalKey chartKey;
  const _CorpusTab({required this.chartKey});

  @override
  ConsumerState<_CorpusTab> createState() => _CorpusTabState();
}

class _CorpusTabState extends ConsumerState<_CorpusTab> {
  int? _touchedIndex;
  bool _compareRegimes = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;
    final projections = ref.watch(projectionProvider);
    final goals = ref.watch(goalsProvider);
    final profile = ref.watch(userProfileProvider);
    final purchases = ref.watch(purchasesProvider);
    final assumptions = ref.watch(assumptionsProvider);
    final incomeSources = ref.watch(incomeSourcesProvider);

    if (projections.isEmpty || profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final spots = projections
        .map((p) => FlSpot(p.year.toDouble(), p.corpus / 100000))
        .toList();

    List<YearProjection> otherProjections = [];
    List<FlSpot> otherSpots = [];
    double delta = 0;
    if (_compareRegimes) {
      final otherProfile = profile.copyWith(
        taxRegime: profile.taxRegime == 'new' ? 'old' : 'new',
      );
      otherProjections = finance.generateProjection(
        otherProfile,
        goals,
        purchases,
        assumptions,
        incomeSources: incomeSources,
      );
      otherSpots = otherProjections
          .map((p) => FlSpot(p.year.toDouble(), p.corpus / 100000))
          .toList();
      delta = projections.last.corpus - otherProjections.last.corpus;
    }

    final maxY = projections.isEmpty
        ? 100.0
        : (projections.map((p) => p.corpus / 100000).reduce((a, b) => a > b ? a : b) * 1.2);

    return RepaintBoundary(
      key: widget.chartKey,
      child: Container(
        color: const Color(0xFF08090A),
        child: Column(
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
                      getDrawingHorizontalLine: (v) => const FlLine(
                        color: Color(0xFF1F2128),
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
                          getTitlesWidget: (v, _) {
                            final yr = v.toInt();
                            if (yr < 0 || yr > 20) return const SizedBox.shrink();
                            final startYear = profile.startYear ?? DateTime.now().year;
                            return Text(
                              '${startYear + yr}',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
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
                        getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                          final isAlternative = s.barIndex == 1;
                          final projList = isAlternative ? otherProjections : projections;
                          if (projList.isEmpty) return null;
                          final proj = projList.firstWhere(
                              (p) => p.year == s.x.toInt(),
                              orElse: () => projList.first);
                          final startYear = profile.startYear ?? DateTime.now().year;
                          final regimeName = isAlternative 
                              ? (profile.taxRegime == 'new' ? 'Old' : 'New')
                              : (profile.taxRegime == 'new' ? 'New' : 'Old');
                          return LineTooltipItem(
                            '${startYear + s.x.toInt()} ($regimeName)\n'
                            'Corpus: ${formatLakhsCrores(proj.corpus)}\n'
                            'CTC: ${formatLpa(proj.ctcLpa)}',
                            const TextStyle(
                                color: Colors.white, fontSize: 12),
                          );
                        }).whereType<LineTooltipItem>().toList(),
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
                          show: false,
                        ),
                      ),
                      if (_compareRegimes)
                        LineChartBarData(
                          spots: otherSpots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: const Color(0xFFA0A0A0),
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dashArray: [6, 4],
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: false,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Legend
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _LegendItem(
                      color: theme.colorScheme.primary,
                      label: 'Corpus (${profile.taxRegime == 'new' ? 'New' : 'Old'})'),
                  if (_compareRegimes)
                    const _LegendItem(
                      color: Color(0xFFA0A0A0),
                      label: 'Corpus (Alt)',
                      dashed: true,
                    ),
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
            // Regime comparison toggle & delta card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Compare Tax Regimes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: _compareRegimes,
                    onChanged: (val) {
                      setState(() {
                        _compareRegimes = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (_compareRegimes)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111215),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1F2128)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        delta >= 0 ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                        color: delta >= 0 ? colors.success : colors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final currentRegimeName = profile.taxRegime == 'new' ? 'New' : 'Old';
                            final otherRegimeName = profile.taxRegime == 'new' ? 'Old' : 'New';
                            final bestRegimeName = delta >= 0 ? currentRegimeName : otherRegimeName;
                            return Text(
                              'Using the $bestRegimeName regime results in a ${formatLakhsCrores(delta.abs())} higher corpus after 20 years compared to the ${delta >= 0 ? otherRegimeName : currentRegimeName} regime.',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFF4F4F6)),
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
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
    final profile = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;

    if (projections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final startYear = profile?.startYear ?? DateTime.now().year;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowColor:
              WidgetStateProperty.all(const Color(0xFF222222)),
          columns: const [
            DataColumn(label: Text('Year')),
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
                  child: Text('${startYear + p.year}'),
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
  List<HikeBracket>? _whatIfBrackets;
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
    final incomeSources = ref.watch(incomeSourcesProvider);

    if (profile == null || baseProjections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_whatIfBrackets == null) {
      _whatIfBrackets = profile.hikeBrackets;
      if (_whatIfBrackets!.isEmpty) {
        _whatIfBrackets = UserProfile.defaultHikeBrackets(profile.annualHikePct);
      }
    }

    // Generate what-if projection (ephemeral, not saved)
    final whatIfProfile = profile.copyWith(
      sipRatePct: _sipOverride / 100,
    );
    if (_whatIfBrackets != null) {
      whatIfProfile.hikeBrackets = _whatIfBrackets!;
    }
    final whatIfProjections = finance.generateProjection(
        whatIfProfile, goals, purchases, assumptions,
        incomeSources: incomeSources);

    final baseCorpus10 =
        baseProjections.firstWhere((p) => p.year == 10).corpus;
    final whatIfCorpus10 =
        whatIfProjections.firstWhere((p) => p.year == 10).corpus;
    final delta = whatIfCorpus10 - baseCorpus10;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
              color: const Color(0xFF111215),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF1F2128)),
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

          // Hike Brackets Editor on What-If tab
          Text('Salary Hike Brackets', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._whatIfBrackets!.map((bracket) {
            final index = _whatIfBrackets!.indexOf(bracket);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(bracket.label, style: theme.textTheme.bodyMedium),
                  ),
                  Expanded(
                    flex: 5,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: theme.colorScheme.primary,
                        thumbColor: theme.colorScheme.primary,
                        overlayColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                        inactiveTrackColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: bracket.hikePct * 100,
                        min: 0,
                        max: 50,
                        divisions: 50,
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _whatIfBrackets![index] = HikeBracket(
                              fromYear: bracket.fromYear,
                              toYear: bracket.toYear,
                              hikePct: v / 100,
                            );
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(bracket.hikePct * 100).toInt()}%',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          }),
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
            onChanged: (v) {
              HapticFeedback.lightImpact();
              onChanged(v);
            },
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

class _RetirementTab extends ConsumerStatefulWidget {
  const _RetirementTab();

  @override
  ConsumerState<_RetirementTab> createState() => _RetirementTabState();
}

class _RetirementTabState extends ConsumerState<_RetirementTab> {
  double _currentAge = 25;
  double _retirementAge = 55;
  double _lifeExpectancy = 85;
  double? _desiredIncomeToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;

    final profile = ref.watch(userProfileProvider);
    final assumptions = ref.watch(assumptionsProvider);
    final projections = ref.watch(projectionProvider);

    if (profile == null || projections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    _desiredIncomeToday ??= profile.monthlyRent +
        profile.monthlyFood +
        profile.monthlyTransport +
        profile.monthlyMisc;

    final yearsToRetire = (_retirementAge - _currentAge).clamp(1.0, 20.0).toInt();
    final yearsInRetirement = (_lifeExpectancy - _retirementAge).toInt();

    final corpusAtRetirement = projections.firstWhere(
      (p) => p.year == yearsToRetire,
      orElse: () => projections.last,
    ).corpus;

    final inflatedRetirementIncome = _desiredIncomeToday! *
        math.pow(1 + assumptions.expenseInflation, yearsToRetire);

    final rReal = ((assumptions.sipReturnRate) / 12 - (assumptions.expenseInflation) / 12) /
        (1 + (assumptions.expenseInflation) / 12);
    final n = yearsInRetirement * 12;
    double requiredCorpus = 0;
    if (rReal == 0) {
      requiredCorpus = inflatedRetirementIncome * n;
    } else {
      requiredCorpus = inflatedRetirementIncome * (1 - math.pow(1 + rReal, -n)) / rReal;
    }

    final gap = requiredCorpus - corpusAtRetirement;

    final actualSwpAtRetirement = finance.swpMonthly(
      corpusAtRetirement,
      assumptions.sipReturnRate,
      assumptions.expenseInflation,
      yearsInRetirement,
    );
    final sustainableSwpToday =
        actualSwpAtRetirement / math.pow(1 + assumptions.expenseInflation, yearsToRetire);

    final depletionYears = finance.corpusDepletionYear(
      corpusAtRetirement,
      inflatedRetirementIncome,
      assumptions.sipReturnRate,
      assumptions.expenseInflation,
    );
    final depletionAge = _retirementAge + depletionYears;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Retirement & SWP Planner', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Model sustainable Systematic Withdrawal Plans (SWP)',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _RetirementMetricCard(
                  label: 'Projected Corpus',
                  amount: corpusAtRetirement,
                  subtitle: 'At age ${_retirementAge.toInt()}',
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RetirementMetricCard(
                  label: 'Required Target',
                  amount: requiredCorpus,
                  subtitle: 'Inflated Target',
                  color: colors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: gap <= 0 ? colors.success.withValues(alpha: 0.1) : colors.high.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: gap <= 0 ? colors.success : colors.high,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  gap <= 0 ? Icons.check_circle : Icons.error_outline,
                  color: gap <= 0 ? colors.success : colors.high,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gap <= 0 ? 'On Track for Retirement! ✓' : 'Retirement Deficit',
                        style: TextStyle(
                          color: gap <= 0 ? colors.success : colors.high,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        gap <= 0
                            ? 'Your projected corpus exceeds the target by ${formatLakhsCrores(-gap)}.'
                            : 'You need ${formatLakhsCrores(gap)} more to sustain your lifestyle.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('SWP Sustainability', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111215),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F2128)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sustainable SWP (Today\'s Value)'),
                    Text(
                      '${formatCurrency(sustainableSwpToday)}/mo',
                      style: TextStyle(color: colors.success, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Corpus Depletion Age'),
                    Text(
                      depletionAge >= _lifeExpectancy ? 'Lasts past ${_lifeExpectancy.toInt()}' : 'Age ${depletionAge.toInt()}',
                      style: TextStyle(
                        color: depletionAge >= _lifeExpectancy ? colors.success : colors.high,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  depletionAge >= _lifeExpectancy
                      ? 'Your corpus is projected to sustain withdrawals past your expected life expectancy of ${_lifeExpectancy.toInt()} years.'
                      : 'WARNING: Your corpus will run dry at age ${depletionAge.toInt()}, which is ${( _lifeExpectancy - depletionAge).toInt()} years before expected life expectancy.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SliderRow(
            label: 'Current Age',
            value: _currentAge,
            min: 20,
            max: 50,
            divisions: 30,
            format: (v) => '${v.toInt()} yrs',
            onChanged: (v) => setState(() {
              _currentAge = v;
              if (_currentAge >= _retirementAge) {
                _retirementAge = _currentAge + 5;
              }
            }),
            accentColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          _SliderRow(
            label: 'Retirement Age',
            value: _retirementAge,
            min: _currentAge + 1,
            max: 70,
            divisions: (70 - _currentAge - 1).toInt(),
            format: (v) => '${v.toInt()} yrs (in ${(v - _currentAge).toInt()} yrs)',
            onChanged: (v) => setState(() {
              _retirementAge = v;
              if (_retirementAge >= _lifeExpectancy) {
                _lifeExpectancy = _retirementAge + 5;
              }
            }),
            accentColor: colors.warning,
          ),
          const SizedBox(height: 16),
          _SliderRow(
            label: 'Life Expectancy',
            value: _lifeExpectancy,
            min: _retirementAge + 1,
            max: 100,
            divisions: (100 - _retirementAge - 1).toInt(),
            format: (v) => '${v.toInt()} yrs',
            onChanged: (v) => setState(() => _lifeExpectancy = v),
            accentColor: colors.high,
          ),
          const SizedBox(height: 16),
          _SliderRow(
            label: 'Retirement Income (Today\'s ₹/mo)',
            value: _desiredIncomeToday!,
            min: 10000,
            max: 200000,
            divisions: 19,
            format: (v) => formatCurrency(v),
            onChanged: (v) => setState(() => _desiredIncomeToday = v),
            accentColor: colors.success,
          ),
        ],
      ),
    );
  }
}

class _RetirementMetricCard extends StatelessWidget {
  final String label;
  final double amount;
  final String subtitle;
  final Color color;

  const _RetirementMetricCard({
    required this.label,
    required this.amount,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111215),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            formatLakhsCrores(amount),
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
