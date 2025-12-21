import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../data/models/transaction.dart';
import '../home/widgets/balance_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  bool _isSelfTransfer(Transaction t) {
    if (t.isSelfTransfer == true) return true;
    if (t.isSelfTransfer == false) return false;
    // Backward-compat fallback for older DB entries.
    return t.description.toLowerCase().contains('(self transfer)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
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
                BalanceCard(totalBalance: income - expense, income: income, expense: expense),
                const SizedBox(height: 16),
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
