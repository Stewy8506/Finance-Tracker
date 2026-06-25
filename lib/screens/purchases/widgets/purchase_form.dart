import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../finance.dart' as finance;
import '../../../models/recurring_purchase.dart';
import '../../../providers/purchases_provider.dart';
import '../../../utils/currency_formatter.dart';

class PurchaseForm extends ConsumerStatefulWidget {
  final RecurringPurchase? existing;

  const PurchaseForm({super.key, this.existing});

  @override
  ConsumerState<PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends ConsumerState<PurchaseForm> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _firstYearCtrl;
  late final TextEditingController _recurCtrl;
  late final TextEditingController _noteCtrl;

  String _category = 'Tech';
  bool _isOneTime = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _amountCtrl = TextEditingController(
        text: p?.amount.toInt().toString() ?? '');
    _firstYearCtrl =
        TextEditingController(text: p?.firstYear.toString() ?? '1');
    _recurCtrl = TextEditingController(
        text: p?.recurEveryNYears?.toString() ?? '3');
    _noteCtrl = TextEditingController(text: p?.note ?? '');
    _category = p?.category ?? 'Tech';
    _isOneTime = p?.recurEveryNYears == null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _firstYearCtrl.dispose();
    _recurCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _previewTotal {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final firstYear = int.tryParse(_firstYearCtrl.text) ?? 1;
    final recur = _isOneTime ? null : int.tryParse(_recurCtrl.text);
    final p = RecurringPurchase(
      id: '',
      name: '',
      amount: amount,
      firstYear: firstYear,
      recurEveryNYears: recur,
      category: _category,
    );
    return finance.totalSpendOverYears(p, 10);
  }

  int get _occurrences10 {
    final firstYear = int.tryParse(_firstYearCtrl.text) ?? 1;
    final recur = _isOneTime ? null : int.tryParse(_recurCtrl.text);
    final p = RecurringPurchase(
      id: '',
      name: '',
      amount: 1,
      firstYear: firstYear,
      recurEveryNYears: recur,
      category: _category,
    );
    int count = 0;
    for (int y = 1; y <= 10; y++) {
      if (y < p.firstYear) continue;
      if (p.recurEveryNYears == null) {
        if (y == p.firstYear) count++;
      } else {
        final elapsed = y - p.firstYear;
        if (elapsed >= 0 && elapsed % p.recurEveryNYears! == 0) count++;
      }
    }
    return count;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final purchase = RecurringPurchase(
      id: widget.existing?.id ?? _uuid.v4(),
      name: _nameCtrl.text,
      amount: double.parse(_amountCtrl.text),
      firstYear: int.parse(_firstYearCtrl.text),
      recurEveryNYears: _isOneTime ? null : int.tryParse(_recurCtrl.text),
      category: _category,
      note: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
    );

    if (widget.existing != null) {
      ref.read(purchasesProvider.notifier).update(purchase);
    } else {
      ref.read(purchasesProvider.notifier).add(purchase);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _previewTotal;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.existing != null ? 'Edit Purchase' : 'New Purchase',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  final val = double.tryParse(v);
                  if (val == null || val <= 0) return 'Enter a positive amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _firstYearCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Starting Year',
                  suffixText: 'year from now',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter starting year';
                  final val = int.tryParse(v);
                  if (val == null || val < 1 || val > 30) {
                    return 'Enter a year between 1 and 30';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(
                    value: _isOneTime,
                    onChanged: (v) => setState(() => _isOneTime = v),
                  ),
                  const SizedBox(width: 8),
                  const Text('One-time purchase'),
                ],
              ),
              if (!_isOneTime)
                TextFormField(
                  controller: _recurCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Recur every N years',
                    suffixText: 'years',
                  ),
                  validator: (v) {
                    if (_isOneTime) return null;
                    if (v == null || v.isEmpty) return 'Enter recurrence interval';
                    final val = int.tryParse(v);
                    if (val == null || val < 1 || val > 30) {
                      return 'Enter a year between 1 and 30';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 12),
              // Category
              Text('Category', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Tech', 'Travel', 'Lifestyle', 'Health', 'Education']
                    .map((c) => ChoiceChip(
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 16),
              // Live preview
              if (preview > 0)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF2E2E2E)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: theme.colorScheme.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This will cost ${formatCurrency(preview)} over 10 years across $_occurrences10 occurrence(s)',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.existing != null ? 'Save Changes' : 'Add Purchase',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
