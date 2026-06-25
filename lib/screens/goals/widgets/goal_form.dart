import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/goal.dart';
import '../../../providers/goals_provider.dart';

class GoalForm extends ConsumerStatefulWidget {
  final Goal? existing;

  const GoalForm({super.key, this.existing});

  @override
  ConsumerState<GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<GoalForm> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _propertyValueCtrl;
  late final TextEditingController _dpPctCtrl;

  String _type = 'purchase';
  String _priority = 'high';
  bool _adjustForInflation = false;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _amountCtrl = TextEditingController(
        text: g?.targetAmount.toInt().toString() ?? '');
    _yearCtrl =
        TextEditingController(text: g?.targetYear.toString() ?? '5');
    _propertyValueCtrl = TextEditingController(
        text: g?.propertyValue?.toInt().toString() ?? '');
    _dpPctCtrl = TextEditingController(
        text: ((g?.downPaymentPct ?? 0.2) * 100).toInt().toString());
    _type = g?.type ?? 'purchase';
    _priority = g?.priority ?? 'high';
    _adjustForInflation = g?.adjustForInflation ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _yearCtrl.dispose();
    _propertyValueCtrl.dispose();
    _dpPctCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final goal = Goal(
      id: widget.existing?.id ?? _uuid.v4(),
      name: _nameCtrl.text,
      targetAmount: double.parse(_amountCtrl.text),
      targetYear: int.parse(_yearCtrl.text),
      type: _type,
      priority: _priority,
      propertyValue: _type == 'down_payment'
          ? double.tryParse(_propertyValueCtrl.text)
          : null,
      downPaymentPct: _type == 'down_payment'
          ? (double.tryParse(_dpPctCtrl.text) ?? 20) / 100
          : null,
      adjustForInflation: _adjustForInflation,
    );

    if (widget.existing != null) {
      ref.read(goalsProvider.notifier).update(goal);
    } else {
      ref.read(goalsProvider.notifier).add(goal);
    }
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
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
                widget.existing != null ? 'Edit Goal' : 'New Goal',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Goal Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              // Type
              Text('Type', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['purchase', 'down_payment', 'corpus'].map((t) {
                  final labels = {
                    'purchase': 'Purchase',
                    'down_payment': 'Down Payment',
                    'corpus': 'Corpus Target',
                  };
                  return ChoiceChip(
                    label: Text(labels[t]!),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_type == 'down_payment') ...[
                TextFormField(
                  controller: _propertyValueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Property Value (₹)',
                    prefixText: '₹ ',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter property value';
                    final val = double.tryParse(v);
                    if (val == null || val <= 0) return 'Enter a positive amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dpPctCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Down Payment %',
                    suffixText: '%',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter percentage';
                    final val = double.tryParse(v);
                    if (val == null || val < 0 || val > 100) {
                      return 'Enter percentage between 0 and 100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Amount (₹)',
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
                controller: _yearCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Year (from now)',
                  suffixText: 'years',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter target year';
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
                    value: _adjustForInflation,
                    onChanged: (v) => setState(() => _adjustForInflation = v),
                  ),
                  const SizedBox(width: 8),
                  const Text('Adjust target amount for inflation'),
                ],
              ),
              const SizedBox(height: 16),
              // Priority
              Text('Priority', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                children:
                    ['high', 'medium', 'low'].map((p) {
                  final colorsMap = {
                    'high': const Color(0xFFF87171),
                    'medium': const Color(0xFFFBBF24),
                    'low': const Color(0xFF34D399),
                  };
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p.toUpperCase()),
                      selected: _priority == p,
                      selectedColor: const Color(0xFF2E2E2E),
                      onSelected: (_) => setState(() => _priority = p),
                      labelStyle: TextStyle(
                        color: _priority == p ? colorsMap[p] : null,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
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
                  child: Text(widget.existing != null ? 'Save Changes' : 'Add Goal',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
