// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationAdapter extends TypeAdapter<Notification> {
  @override
  final int typeId = 9;

  @override
  Notification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Notification(
      id: fields[0] as int,
      type: fields[1] as NotificationType,
      message: fields[2] as String,
      timestamp: fields[3] as DateTime,
      isRead: fields[4] as bool,
      entityId: fields[5] as String?,
      userId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Notification obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.message)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.isRead)
      ..writeByte(5)
      ..write(obj.entityId)
      ..writeByte(6)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationTypeAdapter extends TypeAdapter<NotificationType> {
  @override
  final int typeId = 8;

  @override
  NotificationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationType.orderStatus;
      case 1:
        return NotificationType.inventoryChange;
      case 2:
        return NotificationType.message;
      case 3:
        return NotificationType.loginSuccess;
      case 4:
        return NotificationType.productCompleted;
      case 5:
        return NotificationType.customerAdded;
      case 6:
        return NotificationType.employeeAdded;
      case 7:
        return NotificationType.paymentReceived;
      case 8:
        return NotificationType.lowStock;
      case 9:
        return NotificationType.orderCompleted;
      case 10:
        return NotificationType.taskAssigned;
      case 11:
        return NotificationType.systemUpdate;
      default:
        return NotificationType.orderStatus;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationType obj) {
    switch (obj) {
      case NotificationType.orderStatus:
        writer.writeByte(0);
        break;
      case NotificationType.inventoryChange:
        writer.writeByte(1);
        break;
      case NotificationType.message:
        writer.writeByte(2);
        break;
      case NotificationType.loginSuccess:
        writer.writeByte(3);
        break;
      case NotificationType.productCompleted:
        writer.writeByte(4);
        break;
      case NotificationType.customerAdded:
        writer.writeByte(5);
        break;
      case NotificationType.employeeAdded:
        writer.writeByte(6);
        break;
      case NotificationType.paymentReceived:
        writer.writeByte(7);
        break;
      case NotificationType.lowStock:
        writer.writeByte(8);
        break;
      case NotificationType.orderCompleted:
        writer.writeByte(9);
        break;
      case NotificationType.taskAssigned:
        writer.writeByte(10);
        break;
      case NotificationType.systemUpdate:
        writer.writeByte(11);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
