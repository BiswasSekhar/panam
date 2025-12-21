import '../../data/models/transaction.dart';

class ParsedTransaction {
  final DateTime date;
  final double amount;
  final TransactionType type;
  final String description;
  final String? externalRef;
  final String? mode; // UPI, ATM, NEFT, etc.
  final double? balance; // Balance after transaction
  final bool isSelfTransfer; // True if this is a transfer between user's own accounts
  final String? counterpartyAccount; // Account number of the other party (for self-transfer detection)
  final String? counterpartyName; // Name extracted from transaction

  const ParsedTransaction({
    required this.date,
    required this.amount,
    required this.type,
    required this.description,
    this.externalRef,
    this.mode,
    this.balance,
    this.isSelfTransfer = false,
    this.counterpartyAccount,
    this.counterpartyName,
  });
}

class ParsedStatement {
  final String? bankName;
  final List<ParsedTransaction> transactions;
  final double? openingBalance; // Calculated from first transaction

  const ParsedStatement({
    this.bankName,
    required this.transactions,
    this.openingBalance,
  });
}
