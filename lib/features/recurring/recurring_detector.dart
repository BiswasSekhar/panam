import '../../data/models/transaction.dart';

class RecurringPattern {
  final double amount;
  final String description;
  final List<DateTime> dates;
  final String pattern; // 'daily', 'weekly', 'monthly', 'same_date'
  final double confidence; // 0-1 score
  final String? categoryId;

  RecurringPattern({
    required this.amount,
    required this.description,
    required this.dates,
    required this.pattern,
    required this.confidence,
    this.categoryId,
  });

  String get patternDescription {
    switch (pattern) {
      case 'daily':
        return 'Repeats daily';
      case 'weekly':
        return 'Repeats every ${_getWeekday()}';
      case 'monthly':
        return 'Repeats monthly on day ${dates.first.day}';
      case 'same_date':
        return 'Repeats on the same date each month';
      default:
        return 'Recurring pattern detected';
    }
  }

  String _getWeekday() {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[dates.first.weekday - 1];
  }
}

class RecurringTransactionDetector {
  static const double amountTolerance = 5.0; // ±5 rupees tolerance
  static const int minOccurrences = 3; // At least 3 occurrences to be considered recurring

  /// Detect recurring transactions from a list of transactions
  static List<RecurringPattern> detectRecurringPatterns(List<Transaction> transactions) {
    final patterns = <RecurringPattern>[];

    // Group by similar amounts and descriptions
    final groups = _groupSimilarTransactions(transactions);

    for (final group in groups) {
      if (group.length < minOccurrences) continue;

      // Check for monthly patterns (same day each month)
      final monthlyPattern = _detectMonthlyPattern(group);
      if (monthlyPattern != null) {
        patterns.add(monthlyPattern);
        continue;
      }

      // Check for weekly patterns (same day of week)
      final weeklyPattern = _detectWeeklyPattern(group);
      if (weeklyPattern != null) {
        patterns.add(weeklyPattern);
        continue;
      }

      // Check for daily patterns
      final dailyPattern = _detectDailyPattern(group);
      if (dailyPattern != null) {
        patterns.add(dailyPattern);
      }
    }

    return patterns..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  static List<List<Transaction>> _groupSimilarTransactions(List<Transaction> transactions) {
    final groups = <List<Transaction>>[];
    final processed = <String>{};

    for (final txn in transactions) {
      if (processed.contains(txn.id)) continue;

      final similar = transactions.where((t) =>
        !processed.contains(t.id) &&
        (t.amount - txn.amount).abs() <= amountTolerance &&
        _similarDescriptions(t.description, txn.description) &&
        t.type == txn.type
      ).toList();

      if (similar.length >= minOccurrences) {
        groups.add(similar);
        processed.addAll(similar.map((t) => t.id));
      }
    }

    return groups;
  }

  static bool _similarDescriptions(String desc1, String desc2) {
    final cleaned1 = desc1.toLowerCase().trim();
    final cleaned2 = desc2.toLowerCase().trim();
    
    // Exact match
    if (cleaned1 == cleaned2) return true;
    
    // Remove common variations (dates, numbers, etc.)
    final normalized1 = cleaned1.replaceAll(RegExp(r'\d+'), '').trim();
    final normalized2 = cleaned2.replaceAll(RegExp(r'\d+'), '').trim();
    
    return normalized1 == normalized2 || 
           cleaned1.contains(cleaned2) || 
           cleaned2.contains(cleaned1);
  }

  static RecurringPattern? _detectMonthlyPattern(List<Transaction> group) {
    if (group.length < 2) return null;

    // Sort by date
    final sorted = group.toList()..sort((a, b) => a.date.compareTo(b.date));
    
    // Check if transactions occur on same day each month
    final firstDay = sorted.first.date.day;
    int matches = 0;
    final dates = <DateTime>[];

    for (int i = 0; i < sorted.length - 1; i++) {
      final current = sorted[i].date;
      final next = sorted[i + 1].date;
      
      final monthDiff = (next.year - current.year) * 12 + (next.month - current.month);
      
      if (monthDiff >= 1 && monthDiff <= 2 && next.day == firstDay) {
        matches++;
        dates.add(current);
      }
    }
    dates.add(sorted.last.date);

    if (matches >= minOccurrences - 1) {
      return RecurringPattern(
        amount: sorted.first.amount,
        description: sorted.first.description,
        dates: dates,
        pattern: 'monthly',
        confidence: matches / sorted.length,
        categoryId: sorted.first.categoryId,
      );
    }

    return null;
  }

  static RecurringPattern? _detectWeeklyPattern(List<Transaction> group) {
    if (group.length < minOccurrences) return null;

    final sorted = group.toList()..sort((a, b) => a.date.compareTo(b.date));
    final firstWeekday = sorted.first.date.weekday;
    
    int matches = 0;
    final dates = <DateTime>[];

    for (int i = 0; i < sorted.length - 1; i++) {
      final current = sorted[i].date;
      final next = sorted[i + 1].date;
      
      final dayDiff = next.difference(current).inDays;
      
      if ((dayDiff >= 6 && dayDiff <= 8) && next.weekday == firstWeekday) {
        matches++;
        dates.add(current);
      }
    }
    dates.add(sorted.last.date);

    if (matches >= minOccurrences - 1) {
      return RecurringPattern(
        amount: sorted.first.amount,
        description: sorted.first.description,
        dates: dates,
        pattern: 'weekly',
        confidence: matches / sorted.length,
        categoryId: sorted.first.categoryId,
      );
    }

    return null;
  }

  static RecurringPattern? _detectDailyPattern(List<Transaction> group) {
    if (group.length < minOccurrences) return null;

    final sorted = group.toList()..sort((a, b) => a.date.compareTo(b.date));
    
    int consecutiveDays = 0;
    final dates = <DateTime>[];

    for (int i = 0; i < sorted.length - 1; i++) {
      final current = sorted[i].date;
      final next = sorted[i + 1].date;
      
      final dayDiff = next.difference(current).inDays;
      
      if (dayDiff == 1) {
        consecutiveDays++;
        dates.add(current);
      }
    }
    dates.add(sorted.last.date);

    if (consecutiveDays >= minOccurrences - 1) {
      return RecurringPattern(
        amount: sorted.first.amount,
        description: sorted.first.description,
        dates: dates,
        pattern: 'daily',
        confidence: consecutiveDays / sorted.length,
        categoryId: sorted.first.categoryId,
      );
    }

    return null;
  }
}
