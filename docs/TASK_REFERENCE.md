# Panam - Step-by-Step Task Reference
## For AI Agent Implementation

This document provides detailed, atomic tasks that an AI agent can follow to build the Panam expense manager app.

---

## PHASE 1: PROJECT SETUP

### Task 1.1: Update pubspec.yaml
**Priority:** HIGH  
**Depends on:** None

**Action:** Replace the dependencies section in `pubspec.yaml` with:

```yaml
name: panam
description: "Panam - Personal Expense Manager"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.10.4

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.2
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Unique IDs
  uuid: ^4.5.1
  
  # File Operations
  file_picker: ^8.1.6
  image_picker: ^1.1.2
  path_provider: ^2.1.5
  
  # OCR
  google_mlkit_text_recognition: ^0.14.0
  
  # PDF Parsing
  syncfusion_flutter_pdf: ^28.2.6
  
  # UI Helpers
  intl: ^0.20.2
  flutter_slidable: ^4.0.0
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.13

flutter:
  uses-material-design: true
```

**Verification:** Run `flutter pub get` successfully

---

### Task 1.2: Create Folder Structure
**Priority:** HIGH  
**Depends on:** Task 1.1

**Action:** Create these directories under `lib/`:

```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   └── local/
│       └── adapters/
├── providers/
├── services/
├── screens/
│   ├── home/
│   │   └── widgets/
│   ├── transactions/
│   │   └── widgets/
│   ├── accounts/
│   │   └── widgets/
│   ├── import/
│   │   └── widgets/
│   └── settings/
└── widgets/
    ├── common/
    └── dialogs/
```

---

### Task 1.3: Create App Constants
**Priority:** HIGH  
**Depends on:** Task 1.2

**File:** `lib/core/constants/app_constants.dart`

```dart
class AppConstants {
  static const String appName = 'Panam';
  static const String appVersion = '1.0.0';
  
  // Hive Box Names
  static const String transactionsBox = 'transactions';
  static const String accountsBox = 'accounts';
  static const String categoriesBox = 'categories';
  static const String settingsBox = 'settings';
  
  // Default values
  static const String defaultCurrency = '₹';
  static const int recentTransactionsLimit = 10;
}
```

---

### Task 1.4: Create Color Constants
**Priority:** MEDIUM  
**Depends on:** Task 1.2

**File:** `lib/core/constants/colors.dart`

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6200EE);
  static const Color primaryVariant = Color(0xFF3700B3);
  static const Color secondary = Color(0xFF03DAC6);
  
  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  
  // Text Colors
  static const Color onPrimary = Colors.white;
  static const Color onBackground = Color(0xFF1C1C1C);
  static const Color onSurface = Color(0xFF1C1C1C);
  
  // Semantic Colors
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  
  // Category Colors
  static const List<Color> categoryColors = [
    Color(0xFFE57373), // Red
    Color(0xFFBA68C8), // Purple
    Color(0xFF64B5F6), // Blue
    Color(0xFF4DB6AC), // Teal
    Color(0xFFFFD54F), // Yellow
    Color(0xFFFF8A65), // Orange
    Color(0xFFA1887F), // Brown
    Color(0xFF90A4AE), // Grey
  ];
}
```

---

### Task 1.5: Create String Constants
**Priority:** MEDIUM  
**Depends on:** Task 1.2

**File:** `lib/core/constants/strings.dart`

```dart
class AppStrings {
  // Navigation
  static const String home = 'Home';
  static const String transactions = 'Transactions';
  static const String accounts = 'Accounts';
  static const String settings = 'Settings';
  
  // Dashboard
  static const String totalBalance = 'Total Balance';
  static const String income = 'Income';
  static const String expense = 'Expense';
  static const String recentTransactions = 'Recent Transactions';
  static const String viewAll = 'View All';
  
  // Transactions
  static const String addTransaction = 'Add Transaction';
  static const String editTransaction = 'Edit Transaction';
  static const String deleteTransaction = 'Delete Transaction';
  static const String amount = 'Amount';
  static const String description = 'Description';
  static const String date = 'Date';
  static const String category = 'Category';
  static const String account = 'Account';
  static const String note = 'Note (Optional)';
  
  // Accounts
  static const String addAccount = 'Add Account';
  static const String editAccount = 'Edit Account';
  static const String deleteAccount = 'Delete Account';
  static const String accountName = 'Account Name';
  static const String accountType = 'Account Type';
  static const String initialBalance = 'Initial Balance';
  
  // Import
  static const String scanReceipt = 'Scan Receipt';
  static const String importStatement = 'Import Statement';
  static const String takePhoto = 'Take Photo';
  static const String chooseFromGallery = 'Choose from Gallery';
  static const String processing = 'Processing...';
  static const String importSelected = 'Import Selected';
  
  // Actions
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String confirm = 'Confirm';
  
