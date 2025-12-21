import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../data/models/transaction.dart';
import '../home/widgets/balance_card.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../widgets/spending_insights_card.dart';
import 'widgets/spending_trend_chart.dart';
import 'widgets/transaction_heatmap.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/recurring_suggestions_card.dart';
import 'widgets/spending_prediction_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _trendPeriod = 'month';
  
  bool _isSelfTransfer(Transaction t) {
    if (t.isSelfTransfer == true) return true;
    if (t.isSelfTransfer == false) return false;
    // Backward-compat fallback for older DB entries.
    return t.description.toLowerCase().contains('(self transfer)');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Consumer<TransactionProvider>(
          builder: (context, txProvider, _) {
            final appProvider = context.watch<AppProvider>();
            final txns = appProvider.showSelfTransfers
                ? txProvider.transactions.toList(growable: false)
                : txProvider.transactions.where((t) => !_isSelfTransfer(t)).toList(growable: false);
            final income = txns
                .where((t) => t.type == TransactionType.income)
                .fold<double>(0, (sum, t) => sum + t.amount);
            final expense = txns
                .where((t) => t.type == TransactionType.expense)
                .fold<double>(0, (sum, t) => sum + t.amount);

            final now = DateTime.now();
            final monthTxns = txns
                .where((t) => t.date.year == now.year && t.date.month == now.month)
                .toList(growable: false);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Balance Summary
                BalanceCard(totalBalance: income - expense, income: income, expense: expense),
                const SizedBox(height: 24),
                
                // Spending Prediction (AI-powered)
                const SpendingPredictionCard(),
                const SizedBox(height: 16),
                
                // AI Spending Insights (Psychological Analysis)
                SpendingInsightsCard(transactions: txns),
                const SizedBox(height: 16),
                
                // Recurring Transaction Suggestions
                const RecurringSuggestionsCard(),
                const SizedBox(height: 24),
                
                // Spending Trend Chart
                Text(
                  'Spending Trend',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'week', label: Text('Week')),
                        ButtonSegment(value: 'month', label: Text('Month')),
                        ButtonSegment(value: '3months', label: Text('3M')),
                      ],
                      selected: {_trendPeriod},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() => _trendPeriod = newSelection.first);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 200,
                      child: SpendingTrendChart(
                        transactions: txns,
                        period: _trendPeriod,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Category Breakdown
                Text(
                  'Category Breakdown',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CategoryPieChart(transactions: monthTxns, showIncome: false),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Transaction Heatmap
                Text(
                  'Transaction Calendar',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Darker colors indicate more transactions on that day',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TransactionHeatmapCalendar(transactions: txns),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Monthly Stats
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('This month'),
                  subtitle: Text('${monthTxns.length} transactions'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
