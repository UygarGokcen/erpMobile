import 'package:erpmobilapp/models/employee.dart';

/// Çalışan yönetimi için servis sınıfı
/// Bu sınıf, uygulama genelinde çalışan verilerine erişim sağlar
class EmployeeService {
  // Singleton örneği için
  static final EmployeeService _instance = EmployeeService._internal();

  // Tüm uygulama için ortak bir çalışan listesi
  static final List<Employee> _employees = [];

  // Singleton factory constructor
  factory EmployeeService() {
    return _instance;
  }

  // Private constructor
  EmployeeService._internal();

  // Çalışanları getir
  static Future<List<Employee>> getEmployees() async {
    // Gerçek bir uygulamada, burada bir API çağrısı olacaktır
    // Simülasyon için küçük bir gecikme ekleyelim
    await Future.delayed(Duration(milliseconds: 200));
    return _employees;
  }

  // Yeni bir çalışan ekle
  static void addEmployee(Employee employee) {
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index >= 0) {
      _employees[index] = employee; // Güncelle
    } else {
      _employees.add(employee); // Yeni ekle
    }
  }

  // Çalışan bilgilerini güncelle
  static void updateEmployee(Employee employee) {
    final index = _employees.indexWhere((e) => e.id == employee.id);
    if (index >= 0) {
      _employees[index] = employee;
    }
  }

  // Çalışanı kaldır
  static void removeEmployee(int employeeId) {
    _employees.removeWhere((employee) => employee.id == employeeId);
  }

  // Çalışanı ID'ye göre bul
  static Employee? getEmployeeById(int employeeId) {
    try {
      return _employees.firstWhere((employee) => employee.id == employeeId);
    } catch (e) {
      return null;
    }
  }
} 