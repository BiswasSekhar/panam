import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/recurring/recurring_detector.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/common/glassmorphic_card.dart';

class RecurringSuggestionsCard extends StatelessWidget {
  const RecurringSuggestionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txProvider = context.watch<TransactionProvider>();
    
    // Get last 3 months of transactions
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
    final recentTxns = txProvider.transactions
        .where((t) => t.date.isAfter(threeMonthsAgo))
        .toList();

    final patterns = RecurringTransactionDetector.detectRecurringPatterns(recentTxns);

    if (patterns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Found Recurring Transactions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...patterns.take(3).map((pattern) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassmorphicCard(
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  '${pattern.dates.length}',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                pattern.description,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '₹${pattern.amount.toStringAsFixed(2)} • ${pattern.patternDescription}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: pattern.confidence,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(pattern.confidence * 100).toStringAsFixed(0)}% confidence',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              trailing: TextButton(
                onPressed: () {
                  _showRecurringOptions(context, pattern);
                },
                child: const Text('Setup'),
              ),
            ),
          ),
        )),
        if (patterns.length > 3)
          TextButton.icon(
            onPressed: () {
              _showAllPatterns(context, patterns);
            },
            icon: const Icon(Icons.arrow_forward),
            label: Text('View all ${patterns.length} patterns'),
          ),
      ],
    );
  }

  void _showRecurringOptions(BuildContext context, RecurringPattern pattern) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Recurring Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction: ${pattern.description}'),
            Text('Amount: ₹${pattern.amount.toStringAsFixed(2)}'),
            Text('Pattern: ${pattern.patternDescription}'),
            const SizedBox(height: 16),
            const Text(
              'Would you like to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Auto-categorize feature coming soon!')),
              );
            },
            child: const Text('Auto-categorize similar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recurring reminders coming soon!')),
              );
            },
            child: const Text('Set reminder'),
          ),
        ],
      ),
    );
  }

  void _showAllPatterns(BuildContext context, List<RecurringPattern> patterns) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: patterns.length + 1,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'All Recurring Patterns',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                );
              }

              final pattern = patterns[index - 1];
              return ListTile(
                leading: CircleAvatar(child: Text('${pattern.dates.length}')),
                title: Text(pattern.description),
                subtitle: Text(
                  '₹${pattern.amount.toStringAsFixed(2)} • ${pattern.patternDescription}',
                ),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showRecurringOptions(context, pattern);
                  },
                  child: const Text('Setup'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
