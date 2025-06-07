// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogEntryAdapter extends TypeAdapter<LogEntry> {
  @override
  final int typeId = 9;

  @override
  LogEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LogEntry(
      id: fields[0] as int,
      timestamp: fields[1] as DateTime,
      userId: fields[2] as String,
      userName: fields[3] as String,
      action: fields[4] as LogAction,
      entityType: fields[5] as LogEntityType,
      entityId: fields[6] as String,
      description: fields[7] as String,
      changes: (fields[8] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, LogEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.userName)
      ..writeByte(4)
      ..write(obj.action)
      ..writeByte(5)
      ..write(obj.entityType)
      ..writeByte(6)
      ..write(obj.entityId)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.changes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LogActionAdapter extends TypeAdapter<LogAction> {
  @override
  final int typeId = 7;

  @override
  LogAction read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LogAction.create;
      case 1:
        return LogAction.update;
      case 2:
        return LogAction.delete;
      case 3:
        return LogAction.login;
      case 4:
        return LogAction.logout;
      default:
        return LogAction.create;
    }
  }

  @override
  void write(BinaryWriter writer, LogAction obj) {
    switch (obj) {
      case LogAction.create:
        writer.writeByte(0);
        break;
      case LogAction.update:
        writer.writeByte(1);
        break;
      case LogAction.delete:
        writer.writeByte(2);
        break;
      case LogAction.login:
        writer.writeByte(3);
        break;
      case LogAction.logout:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LogEntityTypeAdapter extends TypeAdapter<LogEntityType> {
  @override
  final int typeId = 8;

  @override
  LogEntityType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LogEntityType.inventory;
      case 1:
        return LogEntityType.order;
      case 2:
        return LogEntityType.customer;
      case 3:
        return LogEntityType.employee;
      case 4:
        return LogEntityType.user;
      default:
        return LogEntityType.inventory;
    }
  }

  @override
  void write(BinaryWriter writer, LogEntityType obj) {
    switch (obj) {
      case LogEntityType.inventory:
        writer.writeByte(0);
        break;
      case LogEntityType.order:
        writer.writeByte(1);
        break;
      case LogEntityType.customer:
        writer.writeByte(2);
        break;
      case LogEntityType.employee:
        writer.writeByte(3);
        break;
      case LogEntityType.user:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEntityTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
