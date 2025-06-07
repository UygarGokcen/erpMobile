import 'package:erpmobilapp/models/notification.dart' as NotificationModel;
import 'package:erpmobilapp/services/database_service.dart';

class NotificationService {
  static int _nextId = 1;

  static Future<void> createLoginNotification(String userId, String userName) async {
    final notification = NotificationModel.Notification(
      id: _nextId++,
      type: NotificationModel.NotificationType.loginSuccess,
      message: 'Hoş geldiniz $userName! Sisteme başarıyla giriş yaptınız.',
      timestamp: DateTime.now(),
      userId: userId,
    );
    
    await DatabaseService.addNotification(notification);
  }

  static Future<void> createProductCompletedNotification(String productName, String userId) async {
    final notification = NotificationModel.Notification(
      id: _nextId++,
      type: NotificationModel.NotificationType.productCompleted,
      message: '$productName ürünü başarıyla tamamlandı ve stokta mevcut.',
      timestamp: DateTime.now(),
      userId: userId,
    );
    
    await DatabaseService.addNotification(notification);
  }

  static Future<void> createCustomerAddedNotification(String customerName, String userId) async {
    final notification = NotificationModel.Notification(
      id: _nextId++,
      type: NotificationModel.NotificationType.customerAdded,
      message: 'Yeni müşteri eklendi: $customerName',
      timestamp: DateTime.now(),
      userId: userId,
    );
    
    await DatabaseService.addNotification(notification);
  }

  static Future<void> createEmployeeAddedNotification(String employeeName, String userId) async {
    final notification = NotificationModel.Notification(
      id: _nextId++,
      type: NotificationModel.NotificationType.employeeAdded,
      message: 'Yeni çalışan eklendi: $employeeName',
      timestamp: DateTime.now(),
      userId: userId,
    );
    
    await DatabaseService.addNotification(notification);
  }

  static Future<void> createPaymentReceivedNotification(double amount, String customerName, String userId) async {
    final notification = NotificationModel.Notification(
      id: _nextId++,
      type: NotificationModel.NotificationType.paymentReceived,
      message: '$customerName müşterisinden ₺${amount.toStringAsFixed(2)} ödeme alındı.',
      timestamp: DateTime.now(),
      userId: userId,
    );
    
    await DatabaseService.addNotification(notification);
  }

  static Future<void> createLowStockNotification(String productName, int quantity, String userId) async {
    final notification = NotificationModel.Notification(
      id: _nextId++,
      type: NotificationModel.NotificationType.lowStock,
      message: 'Kritik stok seviyesi: $productName (Kalan: $quantity adet)',
      timestamp: DateTime.now(),
      userId: userId,
    );
    
    await DatabaseService.addNotification(notification);
  }

  static Future<void> createOrderCompletedNotification(String orderId, String customerName, String userId) async {
    final notification = NotificationModel.Notification(
      id: _nextId++,
      type: NotificationModel.NotificationType.orderCompleted,
      message: 'Sipariş #$orderId ($customerName) başarıyla tamamlandı.',
      timestamp: DateTime.now(),
      userId: userId,
      entityId: orderId,
    );
    
    await DatabaseService.addNotification(notification);
  }

  static Future<void> createOrderStatusNotification(String orderId, String status, String customerName, String userId) async {
    final notification = NotificationModel.Notification(
      id: _nextId++,
      type: NotificationModel.NotificationType.orderStatus,
      message: 'Sipariş #$orderId durumu güncellendi: $status ($customerName)',
      timestamp: DateTime.now(),
      userId: userId,
      entityId: orderId,
    );
    
    await DatabaseService.addNotification(notification);
  }

  static Future<void> createInventoryChangeNotification(String productName, String changeType, int quantity, String userId) async {
    final notification = NotificationModel.Notification(
      id: _nextId++,
      type: NotificationModel.NotificationType.inventoryChange,
      message: 'Envanter değişikliği: $productName - $changeType ($quantity adet)',
      timestamp: DateTime.now(),
      userId: userId,
    );
    
    await DatabaseService.addNotification(notification);
  }

  static Future<void> createTaskAssignedNotification(String taskName, String assignedTo, String userId) async {
    final notification = NotificationModel.Notification(
      id: _nextId++,
      type: NotificationModel.NotificationType.taskAssigned,
      message: 'Yeni görev atandı: $taskName ($assignedTo\'a atandı)',
      timestamp: DateTime.now(),
      userId: userId,
    );
    
    await DatabaseService.addNotification(notification);
  }

  static Future<void> createSystemUpdateNotification(String updateInfo, String userId) async {
    final notification = NotificationModel.Notification(
      id: _nextId++,
      type: NotificationModel.NotificationType.systemUpdate,
      message: 'Sistem güncellemesi: $updateInfo',
      timestamp: DateTime.now(),
      userId: userId,
    );
    
    await DatabaseService.addNotification(notification);
  }

  static Future<void> createMessageNotification(String fromUser, String message, String userId) async {
    final notification = NotificationModel.Notification(
      id: _nextId++,
      type: NotificationModel.NotificationType.message,
      message: '$fromUser\'dan yeni mesaj: ${message.length > 50 ? message.substring(0, 50) + "..." : message}',
      timestamp: DateTime.now(),
      userId: userId,
    );
    
    await DatabaseService.addNotification(notification);
  }

  static Future<void> initializeWithSampleData() async {
    // Gerçek verilerle örnek bildirimler oluştur
    await createLoginNotification('1', 'Admin User');
    await Future.delayed(Duration(seconds: 1));
    
    await createProductCompletedNotification('Laptop Computer', '1');
    await Future.delayed(Duration(seconds: 1));
    
    await createCustomerAddedNotification('Acme Corporation', '1');
    await Future.delayed(Duration(seconds: 1));
    
    await createPaymentReceivedNotification(15000.0, 'Tech Solutions Ltd.', '1');
    await Future.delayed(Duration(seconds: 1));
    
    await createLowStockNotification('Office Chair', 3, '1');
    await Future.delayed(Duration(seconds: 1));
    
    await createOrderCompletedNotification('ORD-001', 'Global Industries', '1');
    await Future.delayed(Duration(seconds: 1));
    
    await createInventoryChangeNotification('Smartphone', 'Stok Eklendi', 25, '1');
    await Future.delayed(Duration(seconds: 1));
    
    await createTaskAssignedNotification('Müşteri Raporu Hazırlama', 'John Smith', '1');
    await Future.delayed(Duration(seconds: 1));
    
    await createSystemUpdateNotification('Yeni özellikler ve hata düzeltmeleri eklendi.', '1');
    await Future.delayed(Duration(seconds: 1));
    
    await createMessageNotification('Jane Doe', 'Toplantı saati değişti, lütfen takviminizi kontrol edin.', '1');
  }
} 