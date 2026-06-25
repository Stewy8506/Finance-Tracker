import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/goal.dart';

const _kBoxName = 'goals';

class GoalsNotifier extends StateNotifier<List<Goal>> {
  GoalsNotifier() : super([]) {
    load();
  }

  void load() {
    final box = Hive.box<Goal>(_kBoxName);
    state = box.values.toList();
  }

  Future<void> add(Goal goal) async {
    final box = Hive.box<Goal>(_kBoxName);
    await box.put(goal.id, goal);
    state = box.values.toList();
  }

  Future<void> update(Goal goal) async {
    final box = Hive.box<Goal>(_kBoxName);
    await box.put(goal.id, goal);
    state = box.values.toList();
  }

  Future<void> delete(String id) async {
    final box = Hive.box<Goal>(_kBoxName);
    await box.delete(id);
    state = box.values.toList();
  }

  Future<void> reset() async {
    final box = Hive.box<Goal>(_kBoxName);
    await box.clear();
    state = [];
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, List<Goal>>(
  (ref) => GoalsNotifier(),
);
