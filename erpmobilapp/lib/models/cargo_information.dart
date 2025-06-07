import 'package:hive/hive.dart';

part 'cargo_information.g.dart';

@HiveType(typeId: 5)
class CargoInformation extends HiveObject {
  @HiveField(0)
  String currentLocation;

  @HiveField(1)
  List<String> transportationStages;

  @HiveField(2)
  int currentStage;

  CargoInformation({
    this.currentLocation = '',
    this.transportationStages = const [],
    this.currentStage = 0,
  });
}

