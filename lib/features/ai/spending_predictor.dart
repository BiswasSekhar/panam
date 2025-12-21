import 'dart:math' as math;
import '../../data/models/transaction.dart';

class SpendingPrediction {
  final double predictedAmount;
  final double confidence;
  final String trend; // 'increasing', 'decreasing', 'stable'
  final double percentageChange;
  final Map<String, double> categoryPredictions;
  final String explanation;

  SpendingPrediction({
    required this.predictedAmount,
    required this.confidence,
    required this.trend,
    required this.percentageChange,
    required this.categoryPredictions,
    required this.explanation,
  });
}

class MonthlySpendingData {
  final int year;
  final int month;
  final double totalSpending;
  final Map<String, double> categorySpending;
  final int transactionCount;

  MonthlySpendingData({
    required this.year,
    required this.month,
    required this.totalSpending,
    required this.categorySpending,
    required this.transactionCount,
  });

  String get monthYear => '$year-${month.toString().padLeft(2, '0')}';
}

class SpendingPredictor {
  /// Minimum months of data required for prediction
  static const int minMonthsRequired = 2;
  
  /// Maximum months to consider for prediction (recent data is more relevant)
  static const int maxMonthsToConsider = 6;

  /// Analyze spending patterns and predict next month's spending
  static SpendingPrediction? predictNextMonth(List<Transaction> transactions) {
    // Get monthly spending data
    final monthlyData = _aggregateMonthlySpending(transactions);
    
    if (monthlyData.length < minMonthsRequired) {
      return null; // Not enough data for prediction
    }

    // Use only recent months for better accuracy
    final recentData = monthlyData.length > maxMonthsToConsider
        ? monthlyData.sublist(monthlyData.length - maxMonthsToConsider)
        : monthlyData;

    // Calculate prediction using weighted moving average
    final prediction = _calculateWeightedPrediction(recentData);
    
    // Calculate trend
    final trend = _calculateTrend(recentData);
    
    // Calculate confidence based on data consistency
    final confidence = _calculateConfidence(recentData);
    
    // Predict category-wise spending
    final categoryPredictions = _predictCategorySpending(recentData);
    
    // Generate explanation
    final explanation = _generateExplanation(recentData, prediction, trend);

    // Calculate percentage change from last month
    final lastMonthSpending = recentData.last.totalSpending;
    final percentageChange = lastMonthSpending > 0
        ? ((prediction - lastMonthSpending) / lastMonthSpending) * 100
        : 0.0;

    return SpendingPrediction(
      predictedAmount: prediction,
      confidence: confidence,
      trend: trend,
      percentageChange: percentageChange,
      categoryPredictions: categoryPredictions,
      explanation: explanation,
    );
  }

  /// Aggregate transactions into monthly spending data
  static List<MonthlySpendingData> _aggregateMonthlySpending(List<Transaction> transactions) {
    final monthlyMap = <String, MonthlySpendingData>{};

    for (final txn in transactions) {
      if (txn.type != TransactionType.expense) continue;

      final key = '${txn.date.year}-${txn.date.month.toString().padLeft(2, '0')}';
      
      if (monthlyMap.containsKey(key)) {
        final existing = monthlyMap[key]!;
        final categorySpending = Map<String, double>.from(existing.categorySpending);
        final categoryId = txn.categoryId ?? 'uncategorized';
        categorySpending[categoryId] = (categorySpending[categoryId] ?? 0) + txn.amount;
        
        monthlyMap[key] = MonthlySpendingData(
          year: existing.year,
          month: existing.month,
          totalSpending: existing.totalSpending + txn.amount,
          categorySpending: categorySpending,
          transactionCount: existing.transactionCount + 1,
        );
      } else {
        final categoryId = txn.categoryId ?? 'uncategorized';
        monthlyMap[key] = MonthlySpendingData(
          year: txn.date.year,
          month: txn.date.month,
          totalSpending: txn.amount,
          categorySpending: {categoryId: txn.amount},
          transactionCount: 1,
        );
      }
    }

    // Sort by date
    final sortedKeys = monthlyMap.keys.toList()..sort();
    return sortedKeys.map((key) => monthlyMap[key]!).toList();
  }

  /// Calculate weighted prediction (recent months have more weight)
  static double _calculateWeightedPrediction(List<MonthlySpendingData> data) {
    if (data.isEmpty) return 0;
    if (data.length == 1) return data.first.totalSpending;

    double weightedSum = 0;
    double totalWeight = 0;

    for (int i = 0; i < data.length; i++) {
      // More recent months get higher weight (exponential weighting)
      final weight = math.pow(1.5, i).toDouble();
      weightedSum += data[i].totalSpending * weight;
      totalWeight += weight;
    }

    // Apply trend adjustment
    final trend = _calculateTrendValue(data);
    final basePredict = weightedSum / totalWeight;
    
    // Adjust prediction based on trend (but limit the adjustment)
    final trendAdjustment = basePredict * (trend * 0.1).clamp(-0.3, 0.3);
    
    return basePredict + trendAdjustment;
  }

