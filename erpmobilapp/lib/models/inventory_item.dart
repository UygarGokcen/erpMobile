import 'package:hive/hive.dart';

part 'inventory_item.g.dart';

@HiveType(typeId: 2)
class InventoryItem extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  double price;
  
  @HiveField(4)
  Map<String, String> extraFields;

  @HiveField(5)
  String? imagePath;

  InventoryItem({
    required this.id,
    this.name = '',
    this.quantity = 0,
    this.price = 0.0,
    this.extraFields = const {},
    this.imagePath,
  });
}

