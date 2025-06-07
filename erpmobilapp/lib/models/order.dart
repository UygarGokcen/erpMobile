import 'package:hive/hive.dart';
import 'package:erpmobilapp/models/inventory_item.dart';
import 'package:erpmobilapp/models/customer.dart';
import 'package:erpmobilapp/models/order_status.dart';
import 'package:erpmobilapp/models/cargo_information.dart';

part 'order.g.dart';

@HiveType(typeId: 4)
class OrderItem {
  @HiveField(0)
  final InventoryItem item;

  @HiveField(1)
  final int quantity;

  OrderItem({required this.item, required this.quantity});
}

@HiveType(typeId: 6)
class Order extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  Customer customer;

  @HiveField(2)
  double totalAmount;

  @HiveField(3)
  OrderStatus status;

  @HiveField(4)
  List<OrderItem> items;

  @HiveField(5)
  CargoInformation cargoInfo;

  @HiveField(6)
  bool isErased;

  Order({
    required this.id,
    required this.customer,
    this.totalAmount = 0.0,
    this.status = OrderStatus.pending,
    List<OrderItem>? items,
    CargoInformation? cargoInfo,
    this.isErased = false,
  }) : 
      this.items = items ?? [],
      this.cargoInfo = cargoInfo ?? CargoInformation();
}

