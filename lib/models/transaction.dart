import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 6)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String accountId;

  @HiveField(2)
  String? toAccountId; // null unless type == 'transfer'

  @HiveField(3)
  String type; // 'income', 'expense', 'transfer'

  @HiveField(4)
  double amount;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String? categoryId; // 'Food', 'Salary', 'Rent', etc.

  @HiveField(7)
  String? note;

  Transaction({
    required this.id,
    required this.accountId,
    this.toAccountId,
    required this.type,
    required this.amount,
    required this.date,
    this.categoryId,
    this.note,
  });

  Transaction copyWith({
    String? id,
    String? accountId,
    String? toAccountId,
    String? type,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
    );
  }
}
