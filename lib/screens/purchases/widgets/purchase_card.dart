import 'package:flutter/material.dart';
import '../../../finance.dart' as finance;
import '../../../models/recurring_purchase.dart';
import '../../../utils/currency_formatter.dart';

class PurchaseCard extends StatelessWidget {
  final RecurringPurchase purchase;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PurchaseCard({
    super.key,
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
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2E2E2E)),
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
                    color: const Color(0xFF262626),
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

class CategoryIcon extends StatelessWidget {
  final String category;

  const CategoryIcon({super.key, required this.category});

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
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}
