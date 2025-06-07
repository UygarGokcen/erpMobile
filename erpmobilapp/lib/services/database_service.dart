import 'package:hive_flutter/hive_flutter.dart';
import 'package:erpmobilapp/models/employee.dart';
import 'package:erpmobilapp/models/inventory_item.dart';
import 'package:erpmobilapp/models/order.dart';
import 'package:erpmobilapp/models/customer.dart';
import 'package:erpmobilapp/models/notification.dart';
import 'package:erpmobilapp/models/user_role.dart';
import 'package:erpmobilapp/models/cargo_information.dart';
import 'package:erpmobilapp/models/order_status.dart';

class DatabaseService {
  static const String employeesBox = 'employees';
  static const String inventoryBox = 'inventory';
  static const String ordersBox = 'orders';
  static const String customersBox = 'customers';
  static const String notificationsBox = 'notifications';

  static Future<void> initDatabase() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserRoleAdapter());
    Hive.registerAdapter(EmployeeAdapter());
    Hive.registerAdapter(InventoryItemAdapter());
    Hive.registerAdapter(OrderStatusAdapter());
    Hive.registerAdapter(OrderItemAdapter());
    Hive.registerAdapter(CargoInformationAdapter());
    Hive.registerAdapter(OrderAdapter());
    Hive.registerAdapter(CustomerAdapter());
    Hive.registerAdapter(NotificationAdapter());
    await Hive.openBox<Employee>(employeesBox);
    await Hive.openBox<InventoryItem>(inventoryBox);
    await Hive.openBox<Order>(ordersBox);
    await Hive.openBox<Customer>(customersBox);
    await Hive.openBox<Notification>(notificationsBox);
  }

  static Future<void> addEmployee(Employee employee) async {
    final box = Hive.box<Employee>(employeesBox);
    await box.add(employee);
  }

  static List<Employee> getAllEmployees() {
    final box = Hive.box<Employee>(employeesBox);
    return box.values.toList();
  }

  static Future<void> updateEmployee(int index, Employee employee) async {
    final box = Hive.box<Employee>(employeesBox);
    await box.putAt(index, employee);
  }

  static Future<void> deleteEmployee(int index) async {
    final box = Hive.box<Employee>(employeesBox);
    await box.deleteAt(index);
  }

  static Future<Employee?> login(String email, String password) async {
    final box = Hive.box<Employee>(employeesBox);
    try {
      return box.values.firstWhere(
        (e) => e.email == email && e.password == password,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> addInventoryItem(InventoryItem item) async {
    final box = Hive.box<InventoryItem>(inventoryBox);
    await box.add(item);
  }

  static List<InventoryItem> getAllInventoryItems() {
    final box = Hive.box<InventoryItem>(inventoryBox);
    return box.values.toList();
  }

  static Future<void> updateInventoryItem(int index, InventoryItem item) async {
    final box = Hive.box<InventoryItem>(inventoryBox);
    await box.putAt(index, item);
  }

  static Future<void> deleteInventoryItem(int index) async {
    final box = Hive.box<InventoryItem>(inventoryBox);
    await box.deleteAt(index);
  }

  static Future<void> addOrder(Order order) async {
    final box = Hive.box<Order>(ordersBox);
    await box.add(order);
  }

  static List<Order> getAllOrders() {
    final box = Hive.box<Order>(ordersBox);
    return box.values.toList();
  }

  static Future<void> updateOrder(int index, Order order) async {
    final box = Hive.box<Order>(ordersBox);
    await box.putAt(index, order);
  }

  static Future<void> deleteOrder(int index) async {
    final box = Hive.box<Order>(ordersBox);
    await box.deleteAt(index);
  }

  static Future<void> addCustomer(Customer customer) async {
    final box = Hive.box<Customer>(customersBox);
    await box.add(customer);
  }

  static List<Customer> getAllCustomers() {
    final box = Hive.box<Customer>(customersBox);
    return box.values.toList();
  }

  static Future<void> updateCustomer(int index, Customer customer) async {
    final box = Hive.box<Customer>(customersBox);
    await box.putAt(index, customer);
  }

  static Future<void> deleteCustomer(int index) async {
    final box = Hive.box<Customer>(customersBox);
    await box.deleteAt(index);
  }

  static Future<void> addNotification(Notification notification) async {
    final box = Hive.box<Notification>(notificationsBox);
    await box.add(notification);
  }

  static List<Notification> getAllNotifications() {
    final box = Hive.box<Notification>(notificationsBox);
    return box.values.toList();
  }

  static Future<void> deleteNotification(int index) async {
    final box = Hive.box<Notification>(notificationsBox);
    await box.deleteAt(index);
  }
}

