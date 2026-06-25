import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../models/transaction.dart';
import '../../../../providers/transactions_provider.dart';
import '../../../../providers/accounts_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  
  String _type = 'expense';
  String? _accountId;
  String? _toAccountId;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) return;
    if (_type == 'transfer' && _toAccountId == null) return;

    final tx = Transaction(
      id: _uuid.v4(),
      accountId: _accountId!,
      toAccountId: _type == 'transfer' ? _toAccountId : null,
      type: _type,
      amount: double.parse(_amountCtrl.text),
      date: DateTime.now(),
      categoryId: _type == 'transfer' ? 'Transfer' : _categoryCtrl.text.trim(),
    );

    ref.read(transactionsProvider.notifier).add(tx);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add Transaction', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              
              // Type Selector
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                  ButtonSegment(value: 'income', label: Text('Income')),
                  ButtonSegment(value: 'transfer', label: Text('Transfer')),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (accounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Please add an account first!', style: TextStyle(color: Colors.redAccent)),
                )
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: _accountId,
                  decoration: InputDecoration(labelText: _type == 'transfer' ? 'From Account' : 'Account'),
                  items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                  onChanged: (v) => setState(() => _accountId = v),
                  validator: (v) => v == null ? 'Select an account' : null,
                ),
                if (_type == 'transfer') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _toAccountId,
                    decoration: const InputDecoration(labelText: 'To Account'),
                    items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                    onChanged: (v) => setState(() => _toAccountId = v),
                    validator: (v) => v == null ? 'Select destination account' : null,
                  ),
                ],
              ],
              const SizedBox(height: 16),
              
              if (_type != 'transfer') ...[
                TextFormField(
                  controller: _categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category (e.g., Food, Salary)'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter a category' : null,
                ),
                const SizedBox(height: 24),
              ],

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: accounts.isEmpty ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
