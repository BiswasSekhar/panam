import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/account.dart';
import '../../../providers/account_provider.dart';

class AccountSelectorDialog extends StatefulWidget {
  final String? detectedBank;
  final Account? matchingAccount;

  const AccountSelectorDialog({
    super.key,
    this.detectedBank,
    this.matchingAccount,
  });

  @override
  State<AccountSelectorDialog> createState() => _AccountSelectorDialogState();
}

class _AccountSelectorDialogState extends State<AccountSelectorDialog> {
  String? _selectedAccountId;
  bool _creatingNew = false;
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    if (widget.matchingAccount != null) {
      _selectedAccountId = widget.matchingAccount!.id;
    }
    if (widget.detectedBank != null) {
      _nameController.text = widget.detectedBank!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _createNewAccount() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final provider = context.read<AccountProvider>();

    String? icon;
    if (widget.detectedBank != null) {
      icon = widget.detectedBank!.toLowerCase();
    }

    await provider.addAccount(
      name: name,
      type: AccountType.bank,
      initialBalance: balance,
      icon: icon,
    );

    // Select the newly created account
    final newAccount = provider.accounts.where((a) => a.name == name).firstOrNull;
    if (newAccount != null && mounted) {
      Navigator.of(context).pop(newAccount.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.detectedBank != null
          ? 'Select Account for ${widget.detectedBank}'
          : 'Select Account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.matchingAccount != null) ...[
              Text(
                'We found a matching account:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                value: widget.matchingAccount!.id,
                groupValue: _selectedAccountId,
                title: Text(widget.matchingAccount!.name),
                subtitle: Text('Current balance: ₹${context.watch<AccountProvider>().getAccountBalance(widget.matchingAccount!.id).toStringAsFixed(2)}'),
                onChanged: (v) {
                  setState(() {
                    _selectedAccountId = v;
                    _creatingNew = false;
                  });
                },
              ),
              const Divider(),
            ],
            Consumer<AccountProvider>(
              builder: (context, provider, _) {
                final otherAccounts = widget.matchingAccount != null
                    ? provider.accounts.where((a) => a.id != widget.matchingAccount!.id).toList()
                    : provider.accounts;

                if (otherAccounts.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Or select another account:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      ...otherAccounts.map((acc) {
                        return RadioListTile<String>(
                          value: acc.id,
                          groupValue: _selectedAccountId,
                          title: Text(acc.name),
                          onChanged: (v) {
                            setState(() {
                              _selectedAccountId = v;
                              _creatingNew = false;
                            });
                          },
                        );
                      }),
                      const Divider(),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            RadioListTile<bool>(
              value: true,
              groupValue: _creatingNew,
              title: const Text('Create New Account'),
              onChanged: (v) {
                setState(() {
                  _creatingNew = v ?? false;
                  if (_creatingNew) _selectedAccountId = null;
                });
              },
            ),
            if (_creatingNew) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Initial Balance',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_creatingNew) {
              _createNewAccount();
            } else if (_selectedAccountId != null) {
              Navigator.of(context).pop(_selectedAccountId);
            }
          },
          child: Text(_creatingNew ? 'Create & Select' : 'Select'),
        ),
      ],
    );
  }
}
