import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';
import '../../data/models/transaction.dart';

class ManualTransactionScreen extends StatefulWidget {
  final bool isIncome;

  const ManualTransactionScreen({
    super.key,
    required this.isIncome,
  });

  @override
  State<ManualTransactionScreen> createState() => _ManualTransactionScreenState();
}

class _ManualTransactionScreenState extends State<ManualTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _dateTime = DateTime.now();
  bool _saving = false;

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
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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

  Future<bool> _confirmDuplicate(Transaction duplicate) async {
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Possible duplicate'),
          content: Text(
            'A similar transaction already exists:\n\n'
            '${duplicate.description}\n'
            '₹${duplicate.amount.toStringAsFixed(2)} • ${fmt.format(duplicate.date)}\n\n'
            'Add anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add anyway'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final provider = context.read<TransactionProvider>();
    final accountId = provider.ensureDefaultAccountId();

    setState(() => _saving = true);
    try {
      final description = _descriptionController.text.trim();
      final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

      final duplicate = await provider.addManualTransaction(
        accountId: accountId,
        isIncome: widget.isIncome,
        amount: amount,
        description: description,
        date: _dateTime,
        note: note,
        allowDuplicate: false,
      );

      if (duplicate != null) {
        final addAnyway = await _confirmDuplicate(duplicate);
        if (!addAnyway) return;

        await provider.addManualTransaction(
          accountId: accountId,
          isIncome: widget.isIncome,
          amount: amount,
          description: description,
          date: _dateTime,
          note: note,
          allowDuplicate: true,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isIncome ? 'Add Income' : 'Add Expense';
    final dtFmt = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date & time'),
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
