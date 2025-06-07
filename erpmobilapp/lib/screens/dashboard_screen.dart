import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:erpmobilapp/models/dashboard_data.dart';
import 'package:erpmobilapp/screens/settings_screen.dart';
import 'package:erpmobilapp/services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({super.key});
  
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late DashboardData dashboardData;
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadDashboardData();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDashboardData() async {
    try {
      final data = await DashboardService.getDashboardData();
      setState(() {
        dashboardData = data;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      print("Dashboard veri yükleme hatası: $e");
      dashboardData = DashboardData(
        totalRevenue: 0,
        totalExpenses: 0,
        totalOrders: 0,
        totalEmployees: 0,
        inventoryValue: 0,
        monthlySuccessRate: 0,
        recentOrders: [],
      );
      setState(() {
        isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
        ? Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF013220),
                  Color(0xFF013220).withOpacity(0.8),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Dashboard Yükleniyor...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        : FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                // Modern App Bar
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: Color(0xFF013220),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF013220),
                            Color(0xFF013220).withOpacity(0.8),
                            Color(0xFF015a3a),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(left: 16, right: 16, top: 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hoş Geldiniz!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Bugünkü Performansınız',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                        });
                        _loadDashboardData();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                // Content
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF013220).withOpacity(0.1),
                          Colors.white,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Stats Section
                          Text(
                            'Hızlı Bakış',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF013220),
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildQuickStatsGrid(),
                          
                          SizedBox(height: 32),
                          
                          // Performance Metrics
                          Text(
                            'Performans Metrikleri',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF013220),
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildPerformanceCards(),
                          
                          SizedBox(height: 32),
                          
                          // Revenue Chart
                          _buildModernRevenueChart(),
                          
                          SizedBox(height: 32),
                          
                          // Recent Activity
                          _buildRecentActivity(),
                          
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Toplam Gelir',
          '₺${dashboardData.totalRevenue.toStringAsFixed(0)}',
          Icons.trending_up,
          [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          '+12.5%',
        ),
        _buildStatCard(
          'Toplam Gider',
          '₺${dashboardData.totalExpenses.toStringAsFixed(0)}',
          Icons.trending_down,
          [Color(0xFFF44336), Color(0xFFEF5350)],
          '+8.2%',
        ),
        _buildStatCard(
          'Aktif Siparişler',
          dashboardData.totalOrders.toString(),
          Icons.shopping_cart,
          [Color(0xFF2196F3), Color(0xFF42A5F5)],
          '+3 yeni',
        ),
        _buildStatCard(
          'Çalışan Sayısı',
          dashboardData.totalEmployees.toString(),
          Icons.people,
          [Color(0xFF9C27B0), Color(0xFFBA68C8)],
          'Aktif',
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, List<Color> gradientColors, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Spacer(),
            Text(
              title,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCards() {
    double netProfit = dashboardData.totalRevenue - dashboardData.totalExpenses;
    double profitMargin = dashboardData.totalRevenue > 0 
        ? (netProfit / dashboardData.totalRevenue) * 100 
        : 0;
    
    return Row(
      children: [
        Expanded(
          child: _buildPerformanceCard(
            'Net Kar',
            '₺${netProfit.toStringAsFixed(0)}',
            Icons.account_balance_wallet,
            netProfit >= 0 ? Colors.green : Colors.red,
            netProfit >= 0 ? 'Karlı' : 'Zararda',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildPerformanceCard(
            'Kar Marjı',
            '${profitMargin.toStringAsFixed(1)}%',
            Icons.percent,
            Color(0xFF013220),
            'Bu ay',
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Spacer(),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Color(0xFF013220),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRevenueChart() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: Color(0xFF013220), size: 24),
              SizedBox(width: 12),
              Text(
                'Gelir Trendi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF013220),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF013220).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Son 7 Gün',
                  style: TextStyle(
                    color: Color(0xFF013220),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: dashboardData.recentOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade400),
                      SizedBox(height: 12),
                      Text(
                        'Henüz gelir verisi yok',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '₺${(value / 1000).toStringAsFixed(0)}K',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                            if (value.toInt() >= 0 && value.toInt() < days.length) {
                              return Text(
                                days[value.toInt()],
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: _getMaxChartValue(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _createChartSpots(),
                        isCurved: true,
                        gradient: LinearGradient(
                          colors: [Color(0xFF013220), Color(0xFF015a3a)],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Color(0xFF013220),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF013220).withOpacity(0.3),
                              Color(0xFF013220).withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  double _getMaxChartValue() {
    if (dashboardData.recentOrders.isEmpty) return 10000;
    double maxAmount = dashboardData.recentOrders
        .map((order) => order.amount)
        .reduce((a, b) => a > b ? a : b);
    return (maxAmount * 1.2).ceilToDouble();
  }

  List<FlSpot> _createChartSpots() {
    if (dashboardData.recentOrders.isEmpty) {
      return List.generate(7, (index) => FlSpot(index.toDouble(), 0));
    }
    
    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      if (i < dashboardData.recentOrders.length) {
        spots.add(FlSpot(i.toDouble(), dashboardData.recentOrders[i].amount));
      } else {
        spots.add(FlSpot(i.toDouble(), 0));
      }
    }
    return spots;
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Color(0xFF013220), size: 24),
              SizedBox(width: 12),
              Text(
                'Son Siparişler',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF013220),
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  // Navigate to orders screen
                },
                child: Text(
                  'Tümünü Gör',
                  style: TextStyle(color: Color(0xFF013220)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          dashboardData.recentOrders.isEmpty
            ? Container(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                      SizedBox(height: 12),
                      Text(
                        'Henüz sipariş bulunmuyor',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: min(dashboardData.recentOrders.length, 5),
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final order = dashboardData.recentOrders[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF013220).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt,
                        color: Color(0xFF013220),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Sipariş #${order.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF013220),
                      ),
                    ),
                    subtitle: Text(
                      order.date,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Text(
                      '₺${order.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
  
  int min(int a, int b) => a < b ? a : b;
}
