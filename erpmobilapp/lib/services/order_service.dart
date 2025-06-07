import 'package:erpmobilapp/models/order.dart';
import 'package:erpmobilapp/models/order_status.dart';

/// Sipariş yönetimi için servis sınıfı
/// Bu sınıf, uygulama genelinde sipariş verilerine erişim sağlar
class OrderService {
  // Singleton örneği için
  static final OrderService _instance = OrderService._internal();

  // Tüm uygulama için ortak bir sipariş listesi
  static final List<Order> _orders = [];

  // Singleton factory constructor
  factory OrderService() {
    return _instance;
  }

  // Private constructor
  OrderService._internal();

  // Tüm siparişleri getir
  static Future<List<Order>> getAllOrders() async {
    // Gerçek bir uygulamada, burada bir API çağrısı olacaktır
    // Simülasyon için küçük bir gecikme ekleyelim
    await Future.delayed(Duration(milliseconds: 250));
    return _orders;
  }

  // Aktif siparişleri getir (tamamlanmamış ve iptal edilmemiş)
  static List<Order> getActiveOrders() {
    return _orders.where((order) => 
      order.status == OrderStatus.pending || 
      order.status == OrderStatus.processing
    ).toList();
  }

  // Tamamlanmış veya iptal edilmiş siparişleri getir
  static Future<List<Order>> getPreviousOrders() async {
    // Gerçek bir uygulamada, burada bir API çağrısı olacaktır
    // Simülasyon için küçük bir gecikme ekleyelim
    await Future.delayed(Duration(milliseconds: 200));
    return _orders.where((order) => 
      order.status == OrderStatus.completed || 
      order.status == OrderStatus.cancelled
    ).toList();
  }

  // Yeni bir sipariş ekle
  static void addOrder(Order order) {
    // id değeri final olduğundan, mevcut order'ı değiştiremeyiz
    // id değeri zaten belirlenmiş olabilir, o yüzden kontrol edelim
    if (order.id == 0) {
      // Yeni bir sipariş nesnesi oluştur ve onu ekle
      final newId = _getNextOrderId();
      final newOrder = Order(
        id: newId,
        customer: order.customer,
        items: order.items,
        totalAmount: order.totalAmount,
        status: order.status,
      );
      _orders.add(newOrder);
    } else {
      // ID zaten var, güncelleme mi yeni ekleme mi kontrol et
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index >= 0) {
        _orders[index] = order; // Güncelle
      } else {
        _orders.add(order); // Yeni ekle
      }
    }
  }

  // Sipariş bilgilerini güncelle
  static void updateOrder(Order order) {
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      _orders[index] = order;
    }
  }

  // Siparişi kaldır
  static void removeOrder(int orderId) {
    _orders.removeWhere((order) => order.id == orderId);
  }

  // Siparişi ID'ye göre bul
  static Order? getOrderById(int orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  // Yeni sipariş ID'si oluştur
  static int _getNextOrderId() {
    if (_orders.isEmpty) {
      return 1;
    }
    return _orders.map((o) => o.id).reduce((a, b) => a > b ? a : b) + 1;
  }
} 