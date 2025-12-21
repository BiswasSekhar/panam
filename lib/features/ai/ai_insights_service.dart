import 'package:flutter/foundation.dart';
import '../ai/llm_service.dart';
import '../../data/models/transaction.dart';

/// Service for AI-powered spending insights and psychological analysis
class AIInsightsService {
  final LLMService _llm = LLMService();

  /// Generate comprehensive spending insights
  Future<SpendingInsights> generateInsights({
    required List<Transaction> transactions,
    int periodDays = 30,
  }) async {
    if (transactions.isEmpty) {
      return SpendingInsights.empty();
    }

    // Filter to period
    final cutoff = DateTime.now().subtract(Duration(days: periodDays));
    final periodTxns = transactions.where((t) => t.date.isAfter(cutoff)).toList();
    
    if (periodTxns.isEmpty) {
      return SpendingInsights.empty();
    }

    // Calculate total income for period
    final income = periodTxns
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);

    // Calculate category totals
    final categoryTotals = <String, double>{};
    for (final txn in periodTxns.where((t) => t.type == TransactionType.expense)) {
      final category = txn.categoryId ?? 'Other';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + txn.amount.abs();
    }

    // Try LLM analysis if available
    if (_llm.isModelLoaded) {
      try {
        final txnData = periodTxns.take(50).map((t) => {
          'date': t.date.toIso8601String().substring(0, 10),
          'description': t.description,
          'amount': t.amount,
          'category': t.categoryId,
          'isIncome': t.type == TransactionType.income,
        }).toList();

        final analysis = await _llm.analyzeSpendingBehavior(
          transactions: txnData,
          categoryTotals: categoryTotals,
          monthlyIncome: income,
        );

        return SpendingInsights.fromJson(analysis);
      } catch (e) {
        debugPrint('[AIInsights] LLM analysis failed: $e');
      }
    }

