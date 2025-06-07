// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cargo_information.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CargoInformationAdapter extends TypeAdapter<CargoInformation> {
  @override
  final int typeId = 5;

  @override
  CargoInformation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CargoInformation(
      currentLocation: fields[0] as String,
      transportationStages: (fields[1] as List).cast<String>(),
      currentStage: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CargoInformation obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.currentLocation)
      ..writeByte(1)
      ..write(obj.transportationStages)
      ..writeByte(2)
      ..write(obj.currentStage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CargoInformationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
