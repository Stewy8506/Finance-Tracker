import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../finance.dart' as finance;
import '../../models/user_profile.dart';
import '../../models/goal.dart';
import '../../models/recurring_purchase.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/purchases_provider.dart';
import '../../theme.dart';
import '../../utils/currency_formatter.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final _uuid = const Uuid();

  // Step 1
  final _ctcController = TextEditingController(text: '10');
  double get _ctcLpa => double.tryParse(_ctcController.text) ?? 0;

  // Step 2
  double _hikePct = 12;

  // Step 3
  String _cityPreset = 'kolkata_home';
  final _rentController = TextEditingController();
  final _foodController = TextEditingController();
  final _transportController = TextEditingController();
  final _miscController = TextEditingController();

  // Step 4
  double _sipPct = 15;

  // Step 5
  final _goalNameController = TextEditingController(text: 'Own a house');
  final _goalAmountController = TextEditingController(text: '15000000');
  final _goalYearController = TextEditingController(text: '7');
  bool _skipGoal = false;

  @override
  void initState() {
    super.initState();
    _applyPreset('kolkata_home');
    _ctcController.addListener(() => setState(() {}));
  }

  void _applyPreset(String preset) {
    final expenses = UserProfile.presetExpenses(preset);
    _rentController.text = expenses['rent'].toString();
    _foodController.text = expenses['food'].toString();
    _transportController.text = expenses['transport'].toString();
    _miscController.text = expenses['misc'].toString();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ctcController.dispose();
    _rentController.dispose();
    _foodController.dispose();
    _transportController.dispose();
    _miscController.dispose();
    _goalNameController.dispose();
    _goalAmountController.dispose();
    _goalYearController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final profile = UserProfile(
      startingCtcLpa: _ctcLpa,
      annualHikePct: _hikePct / 100,
      taxRegime: 'new',
      cityPreset: _cityPreset,
      monthlyRent: double.tryParse(_rentController.text) ?? 0,
      monthlyFood: double.tryParse(_foodController.text) ?? 10000,
      monthlyTransport: double.tryParse(_transportController.text) ?? 4000,
      monthlyMisc: double.tryParse(_miscController.text) ?? 6000,
      sipRatePct: _sipPct / 100,
      onboardingComplete: true,
    );

    final userProfileNotifier = ref.read(userProfileProvider.notifier);
    final purchasesNotifier = ref.read(purchasesProvider.notifier);
    final goalsNotifier = ref.read(goalsProvider.notifier);

    await userProfileNotifier.save(profile);

    // Pre-populate default purchases
    final defaults = _defaultPurchases();
    await purchasesNotifier.addAll(defaults);

    // Add first goal if not skipped
    if (!_skipGoal) {
      final amount = double.tryParse(_goalAmountController.text) ?? 15000000;
      final year = int.tryParse(_goalYearController.text) ?? 7;
      final goal = Goal(
        id: _uuid.v4(),
        name: _goalNameController.text,
        targetAmount: amount,
        targetYear: year,
        type: 'down_payment',
        priority: 'high',
        propertyValue: amount,
        downPaymentPct: 0.20,
      );
      await goalsNotifier.add(goal);
    }

    if (mounted) context.go('/dashboard');
  }

  List<RecurringPurchase> _defaultPurchases() => [
        RecurringPurchase(
          id: _uuid.v4(),
          name: 'PC Build',
          amount: 300000,
          firstYear: 1,
          recurEveryNYears: 3,
          category: 'Tech',
        ),
        RecurringPurchase(
          id: _uuid.v4(),
          name: 'Desk Setup',
          amount: 50000,
          firstYear: 1,
          recurEveryNYears: null,
          category: 'Tech',
        ),
        RecurringPurchase(
          id: _uuid.v4(),
          name: 'Flagship Phone',
          amount: 150000,
          firstYear: 1,
          recurEveryNYears: 3,
          category: 'Tech',
        ),
        RecurringPurchase(
          id: _uuid.v4(),
          name: 'PC Upgrade',
          amount: 125000,
          firstYear: 3,
          recurEveryNYears: 2,
          category: 'Tech',
        ),
        RecurringPurchase(
          id: _uuid.v4(),
          name: 'Accessories',
          amount: 80000,
          firstYear: 2,
          recurEveryNYears: 2,
          category: 'Tech',
        ),
        RecurringPurchase(
          id: _uuid.v4(),
          name: 'Annual Travel',
          amount: 60000,
          firstYear: 1,
          recurEveryNYears: 1,
          category: 'Travel',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF262626),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_wallet,
                            color: Color(0xFFFFF5EE), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ledger',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFFFFF5EE),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: List.generate(5, (i) {
                      final isActive = i <= _currentPage;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                          height: 4,
                          decoration: BoxDecoration(
                            color: isActive
                                ? theme.colorScheme.primary
                                : const Color(0xFF2E2E2E),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step ${_currentPage + 1} of 5',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _Step1CTC(
                    controller: _ctcController,
                    takeHome:
                        finance.calculateTakeHome(_ctcLpa, 'new'),
                  ),
                  _Step2Hike(
                    hikePct: _hikePct,
                    onChanged: (v) => setState(() => _hikePct = v),
                  ),
                  _Step3City(
                    preset: _cityPreset,
                    rentController: _rentController,
                    foodController: _foodController,
                    transportController: _transportController,
                    miscController: _miscController,
                    onPresetChanged: (v) {
                      setState(() => _cityPreset = v);
                      _applyPreset(v);
                    },
                  ),
                  _Step4SIP(
                    sipPct: _sipPct,
                    takeHome: finance.calculateTakeHome(_ctcLpa, 'new'),
                    onChanged: (v) => setState(() => _sipPct = v),
                  ),
                  _Step5Goal(
                    nameController: _goalNameController,
                    amountController: _goalAmountController,
                    yearController: _goalYearController,
                    skip: _skipGoal,
                    onSkipChanged: (v) => setState(() => _skipGoal = v),
                  ),
                ],
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _prevPage,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage < 4 ? 'Continue' : 'Get Started',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1: CTC
// ─────────────────────────────────────────────────────────────────────────────
class _Step1CTC extends StatelessWidget {
  final TextEditingController controller;
  final double takeHome;

