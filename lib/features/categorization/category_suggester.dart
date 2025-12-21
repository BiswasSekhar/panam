import '../../data/models/category.dart';
import '../../data/models/transaction.dart';

class CategorySuggester {
  /// Suggest a category based on transaction description and amount
  static Category? suggestCategory({
    required String description,
    required double amount,
    required List<Category> availableCategories,
    required bool isIncome,
  }) {
    final descLower = description.toLowerCase();
    
    // Filter categories by income/expense type
    final relevantCats = availableCategories
        .where((c) => c.isIncome == isIncome)
        .toList();
    
    if (relevantCats.isEmpty) return null;
    
    // Rule-based categorization
    for (final rule in _categorizationRules) {
      if (rule.isIncome != isIncome) continue;
      
      for (final keyword in rule.keywords) {
        if (descLower.contains(keyword.toLowerCase())) {
          // Find matching category
          final match = relevantCats.where((c) => 
              c.name.toLowerCase() == rule.categoryName.toLowerCase()
          ).firstOrNull;
          
          if (match != null) return match;
        }
      }
    }
    
    // Default to uncategorized
    return relevantCats.where((c) => c.isDefault).firstOrNull;
  }
  
  /// Get most used categories based on transaction history
  static List<Category> getMostUsedCategories({
    required List<Transaction> transactions,
    required List<Category> availableCategories,
    required bool isIncome,
    int limit = 10,
  }) {
    // Count usage frequency
    final usageCount = <String, int>{};
    
    for (final txn in transactions) {
      if (txn.type == (isIncome ? TransactionType.income : TransactionType.expense)) {
        if (txn.categoryId != null) {
          usageCount[txn.categoryId!] = (usageCount[txn.categoryId!] ?? 0) + 1;
        }
      }
    }
    
    // Sort categories by usage
    final categoriesWithCount = availableCategories
        .where((c) => c.isIncome == isIncome)
        .map((c) => (category: c, count: usageCount[c.id] ?? 0))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    
    return categoriesWithCount
        .take(limit)
        .map((e) => e.category)
        .toList();
  }
  
  /// Sort categories intelligently: most used first, then alphabetically
  static List<Category> sortCategoriesSmartly({
    required List<Category> categories,
    required List<Transaction> transactions,
    required bool isIncome,
    String? selectedCategoryId,
  }) {
    final mostUsed = getMostUsedCategories(
      transactions: transactions,
      availableCategories: categories,
      isIncome: isIncome,
      limit: 5,
    );
    
    final mostUsedIds = mostUsed.map((c) => c.id).toSet();
    final remaining = categories
        .where((c) => !mostUsedIds.contains(c.id) && c.id != selectedCategoryId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    
    // Put selected first, then most used, then rest - no duplicates
    final sorted = <Category>[];
    final addedIds = <String>{};
    
    if (selectedCategoryId != null) {
      final selected = categories.where((c) => c.id == selectedCategoryId).firstOrNull;
      if (selected != null) {
        sorted.add(selected);
        addedIds.add(selected.id);
      }
    }
    
    for (final cat in mostUsed) {
      if (!addedIds.contains(cat.id)) {
        sorted.add(cat);
        addedIds.add(cat.id);
      }
    }
    
    for (final cat in remaining) {
      if (!addedIds.contains(cat.id)) {
        sorted.add(cat);
        addedIds.add(cat.id);
      }
    }
    
    return sorted;
  }
}

class _CategorizationRule {
  final String categoryName;
  final List<String> keywords;
  final bool isIncome;
  
