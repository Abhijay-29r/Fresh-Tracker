import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
class FoodItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  DateTime expiryDate;

  @HiveField(2)
  String category;

  @HiveField(3)
  String? imageUrl;

  @HiveField(4)
  double quantity;

  @HiveField(5)
  String unit;

  @HiveField(6)
  String status; // 'active', 'eaten', or 'wasted'

  // Only ONE constructor allowed:
  FoodItem({
    required this.name,
    required this.expiryDate,
    this.category = 'Pantry',
    this.imageUrl,
    this.quantity = 1.0,
    this.unit = 'pcs',
    this.status = 'active', // This initializes it to 'active' by default
  });
}
