import 'package:erpmobilapp/models/dashboard_data.dart';
import 'package:erpmobilapp/models/order.dart';
import 'package:erpmobilapp/services/order_service.dart';
import 'package:erpmobilapp/services/inventory_service.dart';
import 'package:erpmobilapp/services/customer_service.dart';
import 'package:erpmobilapp/models/financial_data.dart';
import 'package:erpmobilapp/services/employee_service.dart';
import 'package:erpmobilapp/services/finance_service.dart';

/// Dashboard için veri sağlayan servis sınıfı
/// Finance, Order, Inventory ve Employee ekranlarından verileri çeker ve dashboard için hazırlar
class DashboardService {
  // Singleton örneği için
  static final DashboardService _instance = DashboardService._internal();

  // Singleton factory constructor
  factory DashboardService() {
    return _instance;
  }

  // Private constructor
  DashboardService._internal();

  // Dashboard verilerini getir
  static Future<DashboardData> getDashboardData() async {
    // Sipariş verilerini çek
    final List<Order> allOrders = await OrderService.getAllOrders();
    final List<Order> completedOrders = (await OrderService.getPreviousOrders()).where(
      (order) => order.status.toString() == 'OrderStatus.completed'
    ).toList();
    
    // Envanter verilerini çek
    final inventoryItems = await InventoryService.getItems();
    
    // Finansal verileri çek
    FinancialData financialData;
    try {
      // Finans servisinden veri çekelim
      financialData = await FinanceService.getFinancialData();
    } catch (e) {
      // Hata durumunda varsayılan değerlerle oluşturalım
      double totalRevenue = completedOrders.fold(0, (sum, order) => sum + order.totalAmount);
      financialData = FinancialData(
        totalRevenue: totalRevenue,
        totalExpenses: totalRevenue * 0.6,
        netProfit: totalRevenue * 0.4,
        accountsReceivable: totalRevenue * 0.2,
        accountsPayable: totalRevenue * 0.1,
      );
    }
    
    // Çalışan sayısını çek
    int employeeCount = 0;
    try {
      employeeCount = (await EmployeeService.getEmployees()).length;
    } catch (e) {
      // Hata durumunda 0 kullanacağız
    }
    
    // Son siparişleri çekelim (en son 5 adet)
    final recentOrders = allOrders
        .where((order) => order.totalAmount > 0)
        .toList()
        ..sort((a, b) => b.id.compareTo(a.id)); // Azalan sırada sırala (en yeni önce)
    
    final recentOrdersData = recentOrders.take(5).map((order) => 
      OrderData(
        id: order.id.toString(),
        amount: order.totalAmount,
        date: DateTime.now().toString().substring(0, 10), // Örnek için bugünün tarihi
      )
    ).toList();
    
    // Envanter değeri
    double inventoryValue = inventoryItems.fold(0, (sum, item) => 
      sum + ((item.price ?? 0) * (item.quantity ?? 0))
    );
    
    // Aylık başarı oranı (örnek veri)
    double monthlySuccessRate = completedOrders.isNotEmpty 
        ? (completedOrders.length / (allOrders.length <= 0 ? 1 : allOrders.length)) * 100 
        : 0;
    
    // Dashboard verilerini oluştur
    return DashboardData(
      totalRevenue: financialData.totalRevenue,
      totalExpenses: financialData.totalExpenses,
      totalOrders: allOrders.length,
      totalEmployees: employeeCount,
      inventoryValue: inventoryValue,
      monthlySuccessRate: monthlySuccessRate,
      recentOrders: recentOrdersData,
    );
  }
} 