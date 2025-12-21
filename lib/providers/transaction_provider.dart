import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/local/hive_service.dart';
import '../data/models/account.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';

class ImportResult {
  final int total;
  final int imported;
  final int skippedDuplicates;
  final int duplicatesDetected;

  const ImportResult({
    required this.total,
    required this.imported,
    required this.skippedDuplicates,
    required this.duplicatesDetected,
  });
}

class TransactionProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  final HiveService _hive = HiveService();
  List<Transaction> _transactions = const [];

  List<Transaction> get transactions => _transactions;
  List<Transaction> get recentTransactions {
    final sorted = [..._transactions]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList(growable: false);
  }

  TransactionProvider() {
    _refreshFromHive();
  }

  void reload() => _refreshFromHive();

  void _refreshFromHive() {
    _transactions = _hive.transactionsBox.values.toList(growable: false);
    notifyListeners();
  }

  String _normalize(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9 \-_/]'), '');
  }

  String _normalizeRef(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9\-_/]'), '');
  }

  int _dayDistance(DateTime a, DateTime b) {
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return (da.difference(db).inDays).abs();
  }

  bool _looksLikeTransferText(String description) {
    final d = description.toLowerCase();
    return d.contains('self') ||
        d.contains('transfer') ||
        d.contains('upi') ||
        d.contains('imps') ||
        d.contains('neft') ||
        d.contains('rtgs');
  }

  Transaction _copyWithIsSelfTransfer(Transaction t, bool flag) {
    return Transaction(
      id: t.id,
      amount: t.amount,
      description: t.description,
      date: t.date,
      categoryId: t.categoryId,
      accountId: t.accountId,
      type: t.type,
      note: t.note,
      createdAt: t.createdAt,
      externalRef: t.externalRef,
      dedupKey: t.dedupKey,
      source: t.source,
      isSelfTransfer: flag,
      importSequence: t.importSequence,
    );
  }

  Transaction? _findExistingSelfTransferMatch({
    required String importingAccountId,
    required ({
      DateTime date,
      double amount,
      TransactionType type,
      String description,
      String? externalRef,
      bool isSelfTransfer,
    }) item,
    required List<Transaction> existing,
  }) {
    // Self-transfer must be across different accounts.
    final oppositeType = item.type == TransactionType.income
        ? TransactionType.expense
        : TransactionType.income;

    final refNorm = item.externalRef == null ? null : _normalizeRef(item.externalRef!);

    // Prefer externalRef match when available.
    if (refNorm != null && refNorm.isNotEmpty) {
      Transaction? best;
      var bestDayDistance = 999;
      for (final t in existing) {
        if (t.accountId == importingAccountId) continue;
        if (t.type != oppositeType) continue;
        if ((t.amount - item.amount).abs() > 0.01) continue;
        if (t.externalRef == null) continue;
        final tRefNorm = _normalizeRef(t.externalRef!);
        if (tRefNorm != refNorm) continue;
        final dist = _dayDistance(t.date, item.date);
        if (dist > 1) continue;
        if (dist < bestDayDistance) {
          best = t;
          bestDayDistance = dist;
          if (bestDayDistance == 0) break;
        }
      }
      if (best != null) return best;
    }

    // Fallback: only attempt fuzzy matching when the statement row strongly suggests a transfer.
    final shouldTryFuzzy = item.isSelfTransfer || _looksLikeTransferText(item.description);
    if (!shouldTryFuzzy) return null;

    Transaction? best;
    var bestDayDistance = 999;
    for (final t in existing) {
      if (t.accountId == importingAccountId) continue;
      if (t.type != oppositeType) continue;
      if ((t.amount - item.amount).abs() > 0.01) continue;
      final dist = _dayDistance(t.date, item.date);
      if (dist > 0) continue; // keep conservative: same calendar day
      // If existing already indicates self-transfer, it's a strong candidate.
      final existingSuggestsTransfer =
          t.isSelfTransfer == true || _looksLikeTransferText(t.description);
      if (!existingSuggestsTransfer) continue;
      if (dist < bestDayDistance) {
        best = t;
        bestDayDistance = dist;
      }
    }
    return best;
  }

  String _dateKey(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _buildDedupKey({
    required String accountId,
    required DateTime date,
    required double amount,
    required String description,
    String? externalRef,
  }) {
    final amt = amount.toStringAsFixed(2);
    final ref = externalRef == null ? '' : _normalize(externalRef);
    final desc = _normalize(description);
    return '$accountId|${_dateKey(date)}|$amt|$ref|$desc';
  }

  String _ensureDefaultAccountId() {
    final box = _hive.accountsBox;
    if (box.isNotEmpty) return box.values.first.id;

    final id = _uuid.v4();
    final account = Account(
      id: id,
      name: 'Cash',
      type: AccountType.cash,
      initialBalance: 0.0,
      createdAt: DateTime.now(),
    );
    box.put(id, account);
    return id;
  }

  String ensureDefaultAccountId() => _ensureDefaultAccountId();

  int countPossibleDuplicatesForImport({
    required String accountId,
    required List<({
      DateTime date,
      double amount,
      TransactionType type,
      String description,
      String? externalRef,
      bool isSelfTransfer,
    })> items,
  }) {
    int duplicates = 0;
    for (final it in items) {
      final dup = findPossibleDuplicate(
        accountId: accountId,
        date: it.date,
        amount: it.amount,
        description: it.description,
        externalRef: it.externalRef,
      );
      if (dup != null) duplicates += 1;
    }
    return duplicates;
  }

  String _ensureDefaultCategoryId({required bool isIncome}) {
    final box = _hive.categoriesBox;
    final existing = box.values.where((c) => c.isDefault && c.isIncome == isIncome).toList();
    if (existing.isNotEmpty) return existing.first.id;

    final id = _uuid.v4();
    final category = Category(
      id: id,
      name: 'Uncategorized',
      icon: 'category',
      isIncome: isIncome,
      isDefault: true,
      colorIndex: 0,
    );
    box.put(id, category);
    return id;
  }

  Transaction? findPossibleDuplicate({
    required String accountId,
    required DateTime date,
    required double amount,
    required String description,
    String? externalRef,
  }) {
    final candidateKey = _buildDedupKey(
      accountId: accountId,
      date: date,
      amount: amount,
      description: description,
      externalRef: externalRef,
    );
    for (final t in _transactions) {
      if (t.dedupKey != null && t.dedupKey == candidateKey) return t;
    }

    // Fallback match: same day + same amount (+ same externalRef when available)
    final dayKey = _dateKey(date);
    final refNorm = externalRef == null ? null : _normalize(externalRef);
    for (final t in _transactions) {
      if (t.accountId != accountId) continue;
      if ((t.amount - amount).abs() > 0.001) continue;
      if (_dateKey(t.date) != dayKey) continue;
      if (refNorm != null) {
        final tRefNorm = t.externalRef == null ? null : _normalize(t.externalRef!);
        if (tRefNorm != null && tRefNorm == refNorm) return t;
      } else {
        return t;
      }
    }
    return null;
  }

  Future<Transaction?> addManualTransaction({
    required bool isIncome,
    required double amount,
    required String description,
    required DateTime date,
    String? note,
    required bool allowDuplicate,
    required String accountId,
    String? categoryId,
  }) async {
    final finalCategoryId = categoryId ?? _ensureDefaultCategoryId(isIncome: isIncome);

    final duplicate = findPossibleDuplicate(
      accountId: accountId,
      date: date,
      amount: amount,
      description: description,
      externalRef: null,
    );
    if (duplicate != null && !allowDuplicate) return duplicate;

    final id = _uuid.v4();
    final dedupKey = _buildDedupKey(
      accountId: accountId,
      date: date,
      amount: amount,
      description: description,
      externalRef: null,
    );

    final txn = Transaction(
      id: id,
      amount: amount,
      description: description,
      date: date,
      categoryId: finalCategoryId,
      accountId: accountId,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      note: note,
      createdAt: DateTime.now(),
      externalRef: null,
      dedupKey: dedupKey,
      source: TransactionSource.manual,
    );

    await _hive.transactionsBox.put(id, txn);
    _refreshFromHive();
    return null;
  }

  Future<ImportResult> importTransactions({
    required List<({
      DateTime date,
      double amount,
      TransactionType type,
      String description,
      String? externalRef,
      bool isSelfTransfer,
    })> items,
    required TransactionSource source,
    required bool importDuplicates,
    required String accountId,
  }) async {
    int imported = 0;
    int skipped = 0;
    int duplicatesDetected = 0;

    // Use a stable snapshot of existing transactions for matching.
    final existing = _hive.transactionsBox.values.toList(growable: false);

    for (var idx = 0; idx < items.length; idx++) {
      final item = items[idx];
      final isIncome = item.type == TransactionType.income;
      final categoryId = _ensureDefaultCategoryId(isIncome: isIncome);

      final match = _findExistingSelfTransferMatch(
        importingAccountId: accountId,
        item: item,
        existing: existing,
      );
      // Only mark as self-transfer when we can confirm it exists across accounts.
      final isSelfTransfer = match != null;

      final dedupKey = _buildDedupKey(
        accountId: accountId,
        date: item.date,
        amount: item.amount,
        description: item.description,
        externalRef: item.externalRef,
      );

      final duplicate = findPossibleDuplicate(
        accountId: accountId,
        date: item.date,
        amount: item.amount,
        description: item.description,
        externalRef: item.externalRef,
      );

      final isDup = duplicate != null;
      if (isDup) duplicatesDetected += 1;

      if (isDup && !importDuplicates) {
        skipped += 1;
        continue;
      }

      final id = _uuid.v4();
      final txn = Transaction(
        id: id,
        amount: item.amount,
        description: item.description,
        date: item.date,
        categoryId: categoryId,
        accountId: accountId,
        type: item.type,
        note: null,
        createdAt: DateTime.now(),
        externalRef: item.externalRef,
        dedupKey: dedupKey,
        source: source,
        isSelfTransfer: isSelfTransfer,
        importSequence: idx, // Preserve PDF table row order
      );
      await _hive.transactionsBox.put(id, txn);

      if (match != null && match.isSelfTransfer != true) {
        await _hive.transactionsBox.put(match.id, _copyWithIsSelfTransfer(match, true));
      }
      imported += 1;
    }

    _refreshFromHive();
    return ImportResult(
      total: items.length,
      imported: imported,
      skippedDuplicates: skipped,
      duplicatesDetected: duplicatesDetected,
    );
  }

  Future<void> updateTransaction({
    required String id,
    required double amount,
    required String description,
    required DateTime date,
    required bool isIncome,
    required String accountId,
    String? note,
    String? categoryId,
  }) async {
    final existing = _hive.transactionsBox.get(id);
    if (existing == null) return;

    final finalCategoryId = categoryId ?? _ensureDefaultCategoryId(isIncome: isIncome);
    final dedupKey = _buildDedupKey(
      accountId: accountId,
      date: date,
      amount: amount,
      description: description,
      externalRef: existing.externalRef,
    );

    final updated = Transaction(
      id: id,
      amount: amount,
      description: description,
      date: date,
      categoryId: finalCategoryId,
      accountId: accountId,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      note: note,
      createdAt: existing.createdAt,
      externalRef: existing.externalRef,
      dedupKey: dedupKey,
      source: existing.source,
      isSelfTransfer: existing.isSelfTransfer,
      importSequence: existing.importSequence,
    );

    await _hive.transactionsBox.put(id, updated);
    _refreshFromHive();
  }

  Future<void> deleteTransaction(String id) async {
    await _hive.transactionsBox.delete(id);
    _refreshFromHive();
  }
}
