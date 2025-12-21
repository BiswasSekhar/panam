import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/models/transaction.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/account_provider.dart';

class EditTransactionDialog extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionDialog({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _noteController;

  late bool _isIncome;
  late DateTime _dateTime;
  late String _selectedAccountId;
  bool _saving = false;

  // Optional marking for actual income/expense/loan
  bool? _isActualIncome;
  bool? _isActualExpense;
  bool? _isLoan;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.transaction.amount.toString());
    _descriptionController = TextEditingController(text: widget.transaction.description);
    _noteController = TextEditingController(text: widget.transaction.note ?? '');
    _isIncome = widget.transaction.type == TransactionType.income;
    _dateTime = widget.transaction.date;
    _selectedAccountId = widget.transaction.accountId;
    
    // Load existing marking flags
    _isActualIncome = widget.transaction.isActualIncome;
    _isActualExpense = widget.transaction.isActualExpense;
    _isLoan = widget.transaction.isLoan;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final provider = context.read<TransactionProvider>();

    setState(() => _saving = true);
    try {
      await provider.updateTransaction(
        id: widget.transaction.id,
        amount: amount,
        description: _descriptionController.text.trim(),
        date: _dateTime,
        isIncome: _isIncome,
        accountId: _selectedAccountId,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        isActualIncome: _isActualIncome,
        isActualExpense: _isActualExpense,
        isLoan: _isLoan,
      );

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dtFmt = DateFormat('dd MMM yyyy, HH:mm');

    return AlertDialog(
      title: const Text('Edit Transaction'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Income/Expense toggle
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isIncome = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isIncome ? theme.colorScheme.primaryContainer : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Expense',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: !_isIncome ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isIncome = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isIncome ? theme.colorScheme.primaryContainer : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Credit',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: _isIncome ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) {
                  if ((v?.trim() ?? '').isEmpty) return 'Enter a description';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Consumer<AccountProvider>(builder: (context, accProvider, _) {
                final accounts = accProvider.accounts;
                if (accounts.isEmpty) {
                  return const Text('No accounts available.');
                }
                return DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: accounts
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ))
                      .toList(growable: false),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedAccountId = v);
                  },
                );
              }),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date & Time'),
                subtitle: Text(dtFmt.format(_dateTime)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_rounded),
                    ),
                    IconButton(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Optional classification
              Text(
                'Optional Classification',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mark as Actual Income'),
                subtitle: const Text('This is real income (salary, etc)'),
                value: _isActualIncome ?? false,
                tristate: true,
                onChanged: (v) => setState(() => _isActualIncome = v),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mark as Actual Expense'),
                subtitle: const Text('This is a real expense'),
                value: _isActualExpense ?? false,
                tristate: true,
                onChanged: (v) => setState(() => _isActualExpense = v),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mark as Loan'),
                subtitle: const Text('Money lent to be returned later'),
                value: _isLoan ?? false,
                tristate: true,
                onChanged: (v) => setState(() => _isLoan = v),
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
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
