import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../utils/currency_formatter.dart';
import 'widgets/add_account_sheet.dart';
import 'widgets/add_transaction_sheet.dart';

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ledger'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Accounts'),
              Tab(text: 'Transactions'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AccountsTab(),
            _TransactionsTab(),
          ],
        ),
        floatingActionButton: const _LedgerFAB(),
      ),
    );
  }
}

class _AccountsTab extends ConsumerWidget {
  const _AccountsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    if (accounts.isEmpty) {
      return const Center(child: Text('No accounts found. Add one!'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final a = accounts[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(a.color),
            child: Icon(_getIconForType(a.type), color: Colors.white),
          ),
          title: Text(a.name),
          subtitle: Text(a.type.toUpperCase()),
          trailing: Text(
            formatCurrency(a.balance),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      case 'cash':
        return Icons.money;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }
}

class _TransactionsTab extends ConsumerWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final accounts = ref.watch(accountsProvider);

    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions found. Add one!'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        final accountName = accounts.where((a) => a.id == t.accountId).firstOrNull?.name ?? 'Unknown Account';
        
        Color amountColor;
        String prefix;
        if (t.type == 'income') {
          amountColor = Colors.greenAccent;
          prefix = '+';
        } else if (t.type == 'expense') {
          amountColor = Colors.redAccent;
          prefix = '-';
        } else {
          amountColor = Colors.grey;
          prefix = '';
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            child: Icon(t.type == 'transfer' ? Icons.swap_horiz : (t.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward)),
          ),
          title: Text(t.categoryId ?? t.type.toUpperCase()),
          subtitle: Text('$accountName • ${DateFormat('MMM dd').format(t.date)}'),
          trailing: Text(
            '$prefix${formatCurrency(t.amount)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: amountColor),
          ),
        );
      },
    );
  }
}

class _LedgerFAB extends StatelessWidget {
  const _LedgerFAB();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Add Account'),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const AddAccountSheet(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Add Transaction'),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const AddTransactionSheet(),
                  );
                },
              ),
            ],
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}
