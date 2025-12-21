import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/transaction_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../data/models/transaction.dart';

class BulkEditDialog extends StatefulWidget {
  final List<String> transactionIds;

  const BulkEditDialog({
    super.key,
    required this.transactionIds,
  });

  @override
  State<BulkEditDialog> createState() => _BulkEditDialogState();
}

class _BulkEditDialogState extends State<BulkEditDialog> {
  bool _applyActualIncome = false;
  bool? _actualIncomeValue;
  
  bool _applyActualExpense = false;
  bool? _actualExpenseValue;
  
  bool _applyLoan = false;
  bool? _loanValue;
  
  bool _applyCategory = false;
  String? _selectedCategoryId;
  
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    if (!_applyActualIncome && !_applyActualExpense && !_applyLoan && !_applyCategory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one option to apply')),
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<TransactionProvider>();

    try {
      for (final id in widget.transactionIds) {
        final txn = provider.transactions.firstWhere((t) => t.id == id);
        
        await provider.updateTransaction(
          id: id,
          amount: txn.amount,
          description: txn.description,
          date: txn.date,
          isIncome: txn.type == TransactionType.income,
          accountId: txn.accountId,
          note: txn.note,
          categoryId: _applyCategory ? _selectedCategoryId : txn.categoryId,
          isActualIncome: _applyActualIncome ? _actualIncomeValue : txn.isActualIncome,
          isActualExpense: _applyActualExpense ? _actualExpenseValue : txn.isActualExpense,
          isLoan: _applyLoan ? _loanValue : txn.isLoan,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated ${widget.transactionIds.length} transactions')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Bulk Edit (${widget.transactionIds.length} transactions)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select which fields to update:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            // Actual Income
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Update "Actual Income" flag'),
              value: _applyActualIncome,
              onChanged: (v) => setState(() => _applyActualIncome = v ?? false),
            ),
            if (_applyActualIncome)
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 12),
                child: DropdownButtonFormField<bool?>(
                  value: _actualIncomeValue,
                  decoration: const InputDecoration(
                    labelText: 'Set to',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Yes')),
                    DropdownMenuItem(value: false, child: Text('No')),
                    DropdownMenuItem(value: null, child: Text('Unset')),
                  ],
                  onChanged: (v) => setState(() => _actualIncomeValue = v),
                ),
              ),
            
            // Actual Expense
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Update "Actual Expense" flag'),
              value: _applyActualExpense,
              onChanged: (v) => setState(() => _applyActualExpense = v ?? false),
            ),
            if (_applyActualExpense)
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 12),
                child: DropdownButtonFormField<bool?>(
                  value: _actualExpenseValue,
                  decoration: const InputDecoration(
                    labelText: 'Set to',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Yes')),
                    DropdownMenuItem(value: false, child: Text('No')),
                    DropdownMenuItem(value: null, child: Text('Unset')),
                  ],
                  onChanged: (v) => setState(() => _actualExpenseValue = v),
                ),
              ),
            
            // Loan
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Update "Loan" flag'),
              value: _applyLoan,
              onChanged: (v) => setState(() => _applyLoan = v ?? false),
            ),
            if (_applyLoan)
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 12),
                child: DropdownButtonFormField<bool?>(
                  value: _loanValue,
                  decoration: const InputDecoration(
                    labelText: 'Set to',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Yes (is a loan)')),
                    DropdownMenuItem(value: false, child: Text('No')),
                    DropdownMenuItem(value: null, child: Text('Unset')),
                  ],
                  onChanged: (v) => setState(() => _loanValue = v),
                ),
              ),
            
            // Category
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Update Category'),
              value: _applyCategory,
              onChanged: (v) => setState(() => _applyCategory = v ?? false),
            ),
            if (_applyCategory)
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 12),
                child: Consumer<CategoryProvider>(
                  builder: (context, catProvider, _) {
                    final categories = catProvider.categories;
                    return DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        isDense: true,
                      ),
                      items: categories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Apply'),
        ),
      ],
    );
  }
}
