import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  double startingCtcLpa;

  @HiveField(1)
  double annualHikePct; // e.g. 0.12 for 12%

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
  });

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
