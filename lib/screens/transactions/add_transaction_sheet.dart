import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../import/import_statement_screen.dart';

class AddTransactionSheet extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionSheet({
    super.key,
    this.transaction,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _noteController;

  late bool _isIncome;
  late DateTime _dateTime;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  bool _saving = false;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.transaction;
    _isIncome = existing?.type == TransactionType.income;
    _dateTime = existing?.date ?? DateTime.now();
    _selectedAccountId = existing?.accountId;
    _selectedCategoryId = existing?.categoryId;

    _amountController = TextEditingController(text: existing?.amount.toString() ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
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

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    final provider = context.read<TransactionProvider>();

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final description = _descriptionController.text.trim();
      final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

      if (_isEdit) {
        await provider.updateTransaction(
          id: widget.transaction!.id,
          amount: amount,
          description: description,
          date: _dateTime,
          isIncome: _isIncome,
          accountId: _selectedAccountId!,
          note: note,
          categoryId: _selectedCategoryId,
        );
        if (mounted) Navigator.of(context).pop();
        return;
      }

      final duplicate = await provider.addManualTransaction(
        isIncome: _isIncome,
        amount: amount,
        description: description,
        date: _dateTime,
        note: note,
        allowDuplicate: false,
        accountId: _selectedAccountId!,
        categoryId: _selectedCategoryId,
      );

      if (duplicate != null) {
        final addAnyway = await _confirmDuplicate(duplicate);
        if (!addAnyway) return;

        await provider.addManualTransaction(
          isIncome: _isIncome,
          amount: amount,
          description: description,
          date: _dateTime,
          note: note,
          allowDuplicate: true,
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createCategory(BuildContext context) async {
    final provider = context.read<CategoryProvider>();
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create category'),
          content: TextField(
            controller: controller,
            autofocus: false,
            decoration: const InputDecoration(labelText: 'Category name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return;

    final created = await provider.createCategory(name: trimmed, isIncome: _isIncome);
    if (!mounted) return;
    setState(() => _selectedCategoryId = created.id);
  }

  void _openScanner() {
    if (_isEdit) return;
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImportStatementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dtFmt = DateFormat('dd MMM yyyy, HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isEdit ? 'Edit Transaction' : 'Add Transaction',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_isEdit)
                            IconButton(
                              onPressed: _openScanner,
                              icon: const Icon(Icons.document_scanner_rounded),
                              tooltip: 'Import Statement',
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: !_isIncome ? theme.colorScheme.primaryContainer : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward_rounded,
                                        color: !_isIncome ? theme.colorScheme.onPrimaryContainer : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Expense',
                                        style: TextStyle(
                                          fontWeight: !_isIncome ? FontWeight.bold : FontWeight.normal,
                                          color: !_isIncome ? theme.colorScheme.onPrimaryContainer : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isIncome = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: _isIncome ? theme.colorScheme.primaryContainer : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_downward_rounded,
                                        color: _isIncome ? theme.colorScheme.onPrimaryContainer : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Income',
                                        style: TextStyle(
                                          fontWeight: _isIncome ? FontWeight.bold : FontWeight.normal,
                                          color: _isIncome ? theme.colorScheme.onPrimaryContainer : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _amountController,
                          autofocus: false,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          final parsed = double.tryParse(value);
                          if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if ((v?.trim() ?? '').isEmpty) return 'Enter a description';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<AccountProvider>(builder: (context, accProvider, _) {
                        final accounts = accProvider.accounts;
                        if (accounts.isEmpty) {
                          return const Text('No accounts available. Add one in the Accounts tab.');
                        }
                        if (_selectedAccountId == null && accounts.isNotEmpty) {
                          _selectedAccountId = accounts.first.id;
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedAccountId,
                          decoration: InputDecoration(
                            labelText: 'Account',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: accounts
                              .map((a) => DropdownMenuItem(
                                    value: a.id,
                                    child: Text(a.name),
                                  ))
                              .toList(growable: false),
                          onChanged: (v) => setState(() => _selectedAccountId = v),
                        );
                      }),
                      const SizedBox(height: 16),
                      Consumer<CategoryProvider>(builder: (context, catProvider, _) {
                        final cats = catProvider.categories.where((c) => c.isIncome == _isIncome).toList(growable: false);
                        if (cats.isEmpty) {
                          return const Text('No categories available.');
                        }

                        if (_selectedCategoryId == null || !cats.any((c) => c.id == _selectedCategoryId)) {
                          final defaultCat = cats.where((c) => c.isDefault).toList();
                          _selectedCategoryId = (defaultCat.isNotEmpty ? defaultCat.first.id : cats.first.id);
                        }

                        String labelFor(Category c) => c.isDefault ? '${c.name} (Default)' : c.name;

                        return DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            suffixIcon: IconButton(
                              tooltip: 'Create category',
                              onPressed: () => _createCategory(context),
                              icon: const Icon(Icons.add_rounded),
                            ),
                          ),
                          items: cats
                              .map((Category c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(labelFor(c)),
                                  ))
                              .toList(growable: false),
                          onChanged: (v) => setState(() => _selectedCategoryId = v),
                        );
                      }),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: 'Note (optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date & Time',
                                  style: theme.textTheme.labelMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dtFmt.format(_dateTime),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _pickDate,
                                  icon: const Icon(Icons.calendar_today_rounded),
                                  style: IconButton.styleFrom(
                                    backgroundColor: theme.colorScheme.surface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _pickTime,
                                  icon: const Icon(Icons.schedule_rounded),
                                  style: IconButton.styleFrom(
                                    backgroundColor: theme.colorScheme.surface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _saving ? 'Saving…' : (_isEdit ? 'Save Changes' : 'Save Transaction'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
