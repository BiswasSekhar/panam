import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/account_provider.dart';
import '../../../data/models/account.dart';

class AddAccountDialog extends StatefulWidget {
  const AddAccountDialog({super.key});

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');

  AccountType _selectedType = AccountType.bank;
  String? _selectedIcon;

  final _bankIcons = {
    'Kotak': 'kotak',
    'SBI': 'sbi',
    'HDFC': 'hdfc',
    'ICICI': 'icici',
    'Axis': 'axis',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final provider = context.read<AccountProvider>();

    await provider.addAccount(
      name: _nameController.text.trim(),
      type: _selectedType,
      initialBalance: balance,
      icon: _selectedIcon,
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Account'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Account Name'),
                validator: (v) {
                  if ((v?.trim() ?? '').isEmpty) return 'Enter a name';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AccountType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: AccountType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name.toUpperCase()),
                        ))
                    .toList(growable: false),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
              const SizedBox(height: 12),
              if (_selectedType == AccountType.bank) ...[
                DropdownButtonFormField<String?>(
                  value: _selectedIcon,
                  decoration: const InputDecoration(labelText: 'Bank (optional)'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Other')),
                    ..._bankIcons.entries
                        .map((e) => DropdownMenuItem(value: e.value, child: Text(e.key)))
                        .toList(growable: false),
                  ],
                  onChanged: (v) => setState(() => _selectedIcon = v),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Initial Balance',
                  prefixText: '₹',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
