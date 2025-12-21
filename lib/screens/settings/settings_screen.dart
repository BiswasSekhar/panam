import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../data/local/hive_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Theme',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: appProvider.themeMode,
            title: const Text('System'),
            onChanged: (v) {
              if (v != null) appProvider.setThemeMode(v);
            },
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: appProvider.themeMode,
            title: const Text('Light'),
            onChanged: (v) {
              if (v != null) appProvider.setThemeMode(v);
            },
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: appProvider.themeMode,
            title: const Text('Dark'),
            onChanged: (v) {
              if (v != null) appProvider.setThemeMode(v);
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Data',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: appProvider.showSelfTransfers,
            title: const Text('Show self transfers'),
            subtitle: const Text('Include self transfers in totals & analytics'),
            onChanged: (v) => appProvider.setShowSelfTransfers(v),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all transactions, accounts, and categories'),
            onTap: () => _showClearDataDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDataDialog(BuildContext context) async {
    final accountProvider = context.read<AccountProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Data?'),
          content: const Text(
            'This will permanently delete all your transactions, accounts, and categories. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Everything'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    // Clear all Hive boxes
    await HiveService().transactionsBox.clear();
    await HiveService().accountsBox.clear();
    await HiveService().categoriesBox.clear();

    // Refresh providers and re-seed defaults so the UI updates without restart.
    await Future.wait([
      accountProvider.reload(seedIfEmpty: true),
      categoryProvider.reload(seedIfEmpty: true),
    ]);
    transactionProvider.reload();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data cleared.'),
        duration: Duration(seconds: 5),
      ),
    );
  }
}
