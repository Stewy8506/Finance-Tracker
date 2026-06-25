import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import 'accounts_provider.dart';

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, List<Transaction>>((ref) {
  final box = Hive.box<Transaction>('transactions');
  return TransactionsNotifier(box, ref);
});

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  final Box<Transaction> _box;
  final Ref _ref;

  TransactionsNotifier(this._box, this._ref) : super(_box.values.toList()..sort((a, b) => b.date.compareTo(a.date))) {
    _box.listenable().addListener(_onBoxChanged);
  }

  void _onBoxChanged() {
    final list = _box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // descending order
    state = list;
  }

  Future<void> add(Transaction transaction) async {
    await _box.put(transaction.id, transaction);
    _applyTransactionToAccount(transaction, isRevert: false);
  }

  Future<void> updateTransaction(Transaction oldTx, Transaction newTx) async {
    // Revert old effect
    _applyTransactionToAccount(oldTx, isRevert: true);
    // Apply new effect
    await _box.put(newTx.id, newTx);
    _applyTransactionToAccount(newTx, isRevert: false);
  }

  Future<void> delete(String id) async {
    final tx = _box.get(id);
    if (tx != null) {
      _applyTransactionToAccount(tx, isRevert: true);
      await _box.delete(id);
    }
  }

  void _applyTransactionToAccount(Transaction tx, {required bool isRevert}) {
    final accountsNotifier = _ref.read(accountsProvider.notifier);
    final accounts = _ref.read(accountsProvider);

    final multiplier = isRevert ? -1 : 1;

    // Handle from account
    final fromAccount = accounts.where((a) => a.id == tx.accountId).firstOrNull;
    if (fromAccount != null) {
      double change = 0;
      if (tx.type == 'income') {
        change = tx.amount * multiplier;
      } else if (tx.type == 'expense' || tx.type == 'transfer') {
        change = -tx.amount * multiplier;
      }
      
      accountsNotifier.update(fromAccount.copyWith(
        balance: fromAccount.balance + change,
      ));
    }

    // Handle to account (for transfers)
    if (tx.type == 'transfer' && tx.toAccountId != null) {
      final toAccount = accounts.where((a) => a.id == tx.toAccountId).firstOrNull;
      if (toAccount != null) {
        final change = tx.amount * multiplier;
        accountsNotifier.update(toAccount.copyWith(
          balance: toAccount.balance + change,
        ));
      }
    }
  }
}