  const _Step1CTC({required this.controller, required this.takeHome});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What\'s your starting CTC?',
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Your annual cost-to-company in lakhs per annum.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 32),
          TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: 'CTC in LPA',
              suffixText: 'LPA',
              suffixStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF2E2E2E)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Take-Home (New Regime 2026)',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(
                  formatCurrency(takeHome),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text('After PF (12%) + income tax + 4% cess',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2: HIKE
// ─────────────────────────────────────────────────────────────────────────────
class _Step2Hike extends StatelessWidget {
  final double hikePct;
  final ValueChanged<double> onChanged;

  const _Step2Hike({required this.hikePct, required this.onChanged});

  String get _hikeLabel {
    if (hikePct <= 12) return 'Conservative (8–12%)';
    if (hikePct <= 18) return 'Good (13–18%)';
    return 'Aggressive job-hopper (19–30%)';
  }

  Color _hikeLabelColor(BuildContext context) {
    final colors = Theme.of(context).extension<LedgerColors>()!;
    if (hikePct <= 12) return colors.medium;
    if (hikePct <= 18) return colors.success;
    return colors.high;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Expected annual salary hike?',
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('This compounds your salary year-over-year.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 40),
          Center(
            child: Text(
              '${hikePct.toInt()}%',
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Slider(
            value: hikePct,
            min: 8,
            max: 30,
            divisions: 22,
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('8%', style: TextStyle(fontSize: 12)),
              Text('30%', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFF2E2E2E)),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up,
                    color: _hikeLabelColor(context), size: 20),
                const SizedBox(width: 12),
                Text(
                  _hikeLabel,
                  style: TextStyle(
                    color: _hikeLabelColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3: CITY
// ─────────────────────────────────────────────────────────────────────────────
class _Step3City extends StatelessWidget {
  final String preset;
  final TextEditingController rentController;
  final TextEditingController foodController;
  final TextEditingController transportController;
  final TextEditingController miscController;
  final ValueChanged<String> onPresetChanged;

  const _Step3City({
    required this.preset,
    required this.rentController,
    required this.foodController,
    required this.transportController,
    required this.miscController,
    required this.onPresetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom = preset == 'custom';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where are you based?', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('This sets your baseline monthly expenses.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            initialValue: preset,
            decoration: const InputDecoration(labelText: 'City / Living Situation'),
            dropdownColor: const Color(0xFF1E1E1E),
            items: const [
              DropdownMenuItem(
                  value: 'kolkata_home', child: Text('Kolkata (living at home)')),
              DropdownMenuItem(
                  value: 'kolkata_rent', child: Text('Kolkata (rented)')),
              DropdownMenuItem(value: 'metro', child: Text('Metro city')),
              DropdownMenuItem(value: 'custom', child: Text('Custom')),
            ],
            onChanged: (v) => onPresetChanged(v!),
          ),
          const SizedBox(height: 24),
          _ExpenseRow('Monthly Rent (₹)', rentController,
              enabled: isCustom || preset == 'kolkata_rent'),
          const SizedBox(height: 12),
          _ExpenseRow('Monthly Food (₹)', foodController, enabled: isCustom),
          const SizedBox(height: 12),
          _ExpenseRow('Transport (₹)', transportController, enabled: isCustom),
          const SizedBox(height: 12),
          _ExpenseRow('Misc / Personal (₹)', miscController, enabled: isCustom),
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;

  const _ExpenseRow(this.label, this.controller, {required this.enabled});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 4: SIP
// ─────────────────────────────────────────────────────────────────────────────
class _Step4SIP extends StatelessWidget {
  final double sipPct;
  final double takeHome;
  final ValueChanged<double> onChanged;

  const _Step4SIP({
    required this.sipPct,
    required this.takeHome,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sipMonthly = takeHome * (sipPct / 100);
    final corpus10 = finance.sipFutureValue(sipMonthly, 120, 0.12);
    final corpus20 = finance.sipFutureValue(sipMonthly, 240, 0.12);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How much goes to SIP?', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('% of monthly take-home invested in mutual funds.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Text(
                  '${sipPct.toInt()}%',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${formatCurrency(sipMonthly)}/month',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          Slider(
            value: sipPct,
            min: 10,
            max: 30,
            divisions: 20,
            onChanged: onChanged,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _CorpusCard(
                  label: '10-Year Corpus',
                  amount: corpus10,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CorpusCard(
                  label: '20-Year Corpus',
                  amount: corpus20,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('At 12% CAGR (historical Nifty 50 avg)',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _CorpusCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _CorpusCard(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            formatLakhsCrores(amount),
            style: theme.textTheme.titleLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 5: FIRST GOAL
// ─────────────────────────────────────────────────────────────────────────────
class _Step5Goal extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController amountController;
  final TextEditingController yearController;
  final bool skip;
  final ValueChanged<bool> onSkipChanged;

  const _Step5Goal({
    required this.nameController,
    required this.amountController,
    required this.yearController,
    required this.skip,
    required this.onSkipChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LedgerColors>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your first big goal', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('We\'ll track your path to making this happen.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.flag, color: colors.high, size: 20),
              const SizedBox(width: 8),
              Text('Goal Details',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: colors.high)),
            ],
          ),
          const SizedBox(height: 16),
          if (!skip) ...[
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Goal Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Amount (₹)',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Year (from now)',
                suffixText: 'years',
              ),
            ),
            const SizedBox(height: 8),
            Text('e.g. 7 means you want to achieve this in 7 years',
                style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Checkbox(
                value: skip,
                onChanged: (v) => onSkipChanged(v ?? false),
                activeColor: theme.colorScheme.primary,
              ),
              const Text('Skip — I\'ll add goals later'),
            ],
          ),
        ],
      ),
    );
  }
}
