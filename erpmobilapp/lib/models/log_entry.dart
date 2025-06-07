import 'package:hive/hive.dart';

part 'log_entry.g.dart';

@HiveType(typeId: 7)
enum LogAction {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete,
  @HiveField(3)
  login,
  @HiveField(4)
  logout,
}

@HiveType(typeId: 8)
enum LogEntityType {
  @HiveField(0)
  inventory,
  @HiveField(1)
  order,
  @HiveField(2)
  customer,
  @HiveField(3)
  employee,
  @HiveField(4)
  user,
}

@HiveType(typeId: 9)
class LogEntry extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final String userName;

  @HiveField(4)
  final LogAction action;

  @HiveField(5)
  final LogEntityType entityType;

  @HiveField(6)
  final String entityId;

  @HiveField(7)
  final String description;

  @HiveField(8)
  final Map<String, String> changes;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.description,
    this.changes = const {},
  });
} 