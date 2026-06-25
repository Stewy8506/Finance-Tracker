import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

const _kBoxName = 'user_profile';

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null) {
    _load();
  }

  void _load() {
    final box = Hive.box<UserProfile>(_kBoxName);
    if (box.isNotEmpty) {
      state = box.getAt(0);
    } else {
      state = null;
    }
  }

  Future<void> save(UserProfile profile) async {
    final box = Hive.box<UserProfile>(_kBoxName);
    if (box.isEmpty) {
      await box.add(profile);
    } else {
      await box.putAt(0, profile);
    }
    state = profile;
  }

  Future<void> update(UserProfile Function(UserProfile) updater) async {
    if (state == null) return;
    await save(updater(state!));
  }

  Future<void> reset() async {
    final box = Hive.box<UserProfile>(_kBoxName);
    await box.clear();
    state = null;
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>(
  (ref) => UserProfileNotifier(),
);
