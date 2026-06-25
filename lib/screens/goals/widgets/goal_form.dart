import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/goal.dart';
import '../../../providers/goals_provider.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/formatters.dart';
import 'package:intl/intl.dart';

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
  double _dpPct = 20.0;

  String _type = 'purchase';
  String _priority = 'high';
  bool _adjustForInflation = false;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0);
    _amountCtrl = TextEditingController(
        text: g != null ? fmt.format(g.targetAmount).trim() : '');
    _yearCtrl =
        TextEditingController(text: g?.targetYear.toString() ?? '5');
    _propertyValueCtrl = TextEditingController(
        text: g != null && g.propertyValue != null ? fmt.format(g.propertyValue!).trim() : '');
    _dpPct = (g?.downPaymentPct ?? 0.2) * 100;
    
    _propertyValueCtrl.addListener(_onPropertyValueChanged);
    _amountCtrl.addListener(_onTargetAmountChanged);
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
    super.dispose();
  }

  double get _parsedProperty =>
      double.tryParse(_propertyValueCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  double get _parsedAmount =>
      double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  void _onPropertyValueChanged() {
    if (_type != 'down_payment') {
      setState(() {});
      return;
    }
    final propVal = _parsedProperty;
    if (propVal > 0) {
      final newAmt = propVal * (_dpPct / 100);
      final newAmtStr = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(newAmt).trim();
      if (_amountCtrl.text != newAmtStr) {
        _amountCtrl.text = newAmtStr;
      }
    }
    setState(() {});
  }

  void _onTargetAmountChanged() {
    if (_type != 'down_payment') {
      setState(() {});
      return;
    }
    final propVal = _parsedProperty;
    final amtVal = _parsedAmount;
    if (propVal > 0 && amtVal >= 0) {
      double newPct = (amtVal / propVal) * 100;
      if (newPct > 100) newPct = 100;
      if (_dpPct != newPct) {
        setState(() {
          _dpPct = newPct;
        });
        return;
      }
    }
    setState(() {});
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final goal = Goal(
      id: widget.existing?.id ?? _uuid.v4(),
      name: _nameCtrl.text,
      targetAmount: _parsedAmount,
      targetYear: int.parse(_yearCtrl.text),
      type: _type,
      priority: _priority,
      propertyValue: _type == 'down_payment'
          ? _parsedProperty
          : null,
      downPaymentPct: _type == 'down_payment'
          ? _dpPct / 100
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
                  inputFormatters: [IndianCurrencyFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Property Value (₹)',
                    prefixText: '₹ ',
                    helperText: _parsedProperty > 0 ? formatLakhsCrores(_parsedProperty) : null,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter property value';
                    if (_parsedProperty <= 0) return 'Enter a positive amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Down Payment %', style: theme.textTheme.bodySmall),
                    Text('${_dpPct.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _dpPct,
                  min: 0,
                  max: 100,
                  divisions: 1000,
                  label: '${_dpPct.toStringAsFixed(1)}%',
                  onChanged: (val) {
                    setState(() {
                      _dpPct = val;
                    });
                    final propVal = _parsedProperty;
                    if (propVal > 0) {
                      final newAmt = propVal * (val / 100);
                      _amountCtrl.text = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(newAmt).trim();
                    }
                  },
                ),
                const SizedBox(height: 4),
              ],
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [IndianCurrencyFormatter()],
                decoration: InputDecoration(
                  labelText: 'Target Amount (₹)',
                  prefixText: '₹ ',
                  helperText: _parsedAmount > 0 ? formatLakhsCrores(_parsedAmount) : null,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  if (_parsedAmount <= 0) return 'Enter a positive amount';
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
                      selectedColor: const Color(0xFF1F2128),
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
