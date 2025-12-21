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
  late Box<String> _settingsBox;

  Box<Transaction> get transactionsBox => _transactionsBox;
  Box<Account> get accountsBox => _accountsBox;
  Box<Category> get categoriesBox => _categoriesBox;
  Box<String> get settingsBox => _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(TransactionSourceAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(AccountTypeAdapter());
    Hive.registerAdapter(AccountAdapter());
    Hive.registerAdapter(CategoryAdapter());

    // Open boxes
    _transactionsBox = await Hive.openBox<Transaction>(AppConstants.transactionsBox);
    _accountsBox = await Hive.openBox<Account>(AppConstants.accountsBox);
    _categoriesBox = await Hive.openBox<Category>(AppConstants.categoriesBox);
    _settingsBox = await Hive.openBox<String>(AppConstants.settingsBox);
  }
}
