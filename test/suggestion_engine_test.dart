import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/finance.dart' as finance;
import 'package:ledger/models/goal.dart';
import 'package:ledger/models/user_profile.dart';
import 'package:ledger/models/recurring_purchase.dart';
import 'package:ledger/models/assumptions.dart';
import 'package:ledger/models/suggestion.dart';
import 'package:ledger/suggestion_engine.dart';

void main() {
  group('Suggestion Engine Tests', () {
    late UserProfile defaultProfile;
    late Assumptions defaultAssumptions;

    setUp(() {
      defaultProfile = UserProfile(
        startingCtcLpa: 12.0, // 12 LPA -> ~90k take home
        annualHikePct: 0.10,
        taxRegime: 'new',
        cityPreset: 'custom',
        monthlyRent: 15000,
        monthlyFood: 10000,
        monthlyTransport: 5000,
        monthlyMisc: 5000, // Total expense = 35000
        sipRatePct: 0.15,  // SIP = ~13.5k
        onboardingComplete: true,
      );

      defaultAssumptions = Assumptions.defaults();
    });

    test('Deficit Resolver Analyzer', () {
      // Create a huge cash purchase in Year 1 that causes a deficit
      final purchases = [
        RecurringPurchase(
          id: 'p1',
          name: 'Superbike',
          amount: 800000,
          firstYear: 1,
          category: 'Lifestyle',
          targetMonth: 3,
        ),
      ];

      final projections = finance.generateProjection(
        defaultProfile,
        [],
        purchases,
        defaultAssumptions,
      );

      final suggestions = generateSuggestions(
        profile: defaultProfile,
        purchases: purchases,
        goals: [],
        assumptions: defaultAssumptions,
        incomeSources: [],
        projections: projections,
      );

      // Should suggest converting to EMI and/or delaying
      expect(suggestions, isNotEmpty);
      final hasEmiOrDelay = suggestions.any(
        (s) => s.type == SuggestionType.convertToEmi || s.type == SuggestionType.delayPurchase,
      );
      expect(hasEmiOrDelay, isTrue);
    });

    test('Monthly Clustering Detector', () {
      // 2 purchases in the same month in Year 1
      final purchases = [
        RecurringPurchase(
          id: 'p1',
          name: 'Laptop',
          amount: 50000,
          firstYear: 1,
          category: 'Tech',
          targetMonth: 0, // January
        ),
        RecurringPurchase(
          id: 'p2',
          name: 'Phone',
          amount: 30000,
          firstYear: 1,
          category: 'Tech',
          targetMonth: 0, // January
        ),
      ];

      final projections = finance.generateProjection(
        defaultProfile,
        [],
        purchases,
        defaultAssumptions,
      );

      final suggestions = generateSuggestions(
        profile: defaultProfile,
        purchases: purchases,
        goals: [],
        assumptions: defaultAssumptions,
        incomeSources: [],
        projections: projections,
      );

      final hasSpread = suggestions.any((s) => s.type == SuggestionType.spreadMonths);
      expect(hasSpread, isTrue);
    });

    test('EMI Optimization - High Interest on Small Purchase', () {
      // Purchase is small (₹20,000) but has a high EMI interest rate (18%)
      final purchases = [
        RecurringPurchase(
          id: 'p1',
          name: 'Headphones',
          amount: 20000,
          firstYear: 1,
          category: 'Tech',
          targetMonth: 2,
          emiMonths: 12,
          emiInterestRate: 0.18,
        ),
      ];

      final projections = finance.generateProjection(
        defaultProfile,
        [],
        purchases,
        defaultAssumptions,
      );

      final suggestions = generateSuggestions(
        profile: defaultProfile,
        purchases: purchases,
        goals: [],
        assumptions: defaultAssumptions,
        incomeSources: [],
        projections: projections,
      );

      final hasReduceInterest = suggestions.any((s) => s.type == SuggestionType.reduceInterest);
      expect(hasReduceInterest, isTrue);
    });

    test('EMI Optimization - Overlapping EMIs', () {
      // Two overlapping EMI purchases in Year 1
      final purchases = [
        RecurringPurchase(
          id: 'p1',
          name: 'MacBook',
          amount: 150000,
          firstYear: 1,
          category: 'Tech',
          targetMonth: 0,
          emiMonths: 12,
          emiInterestRate: 0.10,
        ),
        RecurringPurchase(
          id: 'p2',
          name: 'iPhone',
          amount: 100000,
          firstYear: 1,
          category: 'Tech',
          targetMonth: 0,
          emiMonths: 12,
          emiInterestRate: 0.10,
        ),
      ];

      final projections = finance.generateProjection(
        defaultProfile,
        [],
        purchases,
        defaultAssumptions,
      );

      final suggestions = generateSuggestions(
        profile: defaultProfile,
        purchases: purchases,
        goals: [],
        assumptions: defaultAssumptions,
        incomeSources: [],
        projections: projections,
      );

      final hasStagger = suggestions.any((s) => s.type == SuggestionType.staggerEmis);
      expect(hasStagger, isTrue);
    });

    test('Income-Timing Optimizer', () {
      // Huge purchase in Year 1, with a massive salary hike in Year 2
      final profileWithLargeHike = UserProfile(
        startingCtcLpa: 10.0,
        annualHikePct: 0.30, // 30% hike in Year 2
        taxRegime: 'new',
        cityPreset: 'custom',
        monthlyRent: 10000,
        monthlyFood: 5000,
        monthlyTransport: 2000,
        monthlyMisc: 3000,
        sipRatePct: 0.10,
        onboardingComplete: true,
      );

      final purchases = [
        RecurringPurchase(
          id: 'p1',
          name: 'Car Down Payment',
          amount: 300000,
          firstYear: 1,
          category: 'Lifestyle',
          targetMonth: 2,
        ),
      ];

      final projections = finance.generateProjection(
        profileWithLargeHike,
        [],
        purchases,
        defaultAssumptions,
      );

      final suggestions = generateSuggestions(
        profile: profileWithLargeHike,
        purchases: purchases,
        goals: [],
        assumptions: defaultAssumptions,
        incomeSources: [],
        projections: projections,
      );

      final hasIncomeAlign = suggestions.any((s) => s.type == SuggestionType.incomeAlign);
      expect(hasIncomeAlign, isTrue);
    });

    test('Spending Spike Detector', () {
      // Huge spending in Year 3 compared to Year 2 and Year 4
      final purchases = [
        RecurringPurchase(
          id: 'p1',
          name: 'Year 3 TV',
          amount: 500000,
          firstYear: 3,
          category: 'Lifestyle',
          targetMonth: 1,
        ),
      ];

      final projections = finance.generateProjection(
        defaultProfile,
        [],
        purchases,
        defaultAssumptions,
      );

      final suggestions = generateSuggestions(
        profile: defaultProfile,
        purchases: purchases,
        goals: [],
        assumptions: defaultAssumptions,
        incomeSources: [],
        projections: projections,
      );

      final hasLevelSpike = suggestions.any((s) => s.type == SuggestionType.levelSpike);
      expect(hasLevelSpike, isTrue);
    });

    test('Goal Conflict Detector', () {
      // High-priority goal in Year 2, with a large purchase in Year 2
      final goals = [
        Goal(
          id: 'g1',
          name: 'Emergency Fund Goal',
          targetAmount: 200000,
          targetYear: 2,
          type: 'corpus',
          priority: 'high',
        ),
      ];

      final purchases = [
        RecurringPurchase(
          id: 'p1',
          name: 'Europe Trip',
          amount: 150000,
          firstYear: 2,
          category: 'Travel',
          targetMonth: 5,
        ),
      ];

      final projections = finance.generateProjection(
        defaultProfile,
        goals,
        purchases,
        defaultAssumptions,
      );

      final suggestions = generateSuggestions(
        profile: defaultProfile,
        purchases: purchases,
        goals: goals,
        assumptions: defaultAssumptions,
        incomeSources: [],
        projections: projections,
      );

      final hasGoalConflict = suggestions.any((s) => s.type == SuggestionType.goalConflict);
      expect(hasGoalConflict, isTrue);
    });

    test('Combo Suggestion Solver', () {
      final purchases = [
        RecurringPurchase(
          id: 'p1',
          name: 'Laptop',
          amount: 80000,
          firstYear: 1,
          category: 'Tech',
          targetMonth: 2,
        ),
        RecurringPurchase(
          id: 'p2',
          name: 'Mobile',
          amount: 60000,
          firstYear: 1,
          category: 'Tech',
          targetMonth: 3,
        ),
      ];

      final profile = UserProfile(
        startingCtcLpa: 6.0,
        annualHikePct: 0.10,
        taxRegime: 'new',
        cityPreset: 'custom',
        monthlyRent: 25000,
        monthlyFood: 10000,
        monthlyTransport: 5000,
        monthlyMisc: 5000,
        sipRatePct: 0.05,
        onboardingComplete: true,
      );

      final projections = finance.generateProjection(
        profile,
        [],
        purchases,
        defaultAssumptions,
      );

      final suggestions = generateSuggestions(
        profile: profile,
        purchases: purchases,
        goals: [],
        assumptions: defaultAssumptions,
        incomeSources: [],
        projections: projections,
      );

      final hasCombo = suggestions.any((s) => s.type == SuggestionType.combo);
      expect(hasCombo, isTrue);
    });

    test('Opportunity Cost Calculator', () {
      final purchases = [
        RecurringPurchase(
          id: 'p1',
          name: 'Big Screen TV',
          amount: 80000,
          firstYear: 1,
          category: 'Tech',
          targetMonth: 0,
        ),
      ];

      final projections = finance.generateProjection(
        defaultProfile,
        [],
        purchases,
        defaultAssumptions,
      );

      final suggestions = generateSuggestions(
        profile: defaultProfile,
        purchases: purchases,
        goals: [],
        assumptions: defaultAssumptions,
        incomeSources: [],
        projections: projections,
      );

      final hasOpp = suggestions.any((s) => s.type == SuggestionType.opportunityCost);
      expect(hasOpp, isTrue);
    });

    test('Skip & Invest Advisor', () {
      final purchases = [
        RecurringPurchase(
          id: 'p1',
          name: 'Tech Gadget',
          amount: 30000,
          firstYear: 1,
          category: 'Tech',
          targetMonth: 1,
        ),
        RecurringPurchase(
          id: 'p2',
          name: 'Super Expensive Bike',
          amount: 600000,
          firstYear: 1,
          category: 'Lifestyle',
          targetMonth: 2,
        ),
      ];

      final projections = finance.generateProjection(
        defaultProfile,
        [],
        purchases,
        defaultAssumptions,
      );

      final suggestions = generateSuggestions(
        profile: defaultProfile,
        purchases: purchases,
        goals: [],
        assumptions: defaultAssumptions,
        incomeSources: [],
        projections: projections,
      );

      final hasSkip = suggestions.any((s) => s.type == SuggestionType.skipAndInvest);
      expect(hasSkip, isTrue);
    });

    test('SIP Flex Advisor', () {
      final profile = UserProfile(
        startingCtcLpa: 12.0,
        annualHikePct: 0.10,
        taxRegime: 'new',
        cityPreset: 'custom',
        monthlyRent: 20000,
        monthlyFood: 10000,
        monthlyTransport: 5000,
        monthlyMisc: 5000,
        sipRatePct: 0.20,
        onboardingComplete: true,
      );

      final purchases = [
        RecurringPurchase(
          id: 'p1',
          name: 'Holiday Trip',
          amount: 470000,
          firstYear: 1,
          category: 'Travel',
          targetMonth: 1,
        ),
      ];

      final projections = finance.generateProjection(
        profile,
        [],
        purchases,
        defaultAssumptions,
      );

      final suggestions = generateSuggestions(
        profile: profile,
        purchases: purchases,
        goals: [],
        assumptions: defaultAssumptions,
        incomeSources: [],
        projections: projections,
      );

      final hasSipFlex = suggestions.any((s) => s.type == SuggestionType.reduceSip);
      expect(hasSipFlex, isTrue);
    });

    test('Purchase Affordability Score', () {
      final purchases = [
        RecurringPurchase(
          id: 'p1',
          name: 'Cheap Gadget',
          amount: 5000,
          firstYear: 1,
          category: 'Tech',
          targetMonth: 1,
        ),
        RecurringPurchase(
          id: 'p2',
          name: 'Huge Luxury Bike',
          amount: 900000,
          firstYear: 1,
          category: 'Lifestyle',
          targetMonth: 2,
        ),
      ];

      final projections = finance.generateProjection(
        defaultProfile,
        [],
        purchases,
        defaultAssumptions,
      );

      final scoreCheap = purchaseAffordabilityScore(purchases[0], projections);
      final scoreExp = purchaseAffordabilityScore(purchases[1], projections);

      expect(scoreCheap, greaterThan(80.0));
      expect(scoreExp, lessThan(40.0));
    });

    test('Best Month Calculator', () {
      final otherPurchases = [
        RecurringPurchase(
          id: 'p1',
          name: 'Trip 1',
          amount: 100000,
          firstYear: 1,
          category: 'Travel',
          targetMonth: 0,
        ),
      ];

      final newPurchase = RecurringPurchase(
        id: 'p2',
        name: 'Trip 2',
        amount: 80000,
        firstYear: 1,
        category: 'Travel',
        targetMonth: 0,
      );

      final bestMonth = bestMonthForPurchase(newPurchase, otherPurchases);
      expect(bestMonth, isNot(equals(0)));
    });
  });
}
