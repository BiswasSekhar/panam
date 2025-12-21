import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../data/models/transaction.dart';

class SpendingTrendChart extends StatefulWidget {
  final List<Transaction> transactions;
  final String period; // 'week', 'month', '3months'

  const SpendingTrendChart({
    super.key,
    required this.transactions,
    this.period = 'week',
  });

  @override
  State<SpendingTrendChart> createState() => _SpendingTrendChartState();
}

class _SpendingTrendChartState extends State<SpendingTrendChart> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Check if there are any expense transactions
    final hasExpenses = widget.transactions.any((txn) => txn.type == TransactionType.expense);
    if (!hasExpenses) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions available',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start adding expenses to see trends',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    final spots = _calculateSpots();

    if (spots.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final interval = maxY > 0 ? maxY / 5.0 : 1.0;
    
    // For month and 3months, enable horizontal scrolling
    final isScrollable = widget.period == 'month' || widget.period == '3months';
    final chartWidth = isScrollable
        ? MediaQuery.of(context).size.width * (widget.period == 'month' ? 2.0 : 4.0)
        : null;

    final chart = LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval.toDouble(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: widget.period == '3months' ? 3 : 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() >= spots.length) {
                  return const SizedBox();
                }
                final date = _getDateForIndex(value.toInt());
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    widget.period == 'week'
                        ? DateFormat('EEE').format(date).substring(0, 1)
                        : widget.period == 'month'
                            ? '${date.day}'
                            : DateFormat('MMM').format(date).substring(0, 1),
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${(value / 1000).toStringAsFixed(0)}k',
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.3),
                  theme.colorScheme.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );

    if (!isScrollable) {
      return chart;
    }

    // Wrap in horizontal scrollview with indicator
    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: chart,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swipe_left,
              size: 16,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Text(
              'Swipe to see more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<FlSpot> _calculateSpots() {
    final now = DateTime.now();
    final Map<int, double> dataPoints = {};

    int days;
    switch (widget.period) {
      case 'week':
        days = 7;
        break;
      case 'month':
        days = 30;
        break;
      case '3months':
        days = 90;
        break;
      default:
        days = 30;
    }

    // Initialize all points to 0
    for (int i = 0; i < days; i++) {
      dataPoints[i] = 0;
    }

    // Aggregate spending by day
    for (final txn in widget.transactions) {
      if (txn.type == TransactionType.expense) {
        final daysDiff = now.difference(txn.date).inDays;
        if (daysDiff >= 0 && daysDiff < days) {
          final index = days - 1 - daysDiff;
          dataPoints[index] = (dataPoints[index] ?? 0) + txn.amount;
        }
      }
    }

    return dataPoints.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  DateTime _getDateForIndex(int index) {
    final now = DateTime.now();
    int days;
    switch (widget.period) {
      case 'week':
        days = 7;
        break;
      case 'month':
        days = 30;
        break;
      case '3months':
        days = 90;
        break;
      default:
        days = 30;
    }
    return now.subtract(Duration(days: days - 1 - index));
  }
}
