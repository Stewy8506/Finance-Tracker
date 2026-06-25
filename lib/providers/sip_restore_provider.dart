import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sip_restore.dart';

const _kBoxName = 'sip_restore';

class SipRestoreNotifier extends StateNotifier<List<SipRestore>> {
  SipRestoreNotifier() : super([]) {
    load();
  }

  void load() {
    final box = Hive.box<SipRestore>(_kBoxName);
    state = box.values.toList();
  }

  Future<void> add(SipRestore restore) async {
    final box = Hive.box<SipRestore>(_kBoxName);
    await box.add(restore);
    state = box.values.toList();
  }

  Future<void> clearAll() async {
    final box = Hive.box<SipRestore>(_kBoxName);
    await box.clear();
    state = [];
  }
}

final sipRestoreProvider =
    StateNotifierProvider<SipRestoreNotifier, List<SipRestore>>(
  (ref) => SipRestoreNotifier(),
);
