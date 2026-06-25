import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../finance.dart' as finance;
import '../../models/recurring_purchase.dart';
import '../../providers/purchases_provider.dart';
import '../../utils/currency_formatter.dart';
import 'widgets/empty_purchases.dart';
import 'widgets/purchase_card.dart';
import 'widgets/purchase_form.dart';

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
          ? EmptyPurchases(onAdd: () => _showPurchaseSheet(context, ref, null))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111215),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF1F2128)),
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
                          CategoryIcon(category: entry.key),
                          const SizedBox(width: 8),
                          Text(entry.key,
                              style: theme.textTheme.titleMedium),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2128),
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
                          child: PurchaseCard(
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
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
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
      backgroundColor: const Color(0xFF111215),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => PurchaseForm(existing: existing),
    );
  }
}
