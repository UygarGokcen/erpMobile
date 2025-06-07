class DashboardData {
  final double totalRevenue;
  final double totalExpenses;
  final int totalOrders;
  final int totalEmployees;
  final double inventoryValue;
  final double monthlySuccessRate;
  final List<OrderData> recentOrders;

  DashboardData({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalOrders,
    required this.totalEmployees,
    required this.inventoryValue,
    required this.monthlySuccessRate,
    required this.recentOrders,
  });
}

class OrderData {
  final String id;
  final double amount;
  final String date;

  OrderData({
    required this.id,
    required this.amount,
    required this.date,
  });
}
