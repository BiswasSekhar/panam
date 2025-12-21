import 'package:intl/intl.dart';

import '../../data/models/transaction.dart';
import 'models.dart';

class SBIStatementParser {
  static final _bankNameRegex = RegExp(r'\bSBI\b|State Bank of India', caseSensitive: false);

  static final _dateDf = DateFormat('d MMM yyyy');
  static final _monthToken = r'(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)';
  static final _dateToken = '([0-9]{1,2}\\s+$_monthToken\\s+[0-9]{4})';
  static final _moneyToken = r'([0-9]+(?:,[0-9]{3})*\.[0-9]{2})';

  // Robust approach: locate each row start (`TxnDate ValueDate ...`) and slice until the next row.
  static final _rowStartRegex = RegExp(
    '$_dateToken\\s+$_dateToken\\s+',
    caseSensitive: false,
  );

  static final _moneyRegex = RegExp(_moneyToken);

  static final _upiRefRegex = RegExp(r'\bUPI\/(DR|CR)\/([0-9]{8,})\b', caseSensitive: false);
  static final _upiNameRegex = RegExp(r'\bUPI\/(?:DR|CR)\/[0-9]{8,}\/([^\/]+)', caseSensitive: false);

  static final _accountNameRegex = RegExp(r'Account\s+Name\s*:\s*([^\n\r]+)', caseSensitive: false);
  static final _accountNumberRegex = RegExp(r'Account\s+Number\s*:\s*([0-9]{10,18})', caseSensitive: false);

  static final _headerNoiseRegex = RegExp(
    r'Txn\s+Date\s+Value\s+Date\s+Description\s+Ref\s+No\./Cheque\s+No\.?\s+Debit\s+Credit\s+Balance',
    caseSensitive: false,
  );

  static final _modePatterns = <String, RegExp>{
    'UPI': RegExp(r'\bUPI\b', caseSensitive: false),
    'ATM': RegExp(r'\bATM\b', caseSensitive: false),
    'NEFT': RegExp(r'\bNEFT\b', caseSensitive: false),
    'IMPS': RegExp(r'\bIMPS\b', caseSensitive: false),
    'RTGS': RegExp(r'\bRTGS\b', caseSensitive: false),
    'POS': RegExp(r'\bPOS\b', caseSensitive: false),
  };

  static final _selfTransferRegex = RegExp(r'\bself\b', caseSensitive: false);
  static final _bankCodeRegex = RegExp(r'\b(KKBK|SBIN|HDFC|ICIC|UTIB|YESB|FDRL|SIBL|CNRB)\b', caseSensitive: false);

