import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../features/import/models.dart';

class MonthFilterDialog extends StatefulWidget {
  final List<ParsedTransaction> transactions;

  const MonthFilterDialog({
    super.key,
    required this.transactions,
  });

  @override
  State<MonthFilterDialog> createState() => _MonthFilterDialogState();
}

class _MonthFilterDialogState extends State<MonthFilterDialog> {
  final Set<DateTime> _selectedMonths = {};
  late final Map<DateTime, int> _monthCounts;

  @override
  void initState() {
    super.initState();
    // Group transactions by month
    _monthCounts = {};
    for (final tx in widget.transactions) {
      final month = DateTime(tx.date.year, tx.date.month);
      _monthCounts[month] = (_monthCounts[month] ?? 0) + 1;
    }

    // Auto-select current month if available
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    if (_monthCounts.containsKey(currentMonth)) {
      _selectedMonths.add(currentMonth);
    } else if (_monthCounts.isNotEmpty) {
      // Otherwise select the most recent month
      final sorted = _monthCounts.keys.toList()..sort((a, b) => b.compareTo(a));
      _selectedMonths.add(sorted.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthFmt = DateFormat('MMMM yyyy');
    final sortedMonths = _monthCounts.keys.toList()..sort((a, b) => b.compareTo(a));

    return AlertDialog(
      title: const Text('Select Months to Import'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: sortedMonths.map((month) {
            final count = _monthCounts[month] ?? 0;
            return CheckboxListTile(
              value: _selectedMonths.contains(month),
              title: Text(monthFmt.format(month)),
              subtitle: Text('$count transaction${count != 1 ? 's' : ''}'),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedMonths.add(month);
                  } else {
                    _selectedMonths.remove(month);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedMonths.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selectedMonths),
          child: Text('Import ${_selectedMonths.length} month${_selectedMonths.length != 1 ? 's' : ''}'),
        ),
      ],
    );
  }
}
