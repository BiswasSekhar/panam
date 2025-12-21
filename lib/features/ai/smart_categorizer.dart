import 'package:flutter/foundation.dart' hide Category;
import '../../data/models/category.dart';
import 'llm_service.dart';

/// Smart categorizer that uses LLM for intelligent transaction categorization
/// based on description and narration text.
/// 
/// Uses actual LLM inference when model is loaded, with pattern matching fallback.
class SmartCategorizer {
  static final LLMService _llm = LLMService();
  
  /// Async version that uses LLM when available
  static Future<String?> categorizeWithLLM({
    required String description,
    String? narration,
    required List<Category> availableCategories,
    bool isIncome = false,
    double? amount,
  }) async {
    // Try LLM first if loaded
    if (_llm.isModelLoaded) {
      try {
        final categoryNames = availableCategories.map((Category c) => c.name).toList();
        final result = await _llm.categorizeTransaction(
          description: description,
          narration: narration,
          amount: amount ?? 0,
          availableCategories: categoryNames,
          isIncome: isIncome,
        );
        
        if (result['category'] != null && result['confidence'] != null) {
          final confidence = double.tryParse(result['confidence'].toString()) ?? 0;
          if (confidence > 0.5) {
            // Find matching category
            final categoryName = result['category'].toString().toLowerCase();
            for (final Category cat in availableCategories) {
              if (cat.isIncome == isIncome &&
                  (cat.name.toLowerCase() == categoryName ||
                   cat.name.toLowerCase().contains(categoryName) ||
                   categoryName.contains(cat.name.toLowerCase()))) {
                debugPrint('[SmartCategorizer] LLM matched: ${cat.name} (${confidence.toStringAsFixed(2)})');
                return cat.id;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[SmartCategorizer] LLM error: $e');
      }
    }
    
    // Fallback to pattern matching
    return categorizeTransaction(
      description: description,
      narration: narration,
      availableCategories: availableCategories,
      isIncome: isIncome,
    );
  }

  // Simulated LLM analysis patterns
  // In production, these would be replaced with actual LLM inference
  static final Map<String, List<String>> _categoryPatterns = {
    // Food & Dining
    'food': ['restaurant', 'cafe', 'coffee', 'pizza', 'burger', 'meal', 'lunch', 'dinner', 
             'breakfast', 'food', 'eat', 'zomato', 'swiggy', 'uber eats', 'dominos', 
             'mcdonalds', 'kfc', 'subway', 'starbucks', 'biryani', 'chinese', 'thai',
             'sushi', 'ice cream', 'bakery', 'snacks', 'juice', 'tea', 'chai'],
    
    // Transportation
    'transportation': ['uber', 'ola', 'lyft', 'cab', 'taxi', 'metro', 'bus', 'train',
                       'fuel', 'petrol', 'diesel', 'gas station', 'parking', 'toll',
                       'rapido', 'auto', 'rickshaw', 'flight', 'airline', 'indigo',
                       'spicejet', 'air india', 'booking', 'irctc', 'railway'],
    
    // Shopping
    'shopping': ['amazon', 'flipkart', 'myntra', 'ajio', 'nykaa', 'shopping', 'mall',
                 'store', 'mart', 'retail', 'purchase', 'buy', 'order', 'delivery',
                 'meesho', 'snapdeal', 'tata cliq', 'big basket', 'grofers', 'zepto',
                 'blinkit', 'instamart', 'dunzo'],
    
    // Bills & Utilities
    'bills': ['electricity', 'electric', 'power', 'water', 'gas', 'internet', 'wifi',
              'broadband', 'phone', 'mobile', 'recharge', 'postpaid', 'prepaid',
              'bill payment', 'utility', 'jio', 'airtel', 'vi', 'bsnl', 'act fibernet',
              'tata sky', 'dish tv', 'd2h', 'cable'],
    
    // Entertainment
    'entertainment': ['netflix', 'prime video', 'hotstar', 'disney', 'youtube', 'spotify',
                      'music', 'movie', 'cinema', 'theater', 'pvr', 'inox', 'game',
                      'gaming', 'playstation', 'xbox', 'steam', 'concert', 'show',
                      'event', 'ticket', 'bookmyshow'],
    
    // Healthcare
    'healthcare': ['hospital', 'clinic', 'doctor', 'medical', 'pharmacy', 'medicine',
                   'health', 'apollo', 'fortis', 'max', 'medplus', 'netmeds', '1mg',
                   'pharmeasy', 'practo', 'dental', 'dentist', 'eye', 'optical',
                   'lab', 'test', 'diagnostic', 'scan', 'xray', 'mri'],
    
    // Education
    'education': ['school', 'college', 'university', 'course', 'class', 'tuition',
                  'coaching', 'book', 'stationary', 'udemy', 'coursera', 'edx',
                  'skillshare', 'linkedin learning', 'unacademy', 'byju', 'vedantu',
                  'exam', 'fee', 'admission'],
    
    // Groceries
    'groceries': ['grocery', 'vegetables', 'fruits', 'milk', 'bread', 'eggs', 'rice',
                  'dal', 'oil', 'spices', 'meat', 'chicken', 'fish', 'supermarket',
                  'reliance fresh', 'dmart', 'more', 'spencer', 'nature basket'],
    
    // Insurance
    'insurance': ['insurance', 'policy', 'premium', 'lic', 'life insurance', 'health insurance',
                  'car insurance', 'bike insurance', 'term plan', 'hdfc ergo', 'icici lombard',
                  'bajaj allianz', 'star health', 'max bupa'],
    
    // Investment
    'investment': ['mutual fund', 'sip', 'stock', 'share', 'zerodha', 'groww', 'upstox',
                   'paytm money', 'kuvera', 'coin', 'nifty', 'sensex', 'investment',
                   'portfolio', 'dividend', 'ipo', 'fd', 'fixed deposit', 'rd', 
                   'recurring deposit', 'ppf', 'nps'],
    
    // Rent & Housing
    'rent': ['rent', 'lease', 'landlord', 'housing', 'apartment', 'flat', 'pg', 
             'paying guest', 'society', 'maintenance', 'security deposit', 'broker',
             'housing society', 'property'],
    
    // Subscription
    'subscription': ['subscription', 'membership', 'monthly', 'annual', 'renewal',
                     'plan', 'premium membership', 'pro', 'plus', 'gold', 'platinum'],
    
    // Personal Care
    'personal_care': ['salon', 'spa', 'haircut', 'beauty', 'cosmetic', 'skincare',
                      'grooming', 'parlour', 'barber', 'nail', 'massage', 'facial',
                      'urban company', 'urbanclap'],
    
    // Fitness
    'fitness': ['gym', 'fitness', 'workout', 'yoga', 'cult', 'gold gym', 'anytime fitness',
                'sports', 'swimming', 'tennis', 'badminton', 'cricket', 'football'],
    
    // Gifts & Donations
    'gifts': ['gift', 'present', 'donation', 'charity', 'wedding', 'birthday', 'anniversary',
              'festival', 'diwali', 'christmas', 'eid', 'holi', 'rakhi'],
    
    // EMI & Loans
    'loan': ['emi', 'loan', 'credit', 'instalment', 'bajaj finserv', 'home loan',
             'car loan', 'personal loan', 'education loan', 'interest', 'principal'],
    
    // Travel
    'travel': ['hotel', 'resort', 'makemytrip', 'goibibo', 'oyo', 'airbnb', 'booking.com',
               'travel', 'trip', 'vacation', 'holiday', 'tour', 'passport', 'visa'],
    
    // Salary (Income)
    'salary': ['salary', 'wages', 'payroll', 'stipend', 'income', 'credited', 'pay'],
    
    // Freelance (Income)
    'freelance': ['freelance', 'consulting', 'contract', 'project', 'client payment',
                  'invoice', 'fiverr', 'upwork', 'toptal'],
    
    // Business (Income)
    'business': ['business', 'revenue', 'sales', 'profit', 'commission', 'royalty',
                 'partnership', 'dividend received'],
    
    // Investment Return (Income)
    'returns': ['interest', 'dividend', 'capital gain', 'maturity', 'redemption',
                'bonus', 'cashback', 'refund', 'reimbursement'],
  };

  /// Categorize a transaction based on its description using simulated LLM analysis
  /// Returns the best matching category ID or null if no confident match
  static String? categorizeTransaction({
    required String description,
    String? narration,
    required List<Category> availableCategories,
    bool isIncome = false,
  }) {
    final text = '${description.toLowerCase()} ${narration?.toLowerCase() ?? ''}'.trim();
    
    if (text.isEmpty) return null;

    // Find the best matching pattern category
    String? bestMatch;
    int bestScore = 0;

    for (final entry in _categoryPatterns.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          // Longer keyword matches get higher scores
          score += keyword.length;
        }
      }
      
      if (score > bestScore) {
        bestScore = score;
        bestMatch = entry.key;
      }
    }

    if (bestMatch == null || bestScore < 3) {
      return null; // No confident match
    }

    // Map pattern category to actual category
    return _mapToCategory(bestMatch, availableCategories, isIncome);
  }

  /// Map pattern name to actual category from available categories
  static String? _mapToCategory(String patternName, List<Category> categories, bool isIncome) {
    // Filter categories by type
    final filteredCategories = categories.where((Category c) => c.isIncome == isIncome).toList();
    
    // Direct name mappings
    final nameMap = {
      'food': ['Food', 'Food & Dining', 'Dining', 'Restaurant', 'Meals'],
      'transportation': ['Transportation', 'Transport', 'Travel', 'Commute', 'Fuel'],
      'shopping': ['Shopping', 'Online Shopping', 'Retail', 'E-commerce'],
      'bills': ['Bills', 'Utilities', 'Bills & Utilities', 'Electricity', 'Internet'],
      'entertainment': ['Entertainment', 'Subscriptions', 'Movies', 'Streaming'],
      'healthcare': ['Healthcare', 'Medical', 'Health', 'Hospital', 'Medicine'],
      'education': ['Education', 'Learning', 'Courses', 'Books', 'School'],
      'groceries': ['Groceries', 'Grocery', 'Supermarket', 'Food Shopping'],
      'insurance': ['Insurance', 'Life Insurance', 'Health Insurance'],
      'investment': ['Investment', 'Investments', 'Stocks', 'Mutual Funds'],
      'rent': ['Rent', 'Housing', 'Home', 'Accommodation'],
      'subscription': ['Subscriptions', 'Subscription', 'Membership'],
      'personal_care': ['Personal Care', 'Beauty', 'Grooming', 'Salon'],
      'fitness': ['Fitness', 'Gym', 'Sports', 'Health & Fitness'],
      'gifts': ['Gifts', 'Gifts & Donations', 'Donations', 'Charity'],
      'loan': ['EMI', 'Loans', 'Loan Payment', 'Credit'],
      'travel': ['Travel', 'Vacation', 'Holiday', 'Trip'],
      'salary': ['Salary', 'Wages', 'Income'],
      'freelance': ['Freelance', 'Consulting', 'Side Income', 'Contract Work'],
      'business': ['Business', 'Business Income', 'Sales', 'Revenue'],
      'returns': ['Investment Returns', 'Interest', 'Dividends', 'Cashback', 'Refunds'],
    };

    final possibleNames = nameMap[patternName] ?? [patternName];
    
    for (final category in filteredCategories) {
      final categoryNameLower = category.name.toLowerCase();
      for (final name in possibleNames) {
        if (categoryNameLower.contains(name.toLowerCase()) || 
            name.toLowerCase().contains(categoryNameLower)) {
          return category.id;
        }
      }
    }

    // Try fuzzy matching as fallback
    for (final category in filteredCategories) {
      if (category.name.toLowerCase().contains(patternName) ||
          patternName.contains(category.name.toLowerCase())) {
        return category.id;
      }
    }

    return null;
  }

  /// Get confidence score for a categorization (0-1)
  static double getConfidenceScore(String description, String? narration, String categoryName) {
    final text = '${description.toLowerCase()} ${narration?.toLowerCase() ?? ''}'.trim();
    
    // Find matching patterns
    int totalMatches = 0;
    int categoryMatches = 0;

    for (final entry in _categoryPatterns.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          totalMatches++;
          if (entry.key == categoryName.toLowerCase() ||
              categoryName.toLowerCase().contains(entry.key)) {
            categoryMatches++;
          }
        }
      }
    }

    if (totalMatches == 0) return 0.0;
    
    // Base confidence from keyword matches
    double confidence = categoryMatches / totalMatches;
    
    // Boost confidence for longer descriptions (more context)
    if (text.length > 50) confidence += 0.1;
    if (text.length > 100) confidence += 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Generate explanation for why a category was suggested
  /// This simulates what an LLM would provide as reasoning
  static String generateExplanation({
    required String description,
    String? narration,
    required String categoryName,
  }) {
    final text = '${description.toLowerCase()} ${narration?.toLowerCase() ?? ''}'.trim();
    final matchedKeywords = <String>[];

    for (final entry in _categoryPatterns.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          matchedKeywords.add(keyword);
        }
      }
    }

    if (matchedKeywords.isEmpty) {
      return 'Suggested based on general transaction patterns.';
    }

    final keywordList = matchedKeywords.take(3).join(', ');
    return 'Categorized as "$categoryName" based on keywords: $keywordList';
  }
}
