import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/local/hive_service.dart';
import '../data/models/account.dart';
import '../data/models/transaction.dart';

class AccountProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  final HiveService _hive = HiveService();
  List<Account> _accounts = const [];

  List<Account> get accounts => _accounts;

  AccountProvider() {
    _refreshFromHive();
    if (_accounts.isEmpty) {
      _seedDefaultAccounts();
    }
  }

  Future<void> reload({bool seedIfEmpty = true}) async {
    _refreshFromHive();
    if (seedIfEmpty && _accounts.isEmpty) {
      await _seedDefaultAccounts();
    }
  }

  void _refreshFromHive() {
    _accounts = _hive.accountsBox.values.toList(growable: false);
    notifyListeners();
  }

  Future<void> _seedDefaultAccounts() async {
    final cash = Account(
      id: _uuid.v4(),
      name: 'Cash',
      type: AccountType.cash,
      initialBalance: 0.0,
      icon: 'cash',
      createdAt: DateTime.now(),
    );
    await _hive.accountsBox.put(cash.id, cash);
    _refreshFromHive();
  }

  Future<void> addAccount({
    required String name,
    required AccountType type,
    double initialBalance = 0.0,
    String? icon,
  }) async {
    final id = _uuid.v4();
    final account = Account(
      id: id,
      name: name,
      type: type,
      initialBalance: initialBalance,
      icon: icon,
      createdAt: DateTime.now(),
    );
    await _hive.accountsBox.put(id, account);
    _refreshFromHive();
  }

  Future<void> deleteAccount(String id) async {
    await _hive.accountsBox.delete(id);
    _refreshFromHive();
  }

  Future<void> updateAccount(Account account) async {
    await _hive.accountsBox.put(account.id, account);
    _refreshFromHive();
  }

  double getAccountBalance(String accountId) {
    final account = _accounts.where((a) => a.id == accountId).firstOrNull;
    if (account == null) return 0.0;

    final txns = _hive.transactionsBox.values.where((t) => t.accountId == accountId);
    final income = txns.where((t) => t.type == TransactionType.income).fold<double>(0, (s, t) => s + t.amount);
    final expense = txns.where((t) => t.type == TransactionType.expense).fold<double>(0, (s, t) => s + t.amount);
    return account.initialBalance + income - expense;
  }

  /// Returns (income, expense) for a single account. Includes ALL transactions
  /// (even self-transfers) because they affect the individual account balance.
  ({double income, double expense}) getAccountIncomeExpense(String accountId) {
    final txns = _hive.transactionsBox.values.where((t) => t.accountId == accountId);
    final income = txns.where((t) => t.type == TransactionType.income).fold<double>(0, (s, t) => s + t.amount);
    final expense = txns.where((t) => t.type == TransactionType.expense).fold<double>(0, (s, t) => s + t.amount);
    return (income: income, expense: expense);
  }
}