  /// Calculate trend direction
  static String _calculateTrend(List<MonthlySpendingData> data) {
    final trendValue = _calculateTrendValue(data);
    
    if (trendValue > 0.05) return 'increasing';
    if (trendValue < -0.05) return 'decreasing';
    return 'stable';
  }

  /// Calculate numerical trend value using linear regression
  static double _calculateTrendValue(List<MonthlySpendingData> data) {
    if (data.length < 2) return 0;

    final n = data.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += data[i].totalSpending;
      sumXY += i * data[i].totalSpending;
      sumX2 += i * i;
    }

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return 0;

    final slope = (n * sumXY - sumX * sumY) / denominator;
    final avgSpending = sumY / n;
    
    // Normalize slope as percentage of average spending
    return avgSpending > 0 ? slope / avgSpending : 0;
  }

  /// Calculate confidence based on data consistency
  static double _calculateConfidence(List<MonthlySpendingData> data) {
    if (data.length < 2) return 0.3;

    // Calculate coefficient of variation (CV)
    final values = data.map((d) => d.totalSpending).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    
    if (mean == 0) return 0.3;

    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = math.sqrt(variance);
    final cv = stdDev / mean;

    // Convert CV to confidence (lower CV = higher confidence)
    // CV of 0 = 95% confidence, CV of 1 = 30% confidence
    final confidence = (0.95 - (cv * 0.65)).clamp(0.3, 0.95);

    // Boost confidence with more data points
    final dataBoost = math.min(data.length / 6, 1.0) * 0.1;

    return (confidence + dataBoost).clamp(0.3, 0.95);
  }

  /// Predict spending by category
  static Map<String, double> _predictCategorySpending(List<MonthlySpendingData> data) {
    if (data.isEmpty) return {};

    final allCategories = <String>{};
    for (final month in data) {
      allCategories.addAll(month.categorySpending.keys);
    }

    final predictions = <String, double>{};
    
    for (final category in allCategories) {
      final categoryData = data
          .map((m) => m.categorySpending[category] ?? 0)
          .toList();
      
      // Simple weighted average for categories
      double weightedSum = 0;
      double totalWeight = 0;
      
      for (int i = 0; i < categoryData.length; i++) {
        final weight = math.pow(1.3, i).toDouble();
        weightedSum += categoryData[i] * weight;
        totalWeight += weight;
      }
      
      predictions[category] = totalWeight > 0 ? weightedSum / totalWeight : 0;
    }

    return predictions;
  }

  /// Generate human-readable explanation
  static String _generateExplanation(
    List<MonthlySpendingData> data,
    double prediction,
    String trend,
  ) {
    if (data.isEmpty) return 'Not enough data for prediction.';

    final lastMonth = data.last;
    final avgSpending = data.map((d) => d.totalSpending).reduce((a, b) => a + b) / data.length;
    
    String trendText;
    switch (trend) {
      case 'increasing':
        trendText = 'Your spending has been increasing';
      case 'decreasing':
        trendText = 'Your spending has been decreasing';
      default:
        trendText = 'Your spending has been relatively stable';
    }

    final comparison = prediction > lastMonth.totalSpending
        ? 'higher than last month'
        : prediction < lastMonth.totalSpending
            ? 'lower than last month'
            : 'similar to last month';

    return '$trendText over the past ${data.length} months. '
        'Based on your patterns, next month\'s spending is predicted to be $comparison. '
        'Average monthly spending: ₹${avgSpending.toStringAsFixed(0)}.';
  }

  /// Get insights about spending patterns
  static List<String> getSpendingInsights(List<Transaction> transactions) {
    final insights = <String>[];
    final monthlyData = _aggregateMonthlySpending(transactions);

    if (monthlyData.length < 2) {
      insights.add('Add more transactions to get spending insights.');
      return insights;
    }

    // Find highest spending category
    final allCategorySpending = <String, double>{};
    for (final month in monthlyData) {
      for (final entry in month.categorySpending.entries) {
        allCategorySpending[entry.key] = (allCategorySpending[entry.key] ?? 0) + entry.value;
      }
    }

    if (allCategorySpending.isNotEmpty) {
      final topCategory = allCategorySpending.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      insights.add('Your highest spending category is "${topCategory.key}".');
    }

    // Check for spending spikes
    if (monthlyData.length >= 2) {
      final lastMonth = monthlyData.last;
      final prevMonth = monthlyData[monthlyData.length - 2];
      final change = ((lastMonth.totalSpending - prevMonth.totalSpending) / prevMonth.totalSpending) * 100;
      
      if (change > 20) {
        insights.add('Your spending increased by ${change.toStringAsFixed(0)}% last month.');
      } else if (change < -20) {
        insights.add('Great job! Your spending decreased by ${change.abs().toStringAsFixed(0)}% last month.');
      }
    }

    // Check transaction frequency
    if (monthlyData.isNotEmpty) {
      final avgTxnCount = monthlyData.map((m) => m.transactionCount).reduce((a, b) => a + b) / monthlyData.length;
      insights.add('You average ${avgTxnCount.toStringAsFixed(0)} expense transactions per month.');
    }

    return insights;
  }
}
