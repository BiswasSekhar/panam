import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/models/category.dart';
import '../data/local/hive_service.dart';

class CategoryProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  final HiveService _hive = HiveService();

  List<Category> _categories = const [];
  List<Category> get categories => _categories;

  CategoryProvider() {
    _refreshFromHive();
    _ensureSeededCategories();
    _refreshFromHive();
  }

  Future<void> reload({bool seedIfEmpty = true}) async {
    _refreshFromHive();
    if (seedIfEmpty) {
      _ensureSeededCategories();
      _refreshFromHive();
    }
  }

  void _refreshFromHive() {
    _categories = _hive.categoriesBox.values.toList(growable: false);
    notifyListeners();
  }

  void _ensureSeededCategories() {
    // If at least one category exists, don't seed.
    if (_hive.categoriesBox.isNotEmpty) return;

    final seeds = <Category>[
      // Expense Categories
      Category(id: _uuid.v4(), name: 'Uncategorized', icon: 'category', isIncome: false, isDefault: true, colorIndex: 0),
      
      // Food & Dining
      Category(id: _uuid.v4(), name: 'Groceries', icon: 'local_grocery_store', isIncome: false, colorIndex: 1),
      Category(id: _uuid.v4(), name: 'Restaurants', icon: 'restaurant', isIncome: false, colorIndex: 1),
      Category(id: _uuid.v4(), name: 'Fast Food', icon: 'fastfood', isIncome: false, colorIndex: 1),
      Category(id: _uuid.v4(), name: 'Cafes & Coffee', icon: 'local_cafe', isIncome: false, colorIndex: 1),
      Category(id: _uuid.v4(), name: 'Food Delivery', icon: 'delivery_dining', isIncome: false, colorIndex: 1),
      
      // Transportation
      Category(id: _uuid.v4(), name: 'Fuel', icon: 'local_gas_station', isIncome: false, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Public Transport', icon: 'directions_bus', isIncome: false, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Taxi & Ride Share', icon: 'local_taxi', isIncome: false, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Parking', icon: 'local_parking', isIncome: false, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Vehicle Maintenance', icon: 'build', isIncome: false, colorIndex: 2),
      
      // Shopping
      Category(id: _uuid.v4(), name: 'Clothing', icon: 'checkroom', isIncome: false, colorIndex: 4),
      Category(id: _uuid.v4(), name: 'Electronics', icon: 'devices', isIncome: false, colorIndex: 4),
      Category(id: _uuid.v4(), name: 'Furniture', icon: 'weekend', isIncome: false, colorIndex: 4),
      Category(id: _uuid.v4(), name: 'General Shopping', icon: 'shopping_bag', isIncome: false, colorIndex: 4),
      Category(id: _uuid.v4(), name: 'Online Shopping', icon: 'shopping_cart', isIncome: false, colorIndex: 4),
      
      // Bills & Utilities
      Category(id: _uuid.v4(), name: 'Electricity', icon: 'electric_bolt', isIncome: false, colorIndex: 3),
      Category(id: _uuid.v4(), name: 'Water', icon: 'water_drop', isIncome: false, colorIndex: 3),
      Category(id: _uuid.v4(), name: 'Gas', icon: 'propane_tank', isIncome: false, colorIndex: 3),
      Category(id: _uuid.v4(), name: 'Internet', icon: 'wifi', isIncome: false, colorIndex: 3),
      Category(id: _uuid.v4(), name: 'Phone', icon: 'phone', isIncome: false, colorIndex: 3),
      Category(id: _uuid.v4(), name: 'Rent', icon: 'home', isIncome: false, colorIndex: 3),
      Category(id: _uuid.v4(), name: 'Home Insurance', icon: 'shield', isIncome: false, colorIndex: 3),
      
      // Entertainment
      Category(id: _uuid.v4(), name: 'Movies & Cinema', icon: 'movie', isIncome: false, colorIndex: 5),
      Category(id: _uuid.v4(), name: 'Streaming Services', icon: 'subscriptions', isIncome: false, colorIndex: 5),
      Category(id: _uuid.v4(), name: 'Gaming', icon: 'sports_esports', isIncome: false, colorIndex: 5),
      Category(id: _uuid.v4(), name: 'Events & Concerts', icon: 'celebration', isIncome: false, colorIndex: 5),
      Category(id: _uuid.v4(), name: 'Sports & Fitness', icon: 'fitness_center', isIncome: false, colorIndex: 5),
      
      // Health & Medical
      Category(id: _uuid.v4(), name: 'Doctor Visits', icon: 'medical_services', isIncome: false, colorIndex: 6),
      Category(id: _uuid.v4(), name: 'Pharmacy', icon: 'local_pharmacy', isIncome: false, colorIndex: 6),
      Category(id: _uuid.v4(), name: 'Dental', icon: 'dentistry', isIncome: false, colorIndex: 6),
      Category(id: _uuid.v4(), name: 'Health Insurance', icon: 'health_and_safety', isIncome: false, colorIndex: 6),
      Category(id: _uuid.v4(), name: 'Lab Tests', icon: 'biotech', isIncome: false, colorIndex: 6),
      
      // Education
      Category(id: _uuid.v4(), name: 'Tuition Fees', icon: 'school', isIncome: false, colorIndex: 7),
      Category(id: _uuid.v4(), name: 'Books & Supplies', icon: 'menu_book', isIncome: false, colorIndex: 7),
      Category(id: _uuid.v4(), name: 'Online Courses', icon: 'laptop_chromebook', isIncome: false, colorIndex: 7),
      Category(id: _uuid.v4(), name: 'Stationary', icon: 'edit_note', isIncome: false, colorIndex: 7),
      
      // Personal Care
      Category(id: _uuid.v4(), name: 'Salon & Grooming', icon: 'content_cut', isIncome: false, colorIndex: 0),
      Category(id: _uuid.v4(), name: 'Cosmetics', icon: 'face', isIncome: false, colorIndex: 0),
      Category(id: _uuid.v4(), name: 'Gym Membership', icon: 'fitness_center', isIncome: false, colorIndex: 0),
      
      // Travel
      Category(id: _uuid.v4(), name: 'Hotels', icon: 'hotel', isIncome: false, colorIndex: 1),
      Category(id: _uuid.v4(), name: 'Flights', icon: 'flight', isIncome: false, colorIndex: 1),
      Category(id: _uuid.v4(), name: 'Travel Insurance', icon: 'luggage', isIncome: false, colorIndex: 1),
      Category(id: _uuid.v4(), name: 'Vacation', icon: 'beach_access', isIncome: false, colorIndex: 1),
      
      // Subscriptions
      Category(id: _uuid.v4(), name: 'Music Streaming', icon: 'music_note', isIncome: false, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Video Streaming', icon: 'ondemand_video', isIncome: false, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Cloud Storage', icon: 'cloud', isIncome: false, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Software', icon: 'computer', isIncome: false, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Magazines', icon: 'auto_stories', isIncome: false, colorIndex: 2),
      
      // Gifts & Donations
      Category(id: _uuid.v4(), name: 'Gifts', icon: 'card_giftcard', isIncome: false, colorIndex: 3),
      Category(id: _uuid.v4(), name: 'Charity', icon: 'volunteer_activism', isIncome: false, colorIndex: 3),
      Category(id: _uuid.v4(), name: 'Donations', icon: 'favorite', isIncome: false, colorIndex: 3),
      
      // Financial
      Category(id: _uuid.v4(), name: 'Bank Fees', icon: 'account_balance', isIncome: false, colorIndex: 4),
      Category(id: _uuid.v4(), name: 'Loan Payment', icon: 'payments', isIncome: false, colorIndex: 4),
      Category(id: _uuid.v4(), name: 'Credit Card Payment', icon: 'credit_card', isIncome: false, colorIndex: 4),
      Category(id: _uuid.v4(), name: 'Tax', icon: 'receipt_long', isIncome: false, colorIndex: 4),
      Category(id: _uuid.v4(), name: 'Investment', icon: 'trending_up', isIncome: false, colorIndex: 4),
      
      // Pets
      Category(id: _uuid.v4(), name: 'Pet Food', icon: 'pets', isIncome: false, colorIndex: 5),
      Category(id: _uuid.v4(), name: 'Veterinary', icon: 'medical_services', isIncome: false, colorIndex: 5),
      Category(id: _uuid.v4(), name: 'Pet Supplies', icon: 'pets', isIncome: false, colorIndex: 5),
      
      // Miscellaneous
      Category(id: _uuid.v4(), name: 'Laundry', icon: 'local_laundry_service', isIncome: false, colorIndex: 6),
      Category(id: _uuid.v4(), name: 'Postal Services', icon: 'mail', isIncome: false, colorIndex: 6),
      Category(id: _uuid.v4(), name: 'Legal Services', icon: 'gavel', isIncome: false, colorIndex: 6),
      Category(id: _uuid.v4(), name: 'Repairs', icon: 'handyman', isIncome: false, colorIndex: 7),
      Category(id: _uuid.v4(), name: 'Childcare', icon: 'child_care', isIncome: false, colorIndex: 1),
      Category(id: _uuid.v4(), name: 'Baby Products', icon: 'baby_changing_station', isIncome: false, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Household Items', icon: 'countertops', isIncome: false, colorIndex: 3),
      Category(id: _uuid.v4(), name: 'Office Supplies', icon: 'business', isIncome: false, colorIndex: 4),
      Category(id: _uuid.v4(), name: 'Garden & Plants', icon: 'yard', isIncome: false, colorIndex: 5),
      Category(id: _uuid.v4(), name: 'Home Improvement', icon: 'home_repair_service', isIncome: false, colorIndex: 6),
      Category(id: _uuid.v4(), name: 'Beauty & Spa', icon: 'spa', isIncome: false, colorIndex: 7),
      Category(id: _uuid.v4(), name: 'Newspapers', icon: 'newspaper', isIncome: false, colorIndex: 0),
      Category(id: _uuid.v4(), name: 'ATM Withdrawal', icon: 'atm', isIncome: false, colorIndex: 1),
      Category(id: _uuid.v4(), name: 'Transfer', icon: 'sync_alt', isIncome: false, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Other', icon: 'more_horiz', isIncome: false, colorIndex: 7),
      
      // Income Categories
      Category(id: _uuid.v4(), name: 'Uncategorized', icon: 'category', isIncome: true, isDefault: true, colorIndex: 0),
      Category(id: _uuid.v4(), name: 'Salary', icon: '💰', isIncome: true, colorIndex: 1),
      Category(id: _uuid.v4(), name: 'Wage', icon: 'payments', isIncome: true, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Freelance', icon: '💼', isIncome: true, colorIndex: 3),
      Category(id: _uuid.v4(), name: 'Business Income', icon: 'business_center', isIncome: true, colorIndex: 4),
      Category(id: _uuid.v4(), name: 'Commission', icon: 'sell', isIncome: true, colorIndex: 5),
      Category(id: _uuid.v4(), name: 'Interest', icon: '📈', isIncome: true, colorIndex: 6),
      Category(id: _uuid.v4(), name: 'Dividend', icon: 'account_balance', isIncome: true, colorIndex: 7),
      Category(id: _uuid.v4(), name: 'Rental Income', icon: '🏠', isIncome: true, colorIndex: 0),
      Category(id: _uuid.v4(), name: 'Investment Returns', icon: 'trending_up', isIncome: true, colorIndex: 1),
      Category(id: _uuid.v4(), name: 'Refund', icon: '↩️', isIncome: true, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Bonus', icon: '🎁', isIncome: true, colorIndex: 3),
      Category(id: _uuid.v4(), name: 'Overtime', icon: 'schedule', isIncome: true, colorIndex: 4),
      Category(id: _uuid.v4(), name: 'Tips & Gratuity', icon: 'volunteer_activism', isIncome: true, colorIndex: 5),
      Category(id: _uuid.v4(), name: 'Gift Received', icon: 'redeem', isIncome: true, colorIndex: 6),
      Category(id: _uuid.v4(), name: 'Cashback & Rewards', icon: '🎯', isIncome: true, colorIndex: 7),
      Category(id: _uuid.v4(), name: 'Pension', icon: 'elderly', isIncome: true, colorIndex: 0),
      Category(id: _uuid.v4(), name: 'Government Benefits', icon: 'account_balance_wallet', isIncome: true, colorIndex: 1),
      Category(id: _uuid.v4(), name: 'Scholarship', icon: 'school', isIncome: true, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Tax Return', icon: 'receipt_long', isIncome: true, colorIndex: 3),
      Category(id: _uuid.v4(), name: 'Sale of Items', icon: '🛍️', isIncome: true, colorIndex: 4),
      Category(id: _uuid.v4(), name: 'Prize & Lottery', icon: 'emoji_events', isIncome: true, colorIndex: 5),
      Category(id: _uuid.v4(), name: 'Royalty', icon: 'copyright', isIncome: true, colorIndex: 6),
      Category(id: _uuid.v4(), name: 'Other Income', icon: 'attach_money', isIncome: true, colorIndex: 7),
    ];

    for (final c in seeds) {
      _hive.categoriesBox.put(c.id, c);
    }
  }

  Future<Category> createCategory({
    required String name,
    required bool isIncome,
    String? icon,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    final c = Category(
      id: _uuid.v4(),
      name: trimmed,
      icon: icon ?? 'category',
      isIncome: isIncome,
      isDefault: false,
      colorIndex: 0,
    );
    await _hive.categoriesBox.put(c.id, c);
    _refreshFromHive();
    return c;
  }
}
