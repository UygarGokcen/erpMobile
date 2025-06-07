import 'package:erpmobilapp/models/financial_data.dart';
import 'package:erpmobilapp/services/order_service.dart';

/// Finans yönetimi için servis sınıfı
/// Bu sınıf, uygulama genelinde finansal verilere erişim sağlar
class FinanceService {
  // Singleton örneği için
  static final FinanceService _instance = FinanceService._internal();

  // Singleton factory constructor
  factory FinanceService() {
    return _instance;
  }

  // Private constructor
  FinanceService._internal();

  static FinancialData _financialData = FinancialData(
    totalRevenue: 0,
    totalExpenses: 0,
    netProfit: 0,
    accountsReceivable: 0,
    accountsPayable: 0,
  );

  // Finansal verileri getir
  static Future<FinancialData> getFinancialData() async {
    return _financialData;
  }

  static Future<void> updateFinancials({
    required double revenue,
    required double expenses,
    required double profit,
  }) async {
    _financialData = FinancialData(
      totalRevenue: _financialData.totalRevenue + revenue,
      totalExpenses: _financialData.totalExpenses + expenses,
      netProfit: _financialData.netProfit + profit,
      accountsReceivable: _financialData.accountsReceivable,
      accountsPayable: _financialData.accountsPayable,
    );
  }
  
  // Gelir ve gider verilerini ekleme gibi ek metodlar burada olabilir
} 