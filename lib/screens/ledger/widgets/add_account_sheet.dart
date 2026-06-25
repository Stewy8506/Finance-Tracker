import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../models/account.dart';
import '../../../../providers/accounts_provider.dart';

class AddAccountSheet extends ConsumerStatefulWidget {
  const AddAccountSheet({super.key});

  @override
  ConsumerState<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  String _type = 'bank';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    int color = 0xFF4CAF50; // default green
    if (_type == 'credit_card') color = 0xFFF44336; // red
    if (_type == 'cash') color = 0xFFFF9800; // orange
    if (_type == 'investment') color = 0xFF2196F3; // blue

    final account = Account(
      id: _uuid.v4(),
      name: _nameCtrl.text.trim(),
      type: _type,
      balance: double.parse(_balanceCtrl.text),
      color: color,
    );

    ref.read(accountsProvider.notifier).add(account);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
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
            Text('Add Account', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Account Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Account Type'),
              items: const [
                DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                DropdownMenuItem(value: 'cash', child: Text('Cash Wallet')),
                DropdownMenuItem(value: 'investment', child: Text('Investment')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _balanceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Current Balance (₹)',
                prefixText: '₹ ',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter balance';
                if (double.tryParse(v) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
