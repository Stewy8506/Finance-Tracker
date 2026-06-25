import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../finance.dart' as finance;
import '../../models/user_profile.dart';
import '../../models/assumptions.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/purchases_provider.dart';
import '../../providers/assumptions_provider.dart';
import '../../providers/income_provider.dart';
import '../../theme.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/data_import.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final assumptions = ref.watch(assumptionsProvider);

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // ── 1. PROFILE ─────────────────────────────────────────────────
          _SectionHeader('Profile'),
          const SizedBox(height: 12),
          _ProfileEditor(profile: profile),
          const SizedBox(height: 24),

          // ── ADDITIONAL INCOME ──────────────────────────────────────────
          _SectionHeader('Additional Income Streams'),
          const SizedBox(height: 12),
          const _AdditionalIncomeEditor(),
          const SizedBox(height: 24),

          // ── 2. TAX COMPARISON ──────────────────────────────────────────
          _SectionHeader('Tax Comparison'),
          const SizedBox(height: 12),
          _TaxComparison(ctcLpa: profile.startingCtcLpa),
          const SizedBox(height: 24),

          // ── 3. ASSUMPTIONS ─────────────────────────────────────────────
          _SectionHeader('Projection Assumptions'),
          const SizedBox(height: 12),
          _AssumptionsEditor(assumptions: assumptions),
          const SizedBox(height: 24),

          // ── APP CUSTOMIZATION ──────────────────────────────────────────
          _SectionHeader('App Customization'),
          const SizedBox(height: 12),
          _AppPreferencesEditor(profile: profile),
          const SizedBox(height: 24),

          // ── 4. DATA ────────────────────────────────────────────────────
          _SectionHeader('Data'),
          const SizedBox(height: 12),
          _DataSection(),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFA0A0A0),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE EDITOR
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileEditor extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _ProfileEditor({required this.profile});

  @override
  ConsumerState<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends ConsumerState<_ProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctcCtrl;
  late final TextEditingController _hikeCtrl;
  late String _regime;
  late String _cityPreset;
  late final TextEditingController _rentCtrl;
  late final TextEditingController _foodCtrl;
  late final TextEditingController _transportCtrl;
  late final TextEditingController _miscCtrl;
  late double _sipPct;
  late final TextEditingController _emergencyFundCtrl;
  late final TextEditingController _startYearCtrl;
  late final TextEditingController _otherAssetsCtrl;
  late final TextEditingController _liabilitiesCtrl;
  late List<HikeBracket> _hikeBrackets;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _ctcCtrl = TextEditingController(text: p.startingCtcLpa.toStringAsFixed(1));
    _hikeCtrl = TextEditingController(
        text: (p.annualHikePct * 100).toStringAsFixed(0));
    _regime = p.taxRegime;
    _cityPreset = p.cityPreset;
    _rentCtrl = TextEditingController(text: p.monthlyRent.toInt().toString());
    _foodCtrl = TextEditingController(text: p.monthlyFood.toInt().toString());
    _transportCtrl =
        TextEditingController(text: p.monthlyTransport.toInt().toString());
    _miscCtrl = TextEditingController(text: p.monthlyMisc.toInt().toString());
    _sipPct = p.sipRatePct * 100;
    _emergencyFundCtrl = TextEditingController(
        text: (p.emergencyFundBalance ?? 0).toInt().toString());
    _startYearCtrl = TextEditingController(
        text: (p.startYear ?? DateTime.now().year).toString());
    _otherAssetsCtrl = TextEditingController(
        text: (p.otherAssets ?? 0).toInt().toString());
    _liabilitiesCtrl = TextEditingController(
        text: (p.liabilities ?? 0).toInt().toString());
    _hikeBrackets = List.from(p.hikeBrackets);
    if (_hikeBrackets.isEmpty) {
      _hikeBrackets = UserProfile.defaultHikeBrackets(p.annualHikePct);
    }
    _ctcCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctcCtrl.dispose();
    _hikeCtrl.dispose();
    _rentCtrl.dispose();
    _foodCtrl.dispose();
    _transportCtrl.dispose();
    _miscCtrl.dispose();
    _emergencyFundCtrl.dispose();
    _startYearCtrl.dispose();
    _otherAssetsCtrl.dispose();
    _liabilitiesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.profile.copyWith(
      startingCtcLpa: double.tryParse(_ctcCtrl.text) ?? widget.profile.startingCtcLpa,
      annualHikePct: (double.tryParse(_hikeCtrl.text) ?? 12) / 100,
      taxRegime: _regime,
      cityPreset: _cityPreset,
      monthlyRent: double.tryParse(_rentCtrl.text) ?? widget.profile.monthlyRent,
      monthlyFood: double.tryParse(_foodCtrl.text) ?? widget.profile.monthlyFood,
      monthlyTransport:
          double.tryParse(_transportCtrl.text) ?? widget.profile.monthlyTransport,
      monthlyMisc: double.tryParse(_miscCtrl.text) ?? widget.profile.monthlyMisc,
      sipRatePct: _sipPct / 100,
      emergencyFundBalance: double.tryParse(_emergencyFundCtrl.text) ?? 0,
      startYear: int.tryParse(_startYearCtrl.text) ?? DateTime.now().year,
      otherAssets: double.tryParse(_otherAssetsCtrl.text) ?? 0,
      liabilities: double.tryParse(_liabilitiesCtrl.text) ?? 0,
    );
    updated.hikeBrackets = _hikeBrackets;
    ref.read(userProfileProvider.notifier).save(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctcLpa = double.tryParse(_ctcCtrl.text) ?? 0;
    final takeHome = finance.calculateTakeHome(ctcLpa, _regime);

    return Form(
      key: _formKey,
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
            // Live take-home preview
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2128),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Take-Home', style: theme.textTheme.bodySmall),
                      Text(
                        formatCurrency(takeHome),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextFormField(
              controller: _ctcCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Current CTC (LPA)',
                suffixText: 'LPA',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter CTC';
                final val = double.tryParse(v);
                if (val == null || val <= 0) return 'Enter a positive CTC';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hikeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Annual Hike % (Fallback)',
                suffixText: '%',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter hike';
                final val = double.tryParse(v);
                if (val == null || val < 0 || val > 100) return 'Enter percentage 0-100';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startYearCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Start Year',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter year';
                      final val = int.tryParse(v);
                      if (val == null || val < 2000 || val > 2100) return 'Invalid year';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _emergencyFundCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Fund',
                      prefixText: '₹ ',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter balance';
                      final val = double.tryParse(v);
                      if (val == null || val < 0) return 'Invalid balance';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _otherAssetsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Other Assets',
                      prefixText: '₹ ',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter balance';
                      final val = double.tryParse(v);
                      if (val == null || val < 0) return 'Invalid balance';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _liabilitiesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Liabilities',
                      prefixText: '₹ ',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter liabilities';
                      final val = double.tryParse(v);
                      if (val == null || val < 0) return 'Invalid balance';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Stepped Salary Hike Brackets',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._hikeBrackets.map((bracket) {
              final index = _hikeBrackets.indexOf(bracket);
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
                              _hikeBrackets[index] = HikeBracket(
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
            const SizedBox(height: 12),
          // Tax regime toggle
          Text('Tax Regime', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: ['new', 'old'].map((r) {
              final label = r == 'new' ? 'New 2026' : 'Old Regime';
              return Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(right: r == 'new' ? 8 : 0),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _regime == r,
                    onSelected: (_) => setState(() => _regime = r),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _cityPreset,
            decoration: const InputDecoration(labelText: 'City Preset'),
            dropdownColor: const Color(0xFF111215),
            items: const [
              DropdownMenuItem(
                  value: 'kolkata_home', child: Text('Kolkata (home)')),
              DropdownMenuItem(
                  value: 'kolkata_rent', child: Text('Kolkata (rented)')),
              DropdownMenuItem(value: 'metro', child: Text('Metro city')),
              DropdownMenuItem(value: 'custom', child: Text('Custom')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _cityPreset = v);
                if (v != 'custom') {
                  final exp = UserProfile.presetExpenses(v);
                  _rentCtrl.text = exp['rent'].toString();
                  _foodCtrl.text = exp['food'].toString();
                  _transportCtrl.text = exp['transport'].toString();
                  _miscCtrl.text = exp['misc'].toString();
                }
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _rentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Rent', prefixText: '₹ '),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _foodCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Food', prefixText: '₹ '),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _transportCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Transport', prefixText: '₹ '),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _miscCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Misc', prefixText: '₹ '),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SIP Rate: ${_sipPct.toInt()}%',
                  style: theme.textTheme.titleMedium),
              Text(
                formatCurrency(takeHome * _sipPct / 100),
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Slider(
            value: _sipPct,
            min: 10,
            max: 30,
            divisions: 20,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              setState(() => _sipPct = v);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Profile',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );
}
}

// ─────────────────────────────────────────────────────────────────────────────
// TAX COMPARISON
// ─────────────────────────────────────────────────────────────────────────────
class _TaxComparison extends StatelessWidget {
  final double ctcLpa;

  const _TaxComparison({required this.ctcLpa});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final newTakeHome = finance.calculateTakeHome(ctcLpa, 'new');
    final oldTakeHome = finance.calculateTakeHome(ctcLpa, 'old');
    final newTax = finance.calculateAnnualTax(ctcLpa, 'new');
    final oldTax = finance.calculateAnnualTax(ctcLpa, 'old');
    final better = newTakeHome >= oldTakeHome ? 'new' : 'old';
    final savings = (newTakeHome - oldTakeHome).abs() * 12;

    return Row(
      children: [
        Expanded(
          child: _TaxCard(
            title: 'New Regime 2026',
            takeHome: newTakeHome,
            tax: newTax,
            isBetter: better == 'new',
            savings: savings,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TaxCard(
            title: 'Old Regime',
            takeHome: oldTakeHome,
            tax: oldTax,
            isBetter: better == 'old',
            savings: savings,
            color: const Color(0xFF818CF8),
          ),
        ),
      ],
    );
  }
}

class _TaxCard extends StatelessWidget {
  final String title;
  final double takeHome;
  final double tax;
  final bool isBetter;
  final double savings;
  final Color color;

  const _TaxCard({
    required this.title,
    required this.takeHome,
    required this.tax,
    required this.isBetter,
    required this.savings,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111215),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1F2128),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            formatCurrency(takeHome),
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text('/month', style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text('Tax: ${formatLakhsCrores(tax)}/yr',
              style: theme.textTheme.bodySmall),
          if (isBetter) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2128),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✓ Save ${formatLakhsCrores(savings)}/yr',
                style: TextStyle(
                    color: colors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ASSUMPTIONS EDITOR
// ─────────────────────────────────────────────────────────────────────────────
class _AssumptionsEditor extends ConsumerStatefulWidget {
  final Assumptions assumptions;

  const _AssumptionsEditor({required this.assumptions});

  @override
  ConsumerState<_AssumptionsEditor> createState() =>
      _AssumptionsEditorState();
}

class _AssumptionsEditorState extends ConsumerState<_AssumptionsEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sipRateCtrl;
  late final TextEditingController _cashRateCtrl;
  late final TextEditingController _inflationCtrl;
  late final TextEditingController _loanRateCtrl;
  late final TextEditingController _tenureCtrl;

  @override
  void initState() {
    super.initState();
    final a = widget.assumptions;
    _sipRateCtrl = TextEditingController(
        text: (a.sipReturnRate * 100).toStringAsFixed(0));
    _cashRateCtrl = TextEditingController(
        text: (a.cashSavingsRate * 100).toStringAsFixed(0));
    _inflationCtrl = TextEditingController(
        text: (a.expenseInflation * 100).toStringAsFixed(0));
    _loanRateCtrl = TextEditingController(
        text: (a.homeLoanRate * 100).toStringAsFixed(1));
    _tenureCtrl = TextEditingController(
        text: a.loanTenureYears.toString());
  }

  @override
  void dispose() {
    _sipRateCtrl.dispose();
    _cashRateCtrl.dispose();
    _inflationCtrl.dispose();
    _loanRateCtrl.dispose();
    _tenureCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.assumptions.copyWith(
      sipReturnRate: (double.tryParse(_sipRateCtrl.text) ?? 12) / 100,
      cashSavingsRate: (double.tryParse(_cashRateCtrl.text) ?? 6) / 100,
      expenseInflation: (double.tryParse(_inflationCtrl.text) ?? 6) / 100,
      homeLoanRate: (double.tryParse(_loanRateCtrl.text) ?? 8.5) / 100,
      loanTenureYears: int.tryParse(_tenureCtrl.text) ?? 20,
    );
    ref.read(assumptionsProvider.notifier).save(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Assumptions saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111215),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2128)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _AssumptionField(
                    label: 'SIP Return (%)',
                    ctrl: _sipRateCtrl,
                    suffix: '%',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter rate';
                      final val = double.tryParse(v);
                      if (val == null || val < 0 || val > 100) return 'Enter 0-100';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AssumptionField(
                    label: 'Cash Savings (%)',
                    ctrl: _cashRateCtrl,
                    suffix: '%',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter rate';
                      final val = double.tryParse(v);
                      if (val == null || val < 0 || val > 100) return 'Enter 0-100';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _AssumptionField(
                    label: 'Expense Inflation (%)',
                    ctrl: _inflationCtrl,
                    suffix: '%',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter rate';
                      final val = double.tryParse(v);
                      if (val == null || val < 0 || val > 100) return 'Enter 0-100';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AssumptionField(
                    label: 'Home Loan Rate (%)',
                    ctrl: _loanRateCtrl,
                    suffix: '%',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter rate';
                      final val = double.tryParse(v);
                      if (val == null || val < 0 || val > 100) return 'Enter 0-100';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _AssumptionField(
              label: 'Loan Tenure (years)',
              ctrl: _tenureCtrl,
              suffix: 'yrs',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter tenure';
                final val = int.tryParse(v);
                if (val == null || val < 1 || val > 30) return 'Enter 1-30 yrs';
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _save,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Assumptions',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssumptionField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String suffix;
  final String? Function(String?)? validator;

  const _AssumptionField(
      {required this.label, required this.ctrl, required this.suffix, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP PREFERENCES EDITOR
// ─────────────────────────────────────────────────────────────────────────────
class _AppPreferencesEditor extends ConsumerWidget {
  final UserProfile profile;

  const _AppPreferencesEditor({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStyle = profile.navbarStyle ?? 'expand';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111215),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2128), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Navbar Style',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select navigation layout design',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              DropdownButton<String>(
                value: currentStyle,
                dropdownColor: const Color(0xFF111215),
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8E8E93)),
                items: const [
                  DropdownMenuItem(
                    value: 'expand',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Dynamic Expand'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'icons_only',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Icons Only (Dots)'),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    HapticFeedback.lightImpact();
                    ref.read(userProfileProvider.notifier).save(
                          profile.copyWith(navbarStyle: val),
                        );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _DataSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;
    final profile = ref.watch(userProfileProvider);
    final goals = ref.watch(goalsProvider);
    final purchases = ref.watch(purchasesProvider);
    final assumptions = ref.watch(assumptionsProvider);
    final incomeSources = ref.watch(incomeSourcesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111215),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2128)),
      ),
      child: Column(
        children: [
          // Export JSON
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2128),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.download_outlined,
                  color: theme.colorScheme.primary, size: 20),
            ),
            title: const Text('Export to JSON'),
            subtitle: const Text('Share your financial data'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () async {
              final data = {
                'exportedAt': DateTime.now().toIso8601String(),
                'profile': {
                  'startingCtcLpa': profile?.startingCtcLpa,
                  'annualHikePct': profile?.annualHikePct,
                  'taxRegime': profile?.taxRegime,
                  'cityPreset': profile?.cityPreset,
                  'monthlyRent': profile?.monthlyRent,
                  'monthlyFood': profile?.monthlyFood,
                  'monthlyTransport': profile?.monthlyTransport,
                  'monthlyMisc': profile?.monthlyMisc,
                  'sipRatePct': profile?.sipRatePct,
                  'emergencyFundBalance': profile?.emergencyFundBalance,
                  'startYear': profile?.startYear,
                  'otherAssets': profile?.otherAssets,
                  'liabilities': profile?.liabilities,
                  'hikeBracketsRaw': profile?.hikeBracketsRaw,
                },
                'goals': goals.map((g) => {
                      'id': g.id,
                      'name': g.name,
                      'targetAmount': g.targetAmount,
                      'targetYear': g.targetYear,
                      'type': g.type,
                      'priority': g.priority,
                      'adjustForInflation': g.adjustForInflation,
                      'propertyValue': g.propertyValue,
                      'downPaymentPct': g.downPaymentPct,
                    }).toList(),
                'purchases': purchases.map((p) => {
                      'id': p.id,
                      'name': p.name,
                      'amount': p.amount,
                      'firstYear': p.firstYear,
                      'recurEveryNYears': p.recurEveryNYears,
                      'category': p.category,
                    }).toList(),
                'incomeSources': incomeSources.map((s) => {
                      'id': s.id,
                      'label': s.label,
                      'monthlyAmount': s.monthlyAmount,
                      'annualGrowthPct': s.annualGrowthPct,
                    }).toList(),
                'assumptions': {
                  'sipReturnRate': assumptions.sipReturnRate,
                  'cashSavingsRate': assumptions.cashSavingsRate,
                  'expenseInflation': assumptions.expenseInflation,
                  'homeLoanRate': assumptions.homeLoanRate,
                  'loanTenureYears': assumptions.loanTenureYears,
                },
              };
              final json = const JsonEncoder.withIndent('  ').convert(data);
              await Share.share(json, subject: 'Ledger Export');
            },
          ),
          const Divider(height: 1),
          // Import JSON
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2128),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.upload_outlined,
                  color: theme.colorScheme.primary, size: 20),
            ),
            title: const Text('Import from JSON'),
            subtitle: const Text('Paste and restore your financial data'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Import Data'),
                  content: const Text(
                      'This will overwrite all your current data. Are you sure you want to proceed?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Proceed'),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;

              if (!context.mounted) return;
              final txtCtrl = TextEditingController();
              final importJson = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Paste Exported JSON'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: TextField(
                      controller: txtCtrl,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        hintText: '{\n  "profile": ...\n}',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, txtCtrl.text),
                      child: const Text('Import'),
                    ),
                  ],
                ),
              );

              if (importJson != null && importJson.trim().isNotEmpty) {
                final result = await importFromJson(importJson, ref);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success ? colors.success : colors.high,
                  ),
                );
              }
            },
          ),
          const Divider(height: 1),
          // Reset
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2128),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_sweep_outlined,
                  color: colors.high, size: 20),
            ),
            title: Text('Reset All Data',
                style: TextStyle(color: colors.high)),
            subtitle: const Text('Clear all profile, goals, and purchases'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset All Data'),
                  content: const Text(
                      'This will permanently delete all your data and restart onboarding. Are you sure?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(userProfileProvider.notifier).reset();
                await ref.read(goalsProvider.notifier).reset();
                await ref.read(purchasesProvider.notifier).reset();
                await ref.read(assumptionsProvider.notifier).reset();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AdditionalIncomeEditor extends ConsumerWidget {
  const _AdditionalIncomeEditor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;
    final sources = ref.watch(incomeSourcesProvider);

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
          if (sources.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No additional income sources defined.',
                style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFFA0A0A0)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sources.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final source = sources[index];
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(source.label, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${formatCurrency(source.monthlyAmount)}/mo · Growth: ${(source.annualGrowthPct * 100).toInt()}%/yr',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: colors.high, size: 20),
                      onPressed: () {
                        ref.read(incomeSourcesProvider.notifier).delete(source.id);
                      },
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Income Source'),
              onPressed: () => _showAddDialog(context, ref),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final growthCtrl = TextEditingController(text: '5');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Income Source'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'Label (e.g. Freelance)'),
                validator: (v) => v == null || v.isEmpty ? 'Enter label' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Amount (₹)',
                  prefixText: '₹ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  final val = double.tryParse(v);
                  if (val == null || val <= 0) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: growthCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Annual Growth Rate (%)',
                  suffixText: '%',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter growth rate';
                  final val = double.tryParse(v);
                  if (val == null || val < 0 || val > 100) return 'Enter 0-100';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref.read(incomeSourcesProvider.notifier).addNew(
                      label: labelCtrl.text,
                      monthlyAmount: double.parse(amountCtrl.text),
                      annualGrowthPct: double.parse(growthCtrl.text) / 100,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
