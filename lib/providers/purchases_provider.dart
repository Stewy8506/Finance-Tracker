import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/recurring_purchase.dart';

const _kBoxName = 'purchases';

class PurchasesNotifier extends StateNotifier<List<RecurringPurchase>> {
  PurchasesNotifier() : super([]) {
    _load();
  }

  void _load() {
    final box = Hive.box<RecurringPurchase>(_kBoxName);
    state = box.values.toList();
  }

  Future<void> add(RecurringPurchase purchase) async {
    final box = Hive.box<RecurringPurchase>(_kBoxName);
    await box.put(purchase.id, purchase);
    state = box.values.toList();
  }

  Future<void> update(RecurringPurchase purchase) async {
    final box = Hive.box<RecurringPurchase>(_kBoxName);
    await box.put(purchase.id, purchase);
    state = box.values.toList();
  }

  Future<void> delete(String id) async {
    final box = Hive.box<RecurringPurchase>(_kBoxName);
    await box.delete(id);
    state = box.values.toList();
  }

  Future<void> addAll(List<RecurringPurchase> purchases) async {
    final box = Hive.box<RecurringPurchase>(_kBoxName);
    final map = {for (final p in purchases) p.id: p};
    await box.putAll(map);
    state = box.values.toList();
  }

  Future<void> reset() async {
    final box = Hive.box<RecurringPurchase>(_kBoxName);
    await box.clear();
    state = [];
  }
}

final purchasesProvider =
    StateNotifierProvider<PurchasesNotifier, List<RecurringPurchase>>(
  (ref) => PurchasesNotifier(),
);
