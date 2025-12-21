import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../../data/models/transaction.dart';
import '../../../providers/category_provider.dart';

class CategoryPieChart extends StatelessWidget {
  final List<Transaction> transactions;
  final bool showIncome;

  const CategoryPieChart({
    super.key,
    required this.transactions,
    this.showIncome = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryProvider = context.watch<CategoryProvider>();
    final categoryTotals = _calculateCategoryTotals();

    if (categoryTotals.isEmpty) {
      return Center(
        child: Text(
          showIncome ? 'No income transactions' : 'No expense transactions',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final total = categoryTotals.values.reduce((a, b) => a + b);
    final sections = categoryTotals.entries.map((entry) {
      final category = categoryProvider.categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => categoryProvider.categories.first,
      );
      final percentage = (entry.value / total * 100);
      
      return PieChartSectionData(
        value: entry.value,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        color: _getCategoryColor(categoryProvider.categories.indexOf(category), theme),
        radius: 80,
        titleStyle: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: categoryTotals.entries.map((entry) {
            final category = categoryProvider.categories.firstWhere(
              (c) => c.id == entry.key,
              orElse: () => categoryProvider.categories.first,
            );
            final color = _getCategoryColor(
              categoryProvider.categories.indexOf(category),
              theme,
            );
            
            return Chip(
              avatar: CircleAvatar(
                backgroundColor: color,
                radius: 8,
              ),
              label: Text(
                '${category.name}: ₹${entry.value.toStringAsFixed(0)}',
                style: theme.textTheme.bodySmall,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Map<String, double> _calculateCategoryTotals() {
    final Map<String, double> totals = {};
    final filteredTxns = transactions.where((t) => 
      showIncome
        ? t.type == TransactionType.income
        : t.type == TransactionType.expense
    );

    for (final txn in filteredTxns) {
      totals[txn.categoryId] = (totals[txn.categoryId] ?? 0) + txn.amount;
    }

    return totals;
  }

  Color _getCategoryColor(int index, ThemeData theme) {
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.green,
      Colors.teal,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
}
