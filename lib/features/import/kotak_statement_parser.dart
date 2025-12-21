import 'package:intl/intl.dart';

import '../../data/models/transaction.dart';
import 'models.dart';

class KotakStatementParser {
  static final _dateRegex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
  static final _amountRegex = RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})|[0-9]+(?:\.[0-9]{2}))\((Cr|Dr)\)');
  static final _balanceRegex = RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})|[0-9]+(?:\.[0-9]{2}))');
  static final _upiRefRegex = RegExp(r'\bUPI-([0-9]{8,})\b');
  static final _bankNameRegex = RegExp(r'(kotak|KOTAK|Kotak Mahindra)', caseSensitive: false);
  
  // Self-transfer detection patterns
  static final _selfTransferPatterns = [
    RegExp(r'\bSelf[-\s]?(?:transfer)?\b', caseSensitive: false),
    RegExp(r'/Self[-/\s]', caseSensitive: false),
  ];
  
  // Account number pattern (10-18 digits)
  static final _accountNumberRegex = RegExp(r'\b([0-9]{10,18})\b');
  
  // Bank code patterns
  static final _bankCodes = {
    'KKBK': 'Kotak',
    'SBIN': 'SBI', 
    'HDFC': 'HDFC',
    'ICIC': 'ICICI',
    'UTIB': 'Axis',
    'IDFB': 'IDFC',
    'YESB': 'Yes Bank',
    'FDRL': 'Federal',
    'SIBL': 'South Indian Bank',
    'CNRB': 'Canara',
  };
  
  // Extract transaction mode from narration
  static final _modePatterns = {
    'UPI': RegExp(r'\bUPI[/-]', caseSensitive: false),
    'ATM': RegExp(r'\bATM\b', caseSensitive: false),
    'NEFT': RegExp(r'\bNEFT\b', caseSensitive: false),
    'IMPS': RegExp(r'\bIMPS\b', caseSensitive: false),
    'RTGS': RegExp(r'\bRTGS\b', caseSensitive: false),
    'POS': RegExp(r'\bPOS\b', caseSensitive: false),
  };

  static ParsedStatement parse(String text) {
    // Try to detect bank name
    String? bankName;
    final bankMatch = _bankNameRegex.firstMatch(text);
    if (bankMatch != null) {
      bankName = 'Kotak';
    }

    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);

    final results = <ParsedTransaction>[];

    final df = DateFormat('dd-MM-yyyy');

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (!_dateRegex.hasMatch(line)) {
        i++;
        continue;
      }

      DateTime? date;
      try {
        date = df.parseStrict(line);
      } catch (_) {
        i++;
        continue;
      }

      // Collect block until next date line
      final block = <String>[];
      i++;
      while (i < lines.length && !_dateRegex.hasMatch(lines[i])) {
        block.add(lines[i]);
        i++;
      }

      final joined = block.join(' ');
      final amounts = _amountRegex.allMatches(joined).toList(growable: false);
      if (amounts.isEmpty) continue;

      // In Kotak tables, first amount occurrence is usually the transaction amount,
      // later one is the running balance.
      final first = amounts.first;
      final amtRaw = first.group(1) ?? '';
      final crdr = first.group(2) ?? '';

      final amount = double.tryParse(amtRaw.replaceAll(',', ''));
      if (amount == null) continue;

      final type = crdr == 'Cr' ? TransactionType.income : TransactionType.expense;

      // Extract balance (last amount in the line)
      double? balance;
      final allAmounts = _balanceRegex.allMatches(joined).toList();
      if (allAmounts.length >= 2) {
        balance = double.tryParse(allAmounts.last.group(0)!.replaceAll(',', ''));
      }

      final upiMatch = _upiRefRegex.firstMatch(joined);
      final upi = upiMatch?.group(0);
      final upiRefNumber = upiMatch?.group(1);

      // Detect transaction mode
      String? mode;
      for (final entry in _modePatterns.entries) {
        if (entry.value.hasMatch(joined)) {
          mode = entry.key;
          break;
        }
      }

      // Detect self-transfer
      bool isSelfTransfer = false;
      for (final pattern in _selfTransferPatterns) {
        if (pattern.hasMatch(joined)) {
          isSelfTransfer = true;
          break;
        }
      }

      // Extract counterparty account number
      String? counterpartyAccount;
      final accountMatches = _accountNumberRegex.allMatches(joined).toList();
      if (accountMatches.isNotEmpty) {
        for (final match in accountMatches) {
          final num = match.group(1)!;
          if (num != upiRefNumber && num.length >= 10) {
            counterpartyAccount = num;
            break;
          }
        }
      }

      // Extract counterparty name
      String? counterpartyName;
      var description = joined;
      description = description.replaceAll(_amountRegex, '');
      if (upi != null) description = description.replaceAll(upi, '');
      
      // For UPI transactions, extract payee name
      // Kotak pattern: UPI/NAME/refno/Self transfer or UPI/CR/refno/NAME/BANK/phone
      if (mode == 'UPI') {
        final parts = joined.split('/');
        for (int j = 0; j < parts.length; j++) {
          final part = parts[j].trim();
          // Skip common UPI prefixes and codes
          if (part.isEmpty ||
              part == 'UPI' ||
              part.startsWith('CR') ||
              part.startsWith('DR') ||
              part.startsWith('BY TRANSFER') ||
              part.startsWith('TO TRANSFER') ||
              RegExp(r'^[0-9]+$').hasMatch(part) ||
              _bankCodes.containsKey(part.toUpperCase()) ||
              part.toLowerCase() == 'self' ||
              part.toLowerCase().contains('self transfer') ||
              part.toLowerCase().contains('payme') ||
              part.length <= 2) {
            continue;
          }
          
          // Check if this is a name (contains letters, not just codes)
          if (RegExp(r'[a-zA-Z]{2,}').hasMatch(part)) {
            counterpartyName = part;
            description = part;
            break;
          }
        }
      }
      
      // Clean up description if no name found
      if (description == joined || counterpartyName == null) {
        description = description
            .replaceAll(RegExp(r'BY TRANSFER-?'), '')
            .replaceAll(RegExp(r'TO TRANSFER-?'), '')
            .replaceAll(RegExp(r'UPI[/-]'), '')
            .replaceAll(RegExp(r'/NO RE-?'), '')
            .replaceAll(RegExp(r'\b[0-9]{10,}\b'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        
        // Extract first meaningful word/name from remaining
        final words = description.split('/').where((w) => 
            w.trim().isNotEmpty && 
            w.trim().length > 2 &&
            !RegExp(r'^[0-9]+$').hasMatch(w.trim()) &&
            !_bankCodes.containsKey(w.trim().toUpperCase())
        ).toList();
        
        if (words.isNotEmpty) {
          description = words.first.trim();
          counterpartyName = description;
        }
      }
      
      if (description.isEmpty) {
        description = mode != null ? '$mode Transaction' : 'Imported transaction';
      }
      
      // Add self-transfer indicator to description if detected
      if (isSelfTransfer && !description.toLowerCase().contains('self')) {
        description = '$description (Self Transfer)';
      }

      results.add(ParsedTransaction(
        date: DateTime(date.year, date.month, date.day, 12, 0),
        amount: amount,
        type: type,
        description: description,
        externalRef: upi,
        mode: mode,
        balance: balance,
        isSelfTransfer: isSelfTransfer,
        counterpartyAccount: counterpartyAccount,
        counterpartyName: counterpartyName,
      ));
    }

    // Calculate opening balance from first transaction if available
    double? openingBalance;
    if (results.isNotEmpty) {
      final first = results.first;
      if (first.balance != null) {
        if (first.type == TransactionType.income) {
          openingBalance = first.balance! - first.amount;
        } else {
          openingBalance = first.balance! + first.amount;
        }
      }
    }

    return ParsedStatement(
      bankName: bankName,
      transactions: results,
      openingBalance: openingBalance,
    );
  }
}
