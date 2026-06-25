import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 5)
class Account extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type; // 'bank', 'credit_card', 'cash', 'investment'

  @HiveField(3)
  double balance;

  @HiveField(4)
  int color; // hex code for UI representation

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.color,
  });

  Account copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    int? color,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      color: color ?? this.color,
    );
  }
}
