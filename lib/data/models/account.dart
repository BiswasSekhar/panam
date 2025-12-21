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
}
