import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../data/models/account.dart';
import '../../widgets/common/glassmorphic_card.dart';
import 'widgets/add_account_dialog.dart';
import 'widgets/transaction_list_item.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  IconData _getAccountIcon(AccountType type, String? icon) {
    if (icon == 'kotak') return Icons.account_balance;
    if (icon == 'sbi') return Icons.account_balance;
    if (icon == 'cash') return Icons.money_rounded;
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.cash:
        return Icons.money_rounded;
      case AccountType.wallet:
        return Icons.account_balance_wallet_rounded;
      case AccountType.card:
        return Icons.credit_card_rounded;
      default:
        return Icons.savings_rounded;
    }
  }

  Widget _buildIncExpChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Future<void> _createCategory() async {
    final nameController = TextEditingController();
    bool isIncome = false;

    final result = await showDialog<({String name, bool isIncome})>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: false,
                    decoration: const InputDecoration(labelText: 'Category name'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Income category'),
                    value: isIncome,
                    onChanged: (v) => setState(() => isIncome = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop((name: nameController.text, isIncome: isIncome)),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    final name = (result?.name ?? '').trim();
    if (name.isEmpty) return;

    await context.read<CategoryProvider>().createCategory(name: name, isIncome: result!.isIncome);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category created')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            onPressed: _createCategory,
            icon: const Icon(Icons.category_rounded),
            tooltip: 'Create category',
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddAccountDialog(),
              );
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: Consumer2<AccountProvider, TransactionProvider>(
        builder: (context, accProvider, txProvider, _) {
          final accounts = accProvider.accounts;

          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No accounts yet'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddAccountDialog(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Account'),
                  ),
                ],
              ),
            );
          }

          // Ensure current index is valid
          if (_currentIndex >= accounts.length) {
            _currentIndex = 0;
          }

          final currentAccount = accounts[_currentIndex];
          final accountTxns = txProvider.transactions
              .where((t) => t.accountId == currentAccount.id)
              .toList()
            ..sort((a, b) {
              // Primary: date descending (newest first)
              final dateCmp = b.date.compareTo(a.date);
              if (dateCmp != 0) return dateCmp;
              // Secondary: importSequence ascending (preserve PDF table row order)
              final aSeq = a.importSequence ?? 0;
              final bSeq = b.importSequence ?? 0;
              return aSeq.compareTo(bSeq);
            });

          return Column(
            children: [
              // Carousel of account cards
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final acc = accounts[index];
                    final accBalance = accProvider.getAccountBalance(acc.id);
                    final isActive = index == _currentIndex;

                    final accIncExp = accProvider.getAccountIncomeExpense(acc.id);
                    return AnimatedScale(
                      scale: isActive ? 1.0 : 0.9,
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        child: GlassmorphicCard(
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getAccountIcon(acc.type, acc.icon),
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                acc.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${accBalance.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildIncExpChip(context, '↓ ₹${accIncExp.income.toStringAsFixed(0)}', Colors.green),
                                  _buildIncExpChip(context, '↑ ₹${accIncExp.expense.toStringAsFixed(0)}', Colors.red),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Transactions for selected account
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Transactions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: accountTxns.isEmpty
                          ? const Center(child: Text('No transactions in this account'))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: accountTxns.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                return TransactionListItem(transaction: accountTxns[i]);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
