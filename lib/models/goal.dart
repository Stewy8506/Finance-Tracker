import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 1)
class Goal extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double targetAmount;

  @HiveField(3)
  int targetYear; // years from start (1-indexed)

  @HiveField(4)
  String type; // 'purchase' | 'down_payment' | 'corpus'

  @HiveField(5)
  String priority; // 'high' | 'medium' | 'low'

  @HiveField(6)
  double? propertyValue;

  @HiveField(7)
  double? downPaymentPct;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.targetYear,
    required this.type,
    required this.priority,
    this.propertyValue,
    this.downPaymentPct,
  });

  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    int? targetYear,
    String? type,
    String? priority,
    double? propertyValue,
    double? downPaymentPct,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      targetYear: targetYear ?? this.targetYear,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      propertyValue: propertyValue ?? this.propertyValue,
      downPaymentPct: downPaymentPct ?? this.downPaymentPct,
    );
  }
}
