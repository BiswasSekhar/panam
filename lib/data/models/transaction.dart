import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 5)
enum TransactionSource {
  @HiveField(0)
  manual,
  @HiveField(1)
  importPdfText,
  @HiveField(2)
  importOcrImage,
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

  // Optional import metadata (added later; keep nullable for backward compatibility)
  @HiveField(9)
  final String? externalRef;

  @HiveField(10)
  final String? dedupKey;

  @HiveField(11)
  final TransactionSource source;

  // Optional flags (added later; keep nullable for backward compatibility)
  @HiveField(12)
  final bool? isSelfTransfer;

  @HiveField(13)
  final int? importSequence; // Preserves PDF table row order for same-date transactions

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
    this.externalRef,
    this.dedupKey,
    this.source = TransactionSource.manual,
    this.isSelfTransfer,
    this.importSequence,
  });
}
