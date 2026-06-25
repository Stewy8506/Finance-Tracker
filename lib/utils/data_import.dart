import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/user_profile.dart';
import '../models/goal.dart';
import '../models/recurring_purchase.dart';
import '../models/assumptions.dart';
import '../models/income_source.dart';
import '../providers/user_profile_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/purchases_provider.dart';
import '../providers/assumptions_provider.dart';
import '../providers/income_provider.dart';

class ImportResult {
  final bool success;
  final String message;

  ImportResult(this.success, this.message);
}

Future<ImportResult> importFromJson(String jsonString, WidgetRef ref) async {
  try {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    
    if (!data.containsKey('profile') || !data.containsKey('assumptions')) {
      return ImportResult(false, 'Missing core sections (profile, assumptions)');
    }

    final profileData = data['profile'] as Map<String, dynamic>;
    final assumptionsData = data['assumptions'] as Map<String, dynamic>;
    
    final profile = UserProfile(
      startingCtcLpa: (profileData['startingCtcLpa'] as num).toDouble(),
      annualHikePct: (profileData['annualHikePct'] as num).toDouble(),
      taxRegime: profileData['taxRegime'] as String? ?? 'new',
      cityPreset: profileData['cityPreset'] as String? ?? 'custom',
      monthlyRent: (profileData['monthlyRent'] as num).toDouble(),
      monthlyFood: (profileData['monthlyFood'] as num).toDouble(),
      monthlyTransport: (profileData['monthlyTransport'] as num).toDouble(),
      monthlyMisc: (profileData['monthlyMisc'] as num).toDouble(),
      sipRatePct: (profileData['sipRatePct'] as num).toDouble(),
      onboardingComplete: true,
      emergencyFundBalance: (profileData['emergencyFundBalance'] as num?)?.toDouble() ?? 0,
      startYear: profileData['startYear'] as int? ?? DateTime.now().year,
      otherAssets: (profileData['otherAssets'] as num?)?.toDouble() ?? 0,
      liabilities: (profileData['liabilities'] as num?)?.toDouble() ?? 0,
      hikeBracketsRaw: profileData['hikeBracketsRaw'] as List<dynamic>?,
    );

    final assumptions = Assumptions(
      sipReturnRate: (assumptionsData['sipReturnRate'] as num).toDouble(),
      cashSavingsRate: (assumptionsData['cashSavingsRate'] as num).toDouble(),
      expenseInflation: (assumptionsData['expenseInflation'] as num).toDouble(),
      homeLoanRate: (assumptionsData['homeLoanRate'] as num).toDouble(),
      loanTenureYears: assumptionsData['loanTenureYears'] as int? ?? 20,
    );

    final goals = <Goal>[];
    if (data.containsKey('goals')) {
      final goalsList = data['goals'] as List<dynamic>;
      for (final g in goalsList) {
        final map = g as Map<String, dynamic>;
        goals.add(Goal(
          id: map['id'] as String,
          name: map['name'] as String,
          targetAmount: (map['targetAmount'] as num).toDouble(),
          targetYear: map['targetYear'] as int,
          type: map['type'] as String,
          priority: map['priority'] as String,
          adjustForInflation: map['adjustForInflation'] as bool? ?? false,
          propertyValue: (map['propertyValue'] as num?)?.toDouble(),
          downPaymentPct: (map['downPaymentPct'] as num?)?.toDouble(),
        ));
      }
    }

    final purchases = <RecurringPurchase>[];
    if (data.containsKey('purchases')) {
      final purchasesList = data['purchases'] as List<dynamic>;
      for (final p in purchasesList) {
        final map = p as Map<String, dynamic>;
        purchases.add(RecurringPurchase(
          id: map['id'] as String,
          name: map['name'] as String,
          amount: (map['amount'] as num).toDouble(),
          firstYear: map['firstYear'] as int,
          recurEveryNYears: map['recurEveryNYears'] as int?,
          category: map['category'] as String,
        ));
      }
    }

    final incomeSources = <IncomeSource>[];
    if (data.containsKey('incomeSources')) {
      final sourcesList = data['incomeSources'] as List<dynamic>;
      for (final s in sourcesList) {
        final map = s as Map<String, dynamic>;
        incomeSources.add(IncomeSource(
          id: map['id'] as String,
          label: map['label'] as String,
          monthlyAmount: (map['monthlyAmount'] as num).toDouble(),
          annualGrowthPct: (map['annualGrowthPct'] as num).toDouble(),
        ));
      }
    }

    await ref.read(userProfileProvider.notifier).save(profile);
    await ref.read(assumptionsProvider.notifier).save(assumptions);
    
    final goalsBox = Hive.box<Goal>('goals');
    await goalsBox.clear();
    for (final g in goals) {
      await goalsBox.put(g.id, g);
    }
    // Update Riverpod state for goals
    ref.read(goalsProvider.notifier).load();

    final purchasesBox = Hive.box<RecurringPurchase>('purchases');
    await purchasesBox.clear();
    for (final p in purchases) {
      await purchasesBox.put(p.id, p);
    }
    // Update Riverpod state for purchases
    ref.read(purchasesProvider.notifier).load();

    final incomeBox = Hive.box<IncomeSource>('income_sources');
    await incomeBox.clear();
    for (final s in incomeSources) {
      await incomeBox.put(s.id, s);
    }
    // Update Riverpod state for income sources
    ref.read(incomeSourcesProvider.notifier).load();

    return ImportResult(true, 'Data successfully imported!');
  } catch (e) {
    return ImportResult(false, 'Parse error: ${e.toString()}');
  }
}
