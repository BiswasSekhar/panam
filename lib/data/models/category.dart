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
}
