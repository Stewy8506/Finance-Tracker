import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/assumptions.dart';

const _kBoxName = 'assumptions';

class AssumptionsNotifier extends StateNotifier<Assumptions> {
  AssumptionsNotifier() : super(Assumptions.defaults()) {
    _load();
  }

  void _load() {
    final box = Hive.box<Assumptions>(_kBoxName);
    if (box.isNotEmpty) {
      state = box.getAt(0)!;
    }
  }

  Future<void> save(Assumptions assumptions) async {
    final box = Hive.box<Assumptions>(_kBoxName);
    if (box.isEmpty) {
      await box.add(assumptions);
    } else {
      await box.putAt(0, assumptions);
    }
    state = assumptions;
  }

  Future<void> update(Assumptions Function(Assumptions) updater) async {
    await save(updater(state));
  }

  Future<void> reset() async {
    final box = Hive.box<Assumptions>(_kBoxName);
    await box.clear();
    state = Assumptions.defaults();
  }
}

final assumptionsProvider =
    StateNotifierProvider<AssumptionsNotifier, Assumptions>(
  (ref) => AssumptionsNotifier(),
);
