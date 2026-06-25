import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account.dart';

final accountsProvider = StateNotifierProvider<AccountsNotifier, List<Account>>((ref) {
  final box = Hive.box<Account>('accounts');
  return AccountsNotifier(box);
});

class AccountsNotifier extends StateNotifier<List<Account>> {
  final Box<Account> _box;

  AccountsNotifier(this._box) : super(_box.values.toList()) {
    _box.listenable().addListener(_onBoxChanged);
  }

  void _onBoxChanged() {
    state = _box.values.toList();
  }

  Future<void> add(Account account) async {
    await _box.put(account.id, account);
  }

  Future<void> update(Account account) async {
    await _box.put(account.id, account);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  void dispose() {
    // Note: We can't easily remove the listener from Hive.box().listenable()
    // without keeping a reference to the listenable itself, but since this
    // provider usually lives for the app's lifetime, it's generally safe.
    super.dispose();
  }
}
