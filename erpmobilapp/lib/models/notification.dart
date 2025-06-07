import 'package:hive/hive.dart';

part 'notification.g.dart';

@HiveType(typeId: 8)
enum NotificationType {
  @HiveField(0)
  orderStatus,
  @HiveField(1)
  inventoryChange,
  @HiveField(2)
  message,
  @HiveField(3)
  loginSuccess,
  @HiveField(4)
  productCompleted,
  @HiveField(5)
  customerAdded,
  @HiveField(6)
  employeeAdded,
  @HiveField(7)
  paymentReceived,
  @HiveField(8)
  lowStock,
  @HiveField(9)
  orderCompleted,
  @HiveField(10)
  taskAssigned,
  @HiveField(11)
  systemUpdate,
}

@HiveType(typeId: 9)
class Notification extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final NotificationType type;

  @HiveField(2)
  final String message;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  bool isRead;

  @HiveField(5)
  final String? entityId;

  @HiveField(6)
  final String? userId;

  Notification({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.entityId,
    this.userId,
  });
}

