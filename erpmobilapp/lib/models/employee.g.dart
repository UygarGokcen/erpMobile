// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmployeeAdapter extends TypeAdapter<Employee> {
  @override
  final int typeId = 1;

  @override
  Employee read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Employee(
      id: fields[0] as int,
      name: fields[1] as String,
      department: fields[2] as String,
      position: fields[3] as String,
      salary: fields[4] as double,
      role: fields[5] as UserRole,
      email: fields[6] as String,
      password: fields[7] as String,
      notes: fields[8] as String,
      extraFields: (fields[9] as Map).cast<String, String>(),
      startDate: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Employee obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.department)
      ..writeByte(3)
      ..write(obj.position)
      ..writeByte(4)
      ..write(obj.salary)
      ..writeByte(5)
      ..write(obj.role)
      ..writeByte(6)
      ..write(obj.email)
      ..writeByte(7)
      ..write(obj.password)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.extraFields)
      ..writeByte(10)
      ..write(obj.startDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
