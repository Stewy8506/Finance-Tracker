import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/suggestion_history.dart';

const _kBoxName = 'suggestion_history';

class SuggestionHistoryNotifier extends StateNotifier<List<SuggestionHistoryEntry>> {
  SuggestionHistoryNotifier() : super([]) {
    load();
  }

  void load() {
    final box = Hive.box<SuggestionHistoryEntry>(_kBoxName);
    state = box.values.toList();
  }

  Future<void> add(SuggestionHistoryEntry entry) async {
    final box = Hive.box<SuggestionHistoryEntry>(_kBoxName);
    await box.add(entry);
    state = box.values.toList();
  }

  Future<void> addAll(List<SuggestionHistoryEntry> entries) async {
    final box = Hive.box<SuggestionHistoryEntry>(_kBoxName);
    await box.addAll(entries);
    state = box.values.toList();
  }

  Future<void> clearAll() async {
    final box = Hive.box<SuggestionHistoryEntry>(_kBoxName);
    await box.clear();
    state = [];
  }
}

final suggestionHistoryProvider =
    StateNotifierProvider<SuggestionHistoryNotifier, List<SuggestionHistoryEntry>>(
  (ref) => SuggestionHistoryNotifier(),
);
