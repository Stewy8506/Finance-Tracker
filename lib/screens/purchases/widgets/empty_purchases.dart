import 'package:flutter/material.dart';

class EmptyPurchases extends StatelessWidget {
  final VoidCallback onAdd;

  const EmptyPurchases({super.key, required this.onAdd});

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