  const _CategorizationRule({
    required this.categoryName,
    required this.keywords,
    this.isIncome = false,
  });
}

// Comprehensive categorization rules
const _categorizationRules = [
  // Food & Dining
  _CategorizationRule(
    categoryName: 'Groceries',
    keywords: ['grocery', 'supermarket', 'walmart', 'target', 'dmart', 'big bazaar', 'reliance fresh', 'more', 'vegetables', 'fruits'],
  ),
  _CategorizationRule(
    categoryName: 'Restaurants',
    keywords: ['restaurant', 'dining', 'bistro', 'cafe', 'eatery', 'zomato', 'swiggy', 'food delivery', 'hotel'],
  ),
  _CategorizationRule(
    categoryName: 'Fast Food',
    keywords: ['mcdonalds', 'kfc', 'burger king', 'pizza', 'dominos', 'subway', 'taco bell', 'wendys'],
  ),
  _CategorizationRule(
    categoryName: 'Cafes & Coffee',
    keywords: ['starbucks', 'coffee', 'cafe coffee day', 'barista', 'tea', 'bakery'],
  ),
  
  // Transportation
  _CategorizationRule(
    categoryName: 'Fuel',
    keywords: ['petrol', 'diesel', 'gas', 'fuel', 'bp', 'shell', 'indian oil', 'bharat petroleum', 'hp'],
  ),
  _CategorizationRule(
    categoryName: 'Public Transport',
    keywords: ['metro', 'bus', 'train', 'railway', 'uber', 'ola', 'transit', 'dmrc'],
  ),
  _CategorizationRule(
    categoryName: 'Taxi & Ride Share',
    keywords: ['uber', 'ola', 'lyft', 'taxi', 'cab', 'rapido', 'auto'],
  ),
  _CategorizationRule(
    categoryName: 'Parking',
    keywords: ['parking', 'valet'],
  ),
  
  // Bills & Utilities
  _CategorizationRule(
    categoryName: 'Electricity',
    keywords: ['electricity', 'electric', 'power', 'tata power', 'adani'],
  ),
  _CategorizationRule(
    categoryName: 'Water',
    keywords: ['water bill', 'municipal water'],
  ),
  _CategorizationRule(
    categoryName: 'Internet',
    keywords: ['internet', 'broadband', 'wifi', 'airtel', 'jio fiber', 'act fibernet'],
  ),
  _CategorizationRule(
    categoryName: 'Phone',
    keywords: ['mobile', 'phone bill', 'airtel', 'jio', 'vi', 'vodafone', 'bsnl', 'recharge'],
  ),
  _CategorizationRule(
    categoryName: 'Rent',
    keywords: ['rent', 'lease', 'landlord'],
  ),
  
  // Shopping
  _CategorizationRule(
    categoryName: 'Clothing',
    keywords: ['clothing', 'fashion', 'apparel', 'zara', 'h&m', 'nike', 'adidas', 'uniqlo', 'myntra'],
  ),
  _CategorizationRule(
    categoryName: 'Electronics',
    keywords: ['electronics', 'amazon', 'flipkart', 'apple', 'samsung', 'sony', 'croma', 'vijay sales'],
  ),
  _CategorizationRule(
    categoryName: 'Online Shopping',
    keywords: ['amazon', 'flipkart', 'ebay', 'online'],
  ),
  
  // Entertainment
  _CategorizationRule(
    categoryName: 'Movies & Cinema',
    keywords: ['cinema', 'movie', 'theater', 'pvr', 'inox', 'cinepolis', 'film'],
  ),
  _CategorizationRule(
    categoryName: 'Streaming Services',
    keywords: ['netflix', 'prime video', 'disney', 'hotstar', 'spotify', 'youtube premium', 'subscription'],
  ),
  _CategorizationRule(
    categoryName: 'Gaming',
    keywords: ['steam', 'playstation', 'xbox', 'nintendo', 'game'],
  ),
  
  // Health & Medical
  _CategorizationRule(
    categoryName: 'Doctor Visits',
    keywords: ['doctor', 'clinic', 'consultation', 'physician', 'hospital'],
  ),
  _CategorizationRule(
    categoryName: 'Pharmacy',
    keywords: ['pharmacy', 'medicine', 'drug', 'apollo', 'medplus', 'netmeds'],
  ),
  _CategorizationRule(
    categoryName: 'Dental',
    keywords: ['dentist', 'dental', 'orthodontist'],
  ),
  _CategorizationRule(
    categoryName: 'Lab Tests',
    keywords: ['lab', 'pathology', 'diagnostic', 'test', 'thyrocare', 'dr lal'],
  ),
  
  // Education
  _CategorizationRule(
    categoryName: 'Tuition Fees',
    keywords: ['tuition', 'school', 'college', 'university', 'course fee'],
  ),
  _CategorizationRule(
    categoryName: 'Books & Supplies',
    keywords: ['book', 'textbook', 'stationery', 'notebook'],
  ),
  _CategorizationRule(
    categoryName: 'Online Courses',
    keywords: ['udemy', 'coursera', 'skillshare', 'pluralsight', 'online course'],
  ),
  
  // Travel
  _CategorizationRule(
    categoryName: 'Hotels',
    keywords: ['hotel', 'resort', 'booking', 'airbnb', 'oyo', 'treebo', 'accommodation'],
  ),
  _CategorizationRule(
    categoryName: 'Flights',
    keywords: ['flight', 'airline', 'airways', 'indigo', 'spicejet', 'air india', 'vistara'],
  ),
  
  // Financial
  _CategorizationRule(
    categoryName: 'Bank Fees',
    keywords: ['bank charges', 'bank fee', 'service charge', 'annual fee'],
  ),
  _CategorizationRule(
    categoryName: 'Loan Payment',
    keywords: ['loan', 'emi', 'installment'],
  ),
  _CategorizationRule(
    categoryName: 'Credit Card Payment',
    keywords: ['credit card', 'cc payment'],
  ),
  _CategorizationRule(
    categoryName: 'Tax',
    keywords: ['tax', 'gst', 'income tax', 'tds'],
  ),
  
  // Income Categories
  _CategorizationRule(
    categoryName: 'Salary',
    keywords: ['salary', 'payroll', 'wages', 'monthly pay', 'wage', 'remuneration'],
    isIncome: true,
  ),
  _CategorizationRule(
    categoryName: 'Freelance',
    keywords: ['freelance', 'upwork', 'fiverr', 'consultant', 'project', 'contract work'],
    isIncome: true,
  ),
  _CategorizationRule(
    categoryName: 'Business Income',
    keywords: ['business', 'revenue', 'sales', 'profit', 'client payment'],
    isIncome: true,
  ),
  _CategorizationRule(
    categoryName: 'Interest',
    keywords: ['interest', 'fd interest', 'savings interest', 'deposit interest'],
    isIncome: true,
  ),
  _CategorizationRule(
    categoryName: 'Dividend',
    keywords: ['dividend', 'stock dividend', 'equity'],
    isIncome: true,
  ),
  _CategorizationRule(
    categoryName: 'Rental Income',
    keywords: ['rent received', 'rental', 'tenant', 'lease payment'],
    isIncome: true,
  ),
  _CategorizationRule(
    categoryName: 'Refund',
    keywords: ['refund', 'return', 'reimbursement'],
    isIncome: true,
  ),
  _CategorizationRule(
    categoryName: 'Bonus',
    keywords: ['bonus', 'incentive', 'performance pay', 'annual bonus'],
    isIncome: true,
  ),
  _CategorizationRule(
    categoryName: 'Commission',
    keywords: ['commission', 'sales commission', 'referral'],
    isIncome: true,
  ),
  _CategorizationRule(
    categoryName: 'Overtime',
    keywords: ['overtime', 'ot', 'extra hours'],
    isIncome: true,
  ),
  _CategorizationRule(
    categoryName: 'Cashback & Rewards',
    keywords: ['cashback', 'reward', 'points redeemed', 'credit card cashback'],
    isIncome: true,
  ),
  _CategorizationRule(
    categoryName: 'Gift Received',
    keywords: ['gift', 'present', 'donation received'],
    isIncome: true,
  ),
  _CategorizationRule(
    categoryName: 'Pension',
    keywords: ['pension', 'retirement', 'pf', 'provident fund'],
    isIncome: true,
  ),
  _CategorizationRule(
    categoryName: 'Investment Returns',
    keywords: ['investment', 'mutual fund', 'returns', 'capital gain'],
    isIncome: true,
  ),
];
