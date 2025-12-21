import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../data/models/transaction.dart';

class TransactionHeatmapCalendar extends StatelessWidget {
  final List<Transaction> transactions;

  const TransactionHeatmapCalendar({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsByDate = _groupTransactionsByDate();
    final maxCount = transactionsByDate.values.isEmpty
        ? 1.0
        : transactionsByDate.values.reduce((a, b) => a > b ? a : b).toDouble();

    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 30)),
      focusedDay: DateTime.now(),
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      calendarStyle: CalendarStyle(
        markersMaxCount: 0,
        cellMargin: const EdgeInsets.all(4),
        defaultDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primaryContainer,
        ),
        selectedDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primary,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, _) {
          return _buildDayCell(context, date, transactionsByDate, maxCount);
        },
        todayBuilder: (context, date, _) {
          return _buildDayCell(context, date, transactionsByDate, maxCount, isToday: true);
        },
        outsideBuilder: (context, date, _) {
          return _buildDayCell(context, date, transactionsByDate, maxCount, isOutside: true);
        },
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime date,
    Map<String, int> transactionsByDate,
    double maxCount, {
    bool isToday = false,
    bool isOutside = false,
  }) {
    final theme = Theme.of(context);
    final dateKey = _dateKey(date);
    final count = transactionsByDate[dateKey] ?? 0;
    final intensity = count / maxCount;

    Color cellColor;
    if (count == 0) {
      cellColor = isOutside
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : theme.colorScheme.surfaceContainerHighest;
    } else {
      final baseColor = theme.brightness == Brightness.dark
          ? theme.colorScheme.primary
          : theme.colorScheme.primaryContainer;
      cellColor = Color.lerp(
        baseColor.withValues(alpha: 0.2),
        baseColor,
        intensity,
      )!;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cellColor,
        border: isToday
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${date.day}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: count > 0
              ? theme.colorScheme.onPrimaryContainer
              : (isOutside
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                  : theme.colorScheme.onSurface),
          fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Map<String, int> _groupTransactionsByDate() {
    final Map<String, int> result = {};
    for (final txn in transactions) {
      final key = _dateKey(txn.date);
      result[key] = (result[key] ?? 0) + 1;
    }
    return result;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
