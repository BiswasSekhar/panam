import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'widgets/balance_card.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/app_provider.dart';
import '../../data/models/transaction.dart';
import '../transactions/add_transaction_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openEditor(BuildContext context, Transaction t) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(transaction: t),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<TransactionProvider>(
          builder: (context, txProvider, _) {
            final appProvider = context.watch<AppProvider>();
            final txns = txProvider.recentTransactions;
            bool isSelfTransfer(Transaction t) {
              if (t.isSelfTransfer == true) return true;
              if (t.isSelfTransfer == false) return false;
              // Backward-compat fallback for older DB entries.
              return t.description.toLowerCase().contains('(self transfer)');
            }
            final visibleRecent = appProvider.showSelfTransfers
                ? txns
                : txns.where((t) => !isSelfTransfer(t)).toList(growable: false);
            final income = txProvider.transactions
              .where((t) => appProvider.showSelfTransfers ? true : !isSelfTransfer(t))
              .where((t) => t.type == TransactionType.income)
                .fold<double>(0, (sum, t) => sum + t.amount);
            final expense = txProvider.transactions
              .where((t) => appProvider.showSelfTransfers ? true : !isSelfTransfer(t))
              .where((t) => t.type == TransactionType.expense)
                .fold<double>(0, (sum, t) => sum + t.amount);
            final total = income - expense;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BalanceCard(
                    totalBalance: total,
                    income: income,
                    expense: expense,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (txns.isEmpty)
                    const Center(child: Text('No transactions yet'))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visibleRecent.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final t = visibleRecent[index];
                        final isIncome = t.type == TransactionType.income;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          ),
                          title: Text(t.description),
                          subtitle: Text(
                            '${t.date.day.toString().padLeft(2, '0')}-'
                            '${t.date.month.toString().padLeft(2, '0')}-'
                            '${t.date.year}',
                          ),
                          onTap: () => _openEditor(context, t),
                          trailing: Text(
                            '${isIncome ? '+' : '-'}₹${t.amount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isIncome ? Colors.green : Colors.red,
                                ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
