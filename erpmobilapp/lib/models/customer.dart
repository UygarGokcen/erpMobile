import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 7)
class Customer extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String location;

  @HiveField(3)
  String phoneNumber;

  @HiveField(4)
  List<int> orderIds;
  
  @HiveField(5)
  String notes;
  
  @HiveField(6)
  Map<String, String> extraFields;

  Customer({
    required this.id,
    this.name = '',
    this.location = '',
    this.phoneNumber = '',
    this.orderIds = const [],
    this.notes = '',
    this.extraFields = const {},
  });
}

