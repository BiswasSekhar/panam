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
      // Expense
      Category(id: _uuid.v4(), name: 'Uncategorized', icon: 'category', isIncome: false, isDefault: true, colorIndex: 0),
      Category(id: _uuid.v4(), name: 'Food', icon: 'restaurant', isIncome: false, colorIndex: 1),
      Category(id: _uuid.v4(), name: 'Transport', icon: 'directions_car', isIncome: false, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Bills', icon: 'receipt', isIncome: false, colorIndex: 3),
      Category(id: _uuid.v4(), name: 'Shopping', icon: 'shopping_bag', isIncome: false, colorIndex: 4),
      // Income
      Category(id: _uuid.v4(), name: 'Uncategorized', icon: 'category', isIncome: true, isDefault: true, colorIndex: 0),
      Category(id: _uuid.v4(), name: 'Salary', icon: 'payments', isIncome: true, colorIndex: 1),
      Category(id: _uuid.v4(), name: 'Interest', icon: 'savings', isIncome: true, colorIndex: 2),
      Category(id: _uuid.v4(), name: 'Refund', icon: 'history', isIncome: true, colorIndex: 3),
    ];

    for (final c in seeds) {
      _hive.categoriesBox.put(c.id, c);
    }
  }

  Future<Category> createCategory({
    required String name,
    required bool isIncome,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    final c = Category(
      id: _uuid.v4(),
      name: trimmed,
      icon: 'category',
      isIncome: isIncome,
      isDefault: false,
      colorIndex: 0,
    );
    await _hive.categoriesBox.put(c.id, c);
    _refreshFromHive();
    return c;
  }
}