    // Fallback to statistical analysis
    return _calculateStatisticalInsights(periodTxns, categoryTotals, income);
  }

  SpendingInsights _calculateStatisticalInsights(
    List<Transaction> transactions,
    Map<String, double> categoryTotals,
    double monthlyIncome,
  ) {
    final totalExpenses = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final savingsRate = monthlyIncome > 0 
        ? ((monthlyIncome - totalExpenses) / monthlyIncome).clamp(-1.0, 1.0) 
        : 0.0;
    
    // Determine spending personality
    String personality;
    String personalityDesc;
    if (savingsRate > 0.3) {
      personality = 'The Prudent Saver';
      personalityDesc = 'You prioritize saving and are careful with your spending. This discipline will help you build long-term wealth.';
    } else if (savingsRate > 0.1) {
      personality = 'The Balanced Spender';
      personalityDesc = 'You maintain a healthy balance between enjoying life and saving for the future. A sustainable approach!';
    } else if (savingsRate > 0) {
      personality = 'The Social Spender';
      personalityDesc = 'You enjoy experiences and may prioritize lifestyle over savings. Consider setting automated savings.';
    } else {
      personality = 'The Lifestyle Optimizer';
      personalityDesc = 'Your spending exceeds income currently. Focus on identifying non-essential expenses to cut.';
    }

    // Calculate financial health score (0-100)
    double healthScore = 50.0;
    
    // Savings rate contribution (0-40 points)
    healthScore += (savingsRate * 40).clamp(-20, 40);
    
    // Expense diversity (0-20 points) - more categories = more balanced
    if (categoryTotals.length >= 5) healthScore += 20;
    else if (categoryTotals.length >= 3) healthScore += 10;
    
    // Not overspending bonus (0-20 points)
    if (totalExpenses <= monthlyIncome) healthScore += 20;
    else healthScore -= 10;
    
    healthScore = healthScore.clamp(0.0, 100.0);

    // Generate behavior patterns
    final patterns = <String>[];
    
    // Check for impulse spending (small frequent transactions)
    final expenseTxns = transactions.where((t) => t.type == TransactionType.expense).toList();
    final smallTxns = expenseTxns.where((t) => t.amount.abs() < 500).length;
    if (expenseTxns.isNotEmpty && smallTxns / expenseTxns.length > 0.5) {
      patterns.add('Frequent small purchases - these can add up quickly');
    }

    // Check for late-night spending
    final lateSpending = expenseTxns.where((t) {
      final hour = t.date.hour;
      return hour >= 22 || hour <= 5;
    }).length;
    if (lateSpending > 3) {
      patterns.add('Late-night spending detected - emotional purchases are common at night');
    }

    // Check for weekend splurges  
    final weekendSpending = expenseTxns.where((t) {
      return t.date.weekday == 6 || t.date.weekday == 7;
    }).toList();
    final weekdaySpending = expenseTxns.where((t) {
      return t.date.weekday < 6;
    }).toList();
    
    if (weekendSpending.length >= 2 && weekdaySpending.length >= 2) {
      final weekendAvg = weekendSpending.fold<double>(0, (s, t) => s + t.amount.abs()) / weekendSpending.length;
      final weekdayAvg = weekdaySpending.fold<double>(0, (s, t) => s + t.amount.abs()) / weekdaySpending.length;
      
      if (weekendAvg > weekdayAvg * 1.5) {
        patterns.add('Weekend spending is significantly higher than weekdays');
      }
    }

    // Generate recommendations based on analysis
    final recommendations = <String>[];
    
    if (savingsRate < 0.1) {
      recommendations.add('Aim to save at least 10-20% of your income. Start with automating a small amount.');
    }
    
    // Category-specific advice
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedCategories.isNotEmpty) {
      final topCategory = sortedCategories.first;
      final topPct = totalExpenses > 0 ? (topCategory.value / totalExpenses * 100) : 0;
      if (topPct > 40) {
        recommendations.add('${topCategory.key} is ${topPct.toStringAsFixed(0)}% of spending. Look for ways to optimize.');
      }
    }
    
    if (smallTxns > expenseTxns.length * 0.5) {
      recommendations.add('Many small purchases add up. Try the 48-hour rule before buying.');
    }
    
    if (totalExpenses > monthlyIncome) {
      recommendations.add('Create a strict budget - you\'re spending more than you earn.');
    }
    
    // Add generic recommendations if needed
    if (recommendations.isEmpty) {
      recommendations.add('Keep tracking your expenses - awareness is the first step to financial health!');
    }

    // Generate financial health description
    String healthDesc;
    if (healthScore >= 80) {
      healthDesc = 'Excellent! You have strong financial habits and are on track for your goals.';
    } else if (healthScore >= 60) {
      healthDesc = 'Good standing. A few optimizations could further improve your finances.';
    } else if (healthScore >= 40) {
      healthDesc = 'Room for improvement. Focus on reducing unnecessary expenses.';
    } else {
      healthDesc = 'Needs attention. Consider creating a strict budget and tracking all expenses.';
    }

    return SpendingInsights(
      spendingPersonality: personalityDesc,
      financialHealth: healthDesc,
      healthScore: healthScore,
      behaviorPatterns: patterns,
      recommendations: recommendations,
    );
  }

  /// Get quick spending tips based on recent transactions
  List<String> getQuickTips(List<Transaction> recentTransactions) {
    if (recentTransactions.isEmpty) {
      return ['Start tracking your expenses to get personalized tips'];
    }

    final tips = <String>[];
    final expenses = recentTransactions.where((t) => t.type == TransactionType.expense).toList();
    
    if (expenses.isEmpty) {
      return ['Track your expenses to see personalized tips'];
    }
    
    // Check for frequent small purchases
    final smallPurchases = expenses.where((t) => t.amount.abs() < 200).length;
    if (smallPurchases > expenses.length * 0.5) {
      tips.add('Many small purchases add up. Try batch shopping instead.');
    }

    // Check for late-night spending
    final lateSpending = expenses.where((t) {
      final hour = t.date.hour;
      return hour >= 22 || hour <= 5;
    }).length;
    
    if (lateSpending > 3) {
      tips.add('You tend to spend late at night. Sleep on it before buying!');
    }

    // Check for weekend splurges
    final weekendSpending = expenses.where((t) {
      return t.date.weekday == 6 || t.date.weekday == 7;
    }).toList();
    
    final weekdaySpending = expenses.where((t) {
      return t.date.weekday < 6;
    }).toList();
    
    if (weekendSpending.length >= 2 && weekdaySpending.length >= 2) {
      final weekendTotal = weekendSpending.fold<double>(0, (s, t) => s + t.amount.abs());
      final weekdayTotal = weekdaySpending.fold<double>(0, (s, t) => s + t.amount.abs());
      final weekendAvg = weekendTotal / weekendSpending.length;
      final weekdayAvg = weekdayTotal / weekdaySpending.length;
      
      if (weekendAvg > weekdayAvg * 1.5) {
        tips.add('Weekend spending is higher. Plan activities in advance.');
      }
    }

    // Add generic tips if needed
    if (tips.isEmpty) {
      tips.addAll([
        'Great job tracking your expenses!',
        'Review your spending weekly for better awareness',
      ]);
    }

    return tips.take(3).toList();
  }
}

/// Model for spending insights
class SpendingInsights {
  final String spendingPersonality;
  final String financialHealth;
  final double healthScore;
  final List<String> behaviorPatterns;
  final List<String> recommendations;

  SpendingInsights({
    required this.spendingPersonality,
    required this.financialHealth,
    required this.healthScore,
    required this.behaviorPatterns,
    required this.recommendations,
  });

  factory SpendingInsights.empty() {
    return SpendingInsights(
      spendingPersonality: 'Add transactions to discover your spending personality',
      financialHealth: 'Track your finances to see your health score',
      healthScore: 0,
      behaviorPatterns: [],
      recommendations: ['Start adding transactions to get insights'],
    );
  }

  factory SpendingInsights.fromJson(Map<String, dynamic> json) {
    return SpendingInsights(
      spendingPersonality: json['spending_personality'] ?? 'Unknown',
      financialHealth: json['financial_health'] ?? 'Unknown',
      healthScore: (json['health_score'] as num?)?.toDouble() ?? 50,
      behaviorPatterns: List<String>.from(json['behavior_patterns'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}
