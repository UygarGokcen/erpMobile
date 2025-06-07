import 'package:erpmobilapp/models/customer.dart';

/// Müşteri yönetimi için servis sınıfı
/// Bu sınıf, uygulama genelinde müşteri verilerine erişim sağlar
class CustomerService {
  // Singleton örneği için
  static final CustomerService _instance = CustomerService._internal();

  // Tüm uygulama için ortak bir müşteri listesi
  static final List<Customer> _customers = [];

  // Singleton factory constructor
  factory CustomerService() {
    return _instance;
  }

  // Private constructor
  CustomerService._internal();

  // Müşterileri getir
  static List<Customer> getCustomers() {
    return _customers;
  }

  // Yeni bir müşteri ekle
  static void addCustomer(Customer customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      _customers[index] = customer; // Güncelle
    } else {
      _customers.add(customer); // Yeni ekle
    }
  }

  // Müşteri bilgilerini güncelle
  static void updateCustomer(Customer customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      _customers[index] = customer;
    }
  }

  // Müşteriyi kaldır
  static void removeCustomer(int customerId) {
    _customers.removeWhere((customer) => customer.id == customerId);
  }

  // Müşteriyi ID'ye göre bul
  static Customer? getCustomerById(int customerId) {
    try {
      return _customers.firstWhere((customer) => customer.id == customerId);
    } catch (e) {
      return null;
    }
  }
} 