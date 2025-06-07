import 'package:hive/hive.dart';
import 'package:erpmobilapp/models/user_role.dart';

part 'employee.g.dart';

@HiveType(typeId: 1)
class Employee extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String department;

  @HiveField(3)
  String position;

  @HiveField(4)
  double salary;

  @HiveField(5)
  UserRole role;

  @HiveField(6)
  String email;

  @HiveField(7)
  String password;
  
  @HiveField(8)
  String notes;
  
  @HiveField(9)
  Map<String, String> extraFields;
  
  @HiveField(10)
  DateTime? startDate;

  Employee({
    required this.id,
    this.name = '',
    this.department = '',
    this.position = '',
    this.salary = 0.0,
    this.role = UserRole.employee,
    required this.email,
    required this.password,
    this.notes = '',
    this.extraFields = const {},
    this.startDate,
  });
}

