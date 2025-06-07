import 'package:hive/hive.dart';

part 'order_status.g.dart';

@HiveType(typeId: 3)
enum OrderStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  processing,
  @HiveField(2)
  completed,
  @HiveField(3)
  cancelled
}

