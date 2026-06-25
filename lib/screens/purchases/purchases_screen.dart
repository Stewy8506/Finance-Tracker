import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../finance.dart' as finance;
import '../../models/recurring_purchase.dart';
import '../../providers/purchases_provider.dart';
import '../../utils/currency_formatter.dart';

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchases = ref.watch(purchasesProvider);
    final theme = Theme.of(context);

    // Group by category
    final grouped = <String, List<RecurringPurchase>>{};
    for (final p in purchases) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

    // 10-year tech spend summary
    final techPurchases = purchases.where((p) => p.category == 'Tech').toList();
    final techTotal10 = techPurchases.fold<double>(
      0,
      (sum, p) => sum + finance.totalSpendOverYears(p, 10),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Purchases')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPurchaseSheet(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Purchase'),
      ),
      body: purchases.isEmpty
          ? _EmptyPurchases(onAdd: () => _showPurchaseSheet(context, ref, null))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6366F1).withValues(alpha: 0.12),
                            const Color(0xFF818CF8).withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.computer,
                              color: theme.colorScheme.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Tech Spend (10 years)',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatCurrency(techTotal10),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${techPurchases.length} items',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                for (final entry in grouped.entries) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Row(
                        children: [
                          _CategoryIcon(entry.key),
                          const SizedBox(width: 8),
                          Text(entry.key,
                              style: theme.textTheme.titleMedium),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _categoryColor(entry.key).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${entry.value.length}',
                              style: TextStyle(
                                  color: _categoryColor(entry.key),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PurchaseCard(
                            purchase: entry.value[i],
                            onEdit: () => _showPurchaseSheet(
                                context, ref, entry.value[i]),
                            onDelete: () => _deletePurchase(
                                context, ref, entry.value[i]),
                          ),
                        ),
                        childCount: entry.value.length,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Color _categoryColor(String category) {
    const colors = {
      'Tech': Color(0xFF6366F1),
      'Travel': Color(0xFF34D399),
      'Lifestyle': Color(0xFFF472B6),
      'Health': Color(0xFF34D399),
      'Education': Color(0xFFFBBF24),
    };
    return colors[category] ?? const Color(0xFF9CA3AF);
  }

  Future<void> _deletePurchase(
      BuildContext context, WidgetRef ref, RecurringPurchase purchase) async {
    ref.read(purchasesProvider.notifier).delete(purchase.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${purchase.name} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              ref.read(purchasesProvider.notifier).add(purchase),
        ),
      ),
    );
  }

  void _showPurchaseSheet(
      BuildContext context, WidgetRef ref, RecurringPurchase? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _PurchaseForm(existing: existing),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PURCHASE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseCard extends StatelessWidget {
  final RecurringPurchase purchase;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PurchaseCard({
    required this.purchase,
    required this.onEdit,
    required this.onDelete,
  });

  Color _catColor() {
    const colors = {
      'Tech': Color(0xFF6366F1),
      'Travel': Color(0xFF34D399),
      'Lifestyle': Color(0xFFF472B6),
      'Health': Color(0xFF34D399),
      'Education': Color(0xFFFBBF24),
    };
    return colors[purchase.category] ?? const Color(0xFF9CA3AF);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _catColor();
    final total10 = finance.totalSpendOverYears(purchase, 10);
    final occurrences10 = _countOccurrences(10);

    return Dismissible(
      key: Key(purchase.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF87171).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFF87171)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(purchase.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Text(
                  formatCurrency(purchase.amount),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onEdit,
                  child: Icon(Icons.edit_outlined,
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                      size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    purchase.category,
                    style: TextStyle(
                        color: color, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${purchase.recurrenceLabel}, starting year ${purchase.firstYear}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  'Next: Yr ${purchase.nextOccurrence(1)}',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  '₹${(total10 / 100000).toStringAsFixed(1)}L over 10yr ($occurrences10×)',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _countOccurrences(int years) {
    int count = 0;
    for (int y = 1; y <= years; y++) {
      if (y < purchase.firstYear) continue;
      if (purchase.recurEveryNYears == null) {
        if (y == purchase.firstYear) count++;
      } else {
        final elapsed = y - purchase.firstYear;
        if (elapsed >= 0 && elapsed % purchase.recurEveryNYears! == 0) count++;
      }
    }
    return count;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY ICON
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryIcon extends StatelessWidget {
  final String category;

  const _CategoryIcon(this.category);

  @override
  Widget build(BuildContext context) {
    const icons = {
      'Tech': Icons.computer,
      'Travel': Icons.flight,
      'Lifestyle': Icons.style,
      'Health': Icons.favorite,
      'Education': Icons.school,
    };
    const colors = {
      'Tech': Color(0xFF6366F1),
      'Travel': Color(0xFF34D399),
      'Lifestyle': Color(0xFFF472B6),
      'Health': Color(0xFF34D399),
      'Education': Color(0xFFFBBF24),
    };
    final icon = icons[category] ?? Icons.shopping_bag;
    final color = colors[category] ?? const Color(0xFF9CA3AF);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PURCHASE FORM
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseForm extends ConsumerStatefulWidget {
  final RecurringPurchase? existing;

  const _PurchaseForm({this.existing});

  @override
  ConsumerState<_PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends ConsumerState<_PurchaseForm> {
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
                    v?.isEmpty == true ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                ),
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Enter amount' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _firstYearCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Starting Year',
                  suffixText: 'year from now',
                ),
                validator: (v) =>
                    int.tryParse(v ?? '') == null ? 'Enter year' : null,
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2)),
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

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyPurchases extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyPurchases({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No purchases planned', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Track recurring tech, travel, and lifestyle spends.',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Purchase'),
          ),
        ],
      ),
    );
  }
}
