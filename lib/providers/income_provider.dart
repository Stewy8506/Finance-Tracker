import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/income_source.dart';

final incomeSourcesProvider =
    StateNotifierProvider<IncomeSourcesNotifier, List<IncomeSource>>((ref) {
  return IncomeSourcesNotifier();
});

class IncomeSourcesNotifier extends StateNotifier<List<IncomeSource>> {
  late final Box<IncomeSource> _box;

  IncomeSourcesNotifier() : super([]) {
    _box = Hive.box<IncomeSource>('income_sources');
    load();
  }

  void load() {
    state = _box.values.toList();
  }

  void add(IncomeSource source) {
    _box.put(source.id, source);
    state = _box.values.toList();
  }

  void update(IncomeSource source) {
    _box.put(source.id, source);
    state = _box.values.toList();
  }

  void delete(String id) {
    _box.delete(id);
    state = _box.values.toList();
  }

  void addNew({
    required String label,
    required double monthlyAmount,
    required double annualGrowthPct,
  }) {
    final source = IncomeSource(
      id: const Uuid().v4(),
      label: label,
      monthlyAmount: monthlyAmount,
      annualGrowthPct: annualGrowthPct,
    );
    add(source);
  }
}
