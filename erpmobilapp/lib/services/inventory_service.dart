import 'package:erpmobilapp/models/inventory_item.dart';

/// Envanter yönetimi için servis sınıfı
/// Bu sınıf, uygulama genelinde envanter verilerine erişim sağlar
class InventoryService {
  // Singleton örneği için
  static final InventoryService _instance = InventoryService._internal();

  // Tüm uygulama için ortak bir envanter listesi
  static List<InventoryItem> _items = [];

  // Singleton factory constructor
  factory InventoryService() {
    return _instance;
  }

  // Private constructor
  InventoryService._internal();

  // Envanter öğelerini getir
  static List<InventoryItem> getItems() {
    return _items;
  }

  // Envanter öğesini ID'ye göre bul
  static InventoryItem? getItem(int id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // Yeni bir envanter öğesi ekle
  static void addItem(InventoryItem item) {
    _items.add(item);
  }

  // Envanter öğesini güncelle
  static void updateItem(InventoryItem updatedItem) {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
    }
  }

  // Envanter öğesini kaldır
  static void removeItem(int id) {
    _items.removeWhere((item) => item.id == id);
  }

  // Envanter öğesini ID'ye göre sil
  static void deleteItem(int itemId) {
    _items.removeWhere((item) => item.id == itemId);
  }

  // Sipariş iptal edildiğinde stok iadesi
  static void returnItemToInventory(int itemId, int quantity) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      _items[index].quantity = (_items[index].quantity ?? 0) + quantity;
    } else {
      // Ürün envanterde yoksa, oluşturalım (bu genelde olmaz ama güvenlik için)
      final item = InventoryItem(
        id: itemId,
        quantity: quantity,
      );
      _items.add(item);
    }
  }

  static Future<void> updateItemQuantity(int itemId, int quantityChange) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = _items[index];
      final newQuantity = (item.quantity ?? 0) + quantityChange;
      
      item.quantity = newQuantity;
      
      // Update status based on quantity
      if (newQuantity == 0) {
        item.extraFields['Status'] = 'Tükendi';
      } else if (newQuantity < 10) {
        item.extraFields['Status'] = 'Kritik Seviye';
      } else {
        item.extraFields['Status'] = 'Stokta';
      }
      
      _items[index] = item;
    }
  }
} 