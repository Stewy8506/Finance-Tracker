import 'package:hive/hive.dart';

part 'user_profile.g.dart';

/// Represents a salary hike bracket: a range of years and the hike % for that range.
class HikeBracket {
  final int fromYear; // inclusive, 1-indexed
  final int toYear;   // inclusive (use 99 for "forever")
  final double hikePct; // e.g. 0.20 for 20%

  const HikeBracket({
    required this.fromYear,
    required this.toYear,
    required this.hikePct,
  });

  Map<String, dynamic> toMap() => {
    'fromYear': fromYear,
    'toYear': toYear,
    'hikePct': hikePct,
  };

  factory HikeBracket.fromMap(Map<dynamic, dynamic> map) => HikeBracket(
    fromYear: map['fromYear'] as int,
    toYear: map['toYear'] as int,
    hikePct: (map['hikePct'] as num).toDouble(),
  );

  String get label {
    if (toYear >= 99) return 'Year $fromYear+';
    return 'Year $fromYear–$toYear';
  }
}

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  double startingCtcLpa;

  @HiveField(1)
  double annualHikePct; // e.g. 0.12 for 12% — fallback when hikeBrackets is empty

  @HiveField(2)
  String taxRegime; // 'new' | 'old'

  @HiveField(3)
  String cityPreset; // 'kolkata_home' | 'kolkata_rent' | 'metro' | 'custom'

  @HiveField(4)
  double monthlyRent;

  @HiveField(5)
  double monthlyFood;

  @HiveField(6)
  double monthlyTransport;

  @HiveField(7)
  double monthlyMisc;

  @HiveField(8)
  double sipRatePct; // e.g. 0.15 for 15%

  @HiveField(9)
  bool onboardingComplete;

  /// Stepped hike brackets. Serialized as List<Map> for Hive compatibility.
  /// Empty list means use flat `annualHikePct`.
  @HiveField(10)
  List<dynamic>? hikeBracketsRaw;

  /// Emergency fund balance in ₹.
  @HiveField(11)
  double? emergencyFundBalance;

  /// The calendar year when the user started tracking (e.g. 2026).
  @HiveField(12)
  int? startYear;

  /// Other assets (gold, FDs, etc.) for net worth calculation.
  @HiveField(13)
  double? otherAssets;

  /// Total liabilities (education loans, etc.) for net worth calculation.
  @HiveField(14)
  double? liabilities;

  /// The navigation bar style selection: 'expand' or 'icons_only'
  @HiveField(15)
  String? navbarStyle;

  /// Settings toggle to show/hide opportunity cost cards
  @HiveField(16)
  bool? showOpportunityCost;

  UserProfile({
    required this.startingCtcLpa,
    required this.annualHikePct,
    required this.taxRegime,
    required this.cityPreset,
    required this.monthlyRent,
    required this.monthlyFood,
    required this.monthlyTransport,
    required this.monthlyMisc,
    required this.sipRatePct,
    required this.onboardingComplete,
    this.hikeBracketsRaw,
    this.emergencyFundBalance,
    this.startYear,
    this.otherAssets,
    this.liabilities,
    this.navbarStyle,
    this.showOpportunityCost = true,
  });

  // ── Hike bracket helpers ──────────────────────────────────────────────

  List<HikeBracket> get hikeBrackets {
    if (hikeBracketsRaw == null || hikeBracketsRaw!.isEmpty) return [];
    return hikeBracketsRaw!
        .map((e) => HikeBracket.fromMap(e as Map<dynamic, dynamic>))
        .toList();
  }

  set hikeBrackets(List<HikeBracket> brackets) {
    hikeBracketsRaw = brackets.map((b) => b.toMap()).toList();
  }

  /// Returns the hike rate for a given year.
  /// Falls back to flat `annualHikePct` if no brackets are defined.
  double hikeRateForYear(int year) {
    final brackets = hikeBrackets;
    if (brackets.isEmpty) return annualHikePct;
    for (final b in brackets) {
      if (year >= b.fromYear && year <= b.toYear) return b.hikePct;
    }
    // If year is beyond all brackets, use the last bracket's rate
    return brackets.last.hikePct;
  }

  // ── Default hike brackets ─────────────────────────────────────────────

  static List<HikeBracket> defaultHikeBrackets(double fallbackPct) => [
    HikeBracket(fromYear: 1, toYear: 3, hikePct: fallbackPct),
    HikeBracket(fromYear: 4, toYear: 7, hikePct: fallbackPct * 0.8),
    HikeBracket(fromYear: 8, toYear: 99, hikePct: fallbackPct * 0.6),
  ];

  UserProfile copyWith({
    double? startingCtcLpa,
    double? annualHikePct,
    String? taxRegime,
    String? cityPreset,
    double? monthlyRent,
    double? monthlyFood,
    double? monthlyTransport,
    double? monthlyMisc,
    double? sipRatePct,
    bool? onboardingComplete,
    List<dynamic>? hikeBracketsRaw,
    double? emergencyFundBalance,
    int? startYear,
    double? otherAssets,
    double? liabilities,
    String? navbarStyle,
    bool? showOpportunityCost,
  }) {
    return UserProfile(
      startingCtcLpa: startingCtcLpa ?? this.startingCtcLpa,
      annualHikePct: annualHikePct ?? this.annualHikePct,
      taxRegime: taxRegime ?? this.taxRegime,
      cityPreset: cityPreset ?? this.cityPreset,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      monthlyFood: monthlyFood ?? this.monthlyFood,
      monthlyTransport: monthlyTransport ?? this.monthlyTransport,
      monthlyMisc: monthlyMisc ?? this.monthlyMisc,
      sipRatePct: sipRatePct ?? this.sipRatePct,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      hikeBracketsRaw: hikeBracketsRaw ?? this.hikeBracketsRaw,
      emergencyFundBalance: emergencyFundBalance ?? this.emergencyFundBalance,
      startYear: startYear ?? this.startYear,
      otherAssets: otherAssets ?? this.otherAssets,
      liabilities: liabilities ?? this.liabilities,
      navbarStyle: navbarStyle ?? this.navbarStyle,
      showOpportunityCost: showOpportunityCost ?? this.showOpportunityCost,
    );
  }

  // City preset defaults
  static Map<String, dynamic> presetExpenses(String preset) {
    switch (preset) {
      case 'kolkata_home':
        return {
          'rent': 0.0,
          'food': 8000.0,
          'transport': 3000.0,
          'misc': 5000.0,
        };
      case 'kolkata_rent':
        return {
          'rent': 15000.0,
          'food': 8000.0,
          'transport': 3000.0,
          'misc': 5000.0,
        };
      case 'metro':
        return {
          'rent': 35000.0,
          'food': 15000.0,
          'transport': 6000.0,
          'misc': 10000.0,
        };
      default:
        return {
          'rent': 0.0,
          'food': 10000.0,
          'transport': 4000.0,
          'misc': 6000.0,
        };
    }
  }
}
