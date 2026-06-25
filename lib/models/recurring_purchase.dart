import 'package:hive/hive.dart';

part 'recurring_purchase.g.dart';

@HiveType(typeId: 2)
class RecurringPurchase extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double amount;

  @HiveField(3)
  int firstYear; // year from now (1-indexed)

  @HiveField(4)
  int? recurEveryNYears; // null = one-time

  @HiveField(5)
  String category; // 'Tech' | 'Travel' | 'Lifestyle' | 'Health' | 'Education'

  @HiveField(6)
  String? note;

  @HiveField(7)
  int? targetMonth; // 0-11 (Jan-Dec)

  RecurringPurchase({
    required this.id,
    required this.name,
    required this.amount,
    required this.firstYear,
    this.recurEveryNYears,
    required this.category,
    this.note,
    this.targetMonth,
  });

  RecurringPurchase copyWith({
    String? id,
    String? name,
    double? amount,
    int? firstYear,
    int? recurEveryNYears,
    String? category,
    String? note,
    int? targetMonth,
  }) {
    return RecurringPurchase(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      firstYear: firstYear ?? this.firstYear,
      recurEveryNYears: recurEveryNYears ?? this.recurEveryNYears,
      category: category ?? this.category,
      note: note ?? this.note,
      targetMonth: targetMonth ?? this.targetMonth,
    );
  }

  String get recurrenceLabel {
    if (recurEveryNYears == null) return 'One-time';
    if (recurEveryNYears == 1) return 'Every year';
    return 'Every $recurEveryNYears years';
  }

  int nextOccurrence(int fromYear) {
    if (fromYear < firstYear) return firstYear;
    if (recurEveryNYears == null) return firstYear;
    final elapsed = fromYear - firstYear;
    final cycles = (elapsed / recurEveryNYears!).ceil();
    return firstYear + cycles * recurEveryNYears!;
  }
}