  // Messages
  static const String noTransactions = 'No transactions yet';
  static const String noAccounts = 'No accounts yet';
  static const String addFirstAccount = 'Add your first account to get started';
  static const String addFirstTransaction = 'Add your first transaction';
  static const String deleteConfirmation = 'Are you sure you want to delete this?';
  static const String successfullyAdded = 'Successfully added';
  static const String successfullyDeleted = 'Successfully deleted';
  
  // Errors
  static const String errorOccurred = 'An error occurred';
  static const String invalidAmount = 'Please enter a valid amount';
  static const String requiredField = 'This field is required';
  static const String ocrFailed = 'Could not extract text from image';
  static const String parseFailed = 'Could not parse the statement';
}
```

---

### Task 1.6: Create Transaction Model
**Priority:** HIGH  
**Depends on:** Task 1.2

**File:** `lib/data/models/transaction.dart`

```dart
import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String categoryId;

  @HiveField(5)
  final String accountId;

  @HiveField(6)
  final TransactionType type;

  @HiveField(7)
  final String? note;

  @HiveField(8)
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.categoryId,
    required this.accountId,
    required this.type,
    this.note,
    required this.createdAt,
  });

  Transaction copyWith({
    String? id,
    double? amount,
    String? description,
    DateTime? date,
    String? categoryId,
    String? accountId,
    TransactionType? type,
    String? note,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

---

### Task 1.7: Create Account Model
**Priority:** HIGH  
**Depends on:** Task 1.2

**File:** `lib/data/models/account.dart`

```dart
import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 2)
enum AccountType {
  @HiveField(0)
  cash,
  @HiveField(1)
  bank,
  @HiveField(2)
  wallet,
  @HiveField(3)
  card,
  @HiveField(4)
  other,
}

@HiveType(typeId: 3)
class Account extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final AccountType type;

  @HiveField(3)
  final double initialBalance;

  @HiveField(4)
  final String? icon;

  @HiveField(5)
  final DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
    this.icon,
    required this.createdAt,
  });

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? initialBalance,
    String? icon,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.wallet:
        return 'Digital Wallet';
      case AccountType.card:
        return 'Credit Card';
      case AccountType.other:
        return 'Other';
    }
  }
}
```

---

### Task 1.8: Create Category Model
**Priority:** HIGH  
**Depends on:** Task 1.2

**File:** `lib/data/models/category.dart`

```dart
import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 4)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String icon;

  @HiveField(3)
  final bool isIncome;

  @HiveField(4)
  final bool isDefault;

  @HiveField(5)
  final int colorIndex;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.isIncome,
    this.isDefault = false,
    this.colorIndex = 0,
  });

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isIncome,
    bool? isDefault,
    int? colorIndex,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isIncome: isIncome ?? this.isIncome,
      isDefault: isDefault ?? this.isDefault,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }
}
```

---

### Task 1.9: Create Hive Service
**Priority:** HIGH  
**Depends on:** Tasks 1.6, 1.7, 1.8

**File:** `lib/data/local/hive_service.dart`

```dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../../core/constants/app_constants.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  late Box<Transaction> _transactionsBox;
  late Box<Account> _accountsBox;
  late Box<Category> _categoriesBox;

  Box<Transaction> get transactionsBox => _transactionsBox;
  Box<Account> get accountsBox => _accountsBox;
  Box<Category> get categoriesBox => _categoriesBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(AccountTypeAdapter());
    Hive.registerAdapter(AccountAdapter());
    Hive.registerAdapter(CategoryAdapter());

    // Open boxes
    _transactionsBox = await Hive.openBox<Transaction>(AppConstants.transactionsBox);
    _accountsBox = await Hive.openBox<Account>(AppConstants.accountsBox);
    _categoriesBox = await Hive.openBox<Category>(AppConstants.categoriesBox);

    // Seed default categories if empty
    if (_categoriesBox.isEmpty) {
      await _seedDefaultCategories();
    }
  }

  Future<void> _seedDefaultCategories() async {
    final defaultExpenseCategories = [
      Category(id: 'cat_food', name: 'Food & Dining', icon: '🍔', isIncome: false, isDefault: true, colorIndex: 0),
      Category(id: 'cat_transport', name: 'Transport', icon: '🚗', isIncome: false, isDefault: true, colorIndex: 1),
      Category(id: 'cat_shopping', name: 'Shopping', icon: '🛒', isIncome: false, isDefault: true, colorIndex: 2),
      Category(id: 'cat_housing', name: 'Housing', icon: '🏠', isIncome: false, isDefault: true, colorIndex: 3),
      Category(id: 'cat_utilities', name: 'Utilities', icon: '💡', isIncome: false, isDefault: true, colorIndex: 4),
      Category(id: 'cat_entertainment', name: 'Entertainment', icon: '🎬', isIncome: false, isDefault: true, colorIndex: 5),
      Category(id: 'cat_healthcare', name: 'Healthcare', icon: '💊', isIncome: false, isDefault: true, colorIndex: 6),
      Category(id: 'cat_education', name: 'Education', icon: '📚', isIncome: false, isDefault: true, colorIndex: 7),
      Category(id: 'cat_personal', name: 'Personal Care', icon: '👔', isIncome: false, isDefault: true, colorIndex: 0),
      Category(id: 'cat_gifts', name: 'Gifts', icon: '🎁', isIncome: false, isDefault: true, colorIndex: 1),
      Category(id: 'cat_other_expense', name: 'Other', icon: '📦', isIncome: false, isDefault: true, colorIndex: 2),
    ];

    final defaultIncomeCategories = [
      Category(id: 'cat_salary', name: 'Salary', icon: '💼', isIncome: true, isDefault: true, colorIndex: 3),
      Category(id: 'cat_freelance', name: 'Freelance', icon: '💰', isIncome: true, isDefault: true, colorIndex: 4),
      Category(id: 'cat_investment', name: 'Investment', icon: '📈', isIncome: true, isDefault: true, colorIndex: 5),
      Category(id: 'cat_gift_received', name: 'Gift Received', icon: '🎁', isIncome: true, isDefault: true, colorIndex: 6),
      Category(id: 'cat_other_income', name: 'Other Income', icon: '💵', isIncome: true, isDefault: true, colorIndex: 7),
    ];

    for (final category in [...defaultExpenseCategories, ...defaultIncomeCategories]) {
      await _categoriesBox.put(category.id, category);
    }
  }

  Future<void> clearAllData() async {
    await _transactionsBox.clear();
    await _accountsBox.clear();
    await _categoriesBox.clear();
    await _seedDefaultCategories();
  }
}
```

---

### Task 1.10: Generate Hive Adapters
**Priority:** HIGH  
**Depends on:** Tasks 1.6, 1.7, 1.8

**Action:** Run the following command to generate Hive adapters:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This will generate:
- `lib/data/models/transaction.g.dart`
- `lib/data/models/account.g.dart`
- `lib/data/models/category.g.dart`

---

### Task 1.11: Create App Theme
**Priority:** MEDIUM  
**Depends on:** Task 1.4

**File:** `lib/core/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
```

---

### Task 1.12: Create Utility Functions
**Priority:** MEDIUM  
**Depends on:** Task 1.2

**File:** `lib/core/utils/date_utils.dart`

```dart
import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return formatDate(date);
    }
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
```

**File:** `lib/core/utils/currency_utils.dart`

```dart
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyUtils {
  static final _formatter = NumberFormat.currency(
    symbol: AppConstants.defaultCurrency,
    decimalDigits: 2,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static String formatCompact(double amount) {
    if (amount.abs() >= 1000000) {
      return '${AppConstants.defaultCurrency}${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '${AppConstants.defaultCurrency}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }

  static double? parse(String value) {
    final cleanValue = value.replaceAll(AppConstants.defaultCurrency, '').replaceAll(',', '').trim();
    return double.tryParse(cleanValue);
  }
}
```

**File:** `lib/core/utils/validators.dart`

```dart
class Validators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an amount';
    }
    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null) {
      return 'Please enter a valid number';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }

  static String? minLength(String? value, int minLength) {
    if (value == null || value.length < minLength) {
      return 'Minimum $minLength characters required';
    }
    return null;
  }
}
```

---

### Task 1.13: Update main.dart
**Priority:** HIGH  
**Depends on:** Tasks 1.9, 1.11

**File:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/local/hive_service.dart';
import 'providers/app_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/account_provider.dart';
import 'providers/category_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await HiveService().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: const PanamApp(),
    ),
  );
}
```

---

### Task 1.14: Create App Widget
**Priority:** HIGH  
**Depends on:** Task 1.13

**File:** `lib/app.dart`

```dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'screens/home/home_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/accounts/accounts_screen.dart';
import 'screens/settings/settings_screen.dart';

class PanamApp extends StatelessWidget {
  const PanamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
```

---

## PHASE 2: PROVIDERS & REPOSITORIES

(Continue with detailed tasks for each provider and repository...)

---

## Quick Reference: File Creation Order

### Must create in order (dependencies):
1. `pubspec.yaml` (update)
2. Folder structure
3. Constants files
4. Model files (transaction.dart, account.dart, category.dart)
5. Run `build_runner` to generate adapters
6. `hive_service.dart`
7. Repository files
8. Provider files
9. `app_theme.dart`
10. Utility files
11. `main.dart`
12. `app.dart`
13. Screen files (stub versions first)
14. Widget files
15. Service files (OCR, Parser)

---

## Testing Checkpoints

After each phase, verify:

1. **Phase 1 Complete:** App runs, shows bottom navigation, Hive initializes
2. **Phase 2 Complete:** Can add/view transactions and accounts
3. **Phase 3 Complete:** OCR scanning works on physical device
4. **Phase 4 Complete:** Statement import works, MVP ready