  static ParsedStatement parse(String text) {
    final bankName = _bankNameRegex.hasMatch(text) ? 'SBI' : null;

    final accountName = _extractAccountName(text);
    _extractAccountNumber(text);

    final normalized = _normalizeStatementText(text);
    final results = <ParsedTransaction>[];

    final starts = _rowStartRegex.allMatches(normalized).toList(growable: false);
    for (int idx = 0; idx < starts.length; idx++) {
      final match = starts[idx];
      final nextStart = (idx + 1) < starts.length ? starts[idx + 1].start : normalized.length;

      final txnDateRaw = match.group(1);
      final valueDateRaw = match.group(2);
      if (txnDateRaw == null || valueDateRaw == null) continue;

      final rowBody = normalized.substring(match.end, nextStart).trim();
      if (rowBody.isEmpty) continue;

      final moneyMatches = _moneyRegex.allMatches(rowBody).toList(growable: false);
      if (moneyMatches.length < 2) continue;

      final balanceRaw = moneyMatches.last.group(1);
      if (balanceRaw == null) continue;

      DateTime txnDate;
      try {
        txnDate = _dateDf.parse(txnDateRaw);
      } catch (_) {
        continue;
      }

      final balance = double.tryParse(balanceRaw.replaceAll(',', ''));

      // Amount candidates are the one or two numbers right before balance.
      final amountCandidates = <double>[];
      final prev1 = moneyMatches[moneyMatches.length - 2].group(1);
      if (prev1 != null) {
        final v = double.tryParse(prev1.replaceAll(',', ''));
        if (v != null) amountCandidates.add(v);
      }
      if (moneyMatches.length >= 3) {
        final prev2 = moneyMatches[moneyMatches.length - 3].group(1);
        if (prev2 != null) {
          final v = double.tryParse(prev2.replaceAll(',', ''));
          if (v != null) amountCandidates.add(v);
        }
      }
      if (amountCandidates.isEmpty) continue;

      double? amount;
      for (final candidate in amountCandidates.reversed) {
        if (candidate.abs() > 0.0001) {
          amount = candidate;
          break;
        }
      }
      amount ??= amountCandidates.first;
      if (amount <= 0) continue;

      // Description is everything before the first trailing amount token.
      final earliestTailMatch = moneyMatches.length >= 3 ? moneyMatches[moneyMatches.length - 3] : moneyMatches[moneyMatches.length - 2];
      final descriptionRaw = rowBody.substring(0, earliestTailMatch.start).trim();
      final joined = _cleanupDescription(descriptionRaw);

      // Mode
      String? mode;
      for (final entry in _modePatterns.entries) {
        if (entry.value.hasMatch(joined)) {
          mode = entry.key;
          break;
        }
      }

      // Income/Expense
      final lower = joined.toLowerCase();
      final isIncome = lower.contains('by transfer') || lower.contains('/cr/') || lower.contains('credit');
      final isExpense = lower.contains('to transfer') || lower.contains('/dr/') || lower.contains('debit');
      final type = isIncome && !isExpense ? TransactionType.income : TransactionType.expense;

      // External ref
      String? externalRef;
      final upiRefMatch = _upiRefRegex.firstMatch(joined);
      if (upiRefMatch != null) {
        externalRef = 'UPI/${upiRefMatch.group(1)}/${upiRefMatch.group(2)}';
      }

      // Counterparty name
      String? counterpartyName;
      if (mode == 'UPI') {
        final nameMatch = _upiNameRegex.firstMatch(joined);
        if (nameMatch != null) {
          final candidate = nameMatch.group(1)?.trim();
          if (candidate != null && candidate.isNotEmpty && candidate.length > 2) {
            counterpartyName = candidate;
          }
        }
      } else if (mode == 'NEFT') {
        final parts = joined.split('*');
        if (parts.length >= 4) {
          final candidate = parts.last.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').trim();
          if (candidate.isNotEmpty) counterpartyName = candidate;
        }
      }

      // Self-transfer detection
      final normalizedHolder = _normalizeName(accountName);
      final normalizedCounterparty = _normalizeName(counterpartyName);
      final looksLikeSelfByKeyword = _selfTransferRegex.hasMatch(joined);
      final looksLikeSelfByName =
          normalizedHolder.isNotEmpty && normalizedCounterparty.isNotEmpty && normalizedHolder == normalizedCounterparty;
      final looksLikeSelfByBankCode = _bankCodeRegex.hasMatch(joined);

      final isSelfTransfer = looksLikeSelfByKeyword && (looksLikeSelfByBankCode || looksLikeSelfByName);

      // Description shown to user
      var description = counterpartyName ?? joined;
      description = description.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (description.isEmpty) description = mode != null ? '$mode Transaction' : 'Transaction';
      if (isSelfTransfer && !description.toLowerCase().contains('self')) {
        description = '$description (Self Transfer)';
      }

      results.add(
        ParsedTransaction(
          date: DateTime(txnDate.year, txnDate.month, txnDate.day, 12, 0),
          amount: amount,
          type: type,
          description: description,
          externalRef: externalRef,
          mode: mode,
          balance: balance,
          isSelfTransfer: isSelfTransfer,
          counterpartyAccount: null,
          counterpartyName: counterpartyName,
        ),
      );
    }

    // Don't sort - preserve PDF table order as much as possible
    // results.sort((a, b) => a.date.compareTo(b.date));

    double? openingBalance;
    if (results.isNotEmpty) {
      final first = results.first;
      if (first.balance != null) {
        openingBalance = first.type == TransactionType.income
            ? first.balance! - first.amount
            : first.balance! + first.amount;
      }
    }

    return ParsedStatement(
      bankName: bankName,
      transactions: results,
      openingBalance: openingBalance,
    );
  }

  static String _normalizeStatementText(String text) {
    return text
        .replaceAll('\u0000', ' ')
        .replaceAll('�', ' ')
        .replaceAll(RegExp(r'[\u0000-\u001F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _cleanupDescription(String raw) {
    var s = raw;
    s = s.replaceAll(_headerNoiseRegex, ' ');
    s = s.replaceAll(RegExp(r'\bRef\s+No\./Cheque\s+No\.?\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\bDebit\b|\bCredit\b|\bBalance\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static String _extractAccountName(String text) {
    final match = _accountNameRegex.firstMatch(text);
    if (match == null) return '';
    var name = match.group(1)?.trim() ?? '';
    name = name.replaceAll(RegExp(r'^Mr\.?\s+', caseSensitive: false), '').trim();
    return name;
  }

  static String? _extractAccountNumber(String text) {
    final match = _accountNumberRegex.firstMatch(text);
    return match?.group(1);
  }

  static String _normalizeName(String? name) {
    if (name == null) return '';
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
