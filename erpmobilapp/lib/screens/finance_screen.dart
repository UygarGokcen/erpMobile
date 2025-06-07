import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/financial_data.dart';
import 'package:erpmobilapp/models/employee.dart'; 
import 'package:erpmobilapp/services/finance_service.dart';

class FinanceScreen extends StatefulWidget {
  final Employee currentUser;

  FinanceScreen({required this.currentUser});

  @override
  _FinanceScreenState createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  late FinancialData financialData;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }
  
  Future<void> _loadFinancialData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final data = await FinanceService.getFinancialData();
      setState(() {
        financialData = data;
        isLoading = false;
      });
    } catch (e) {
      print("Finansal veri yükleme hatası: $e");
      // Hata durumunda varsayılan veri
      setState(() {
        financialData = FinancialData(
          totalRevenue: 0,
          totalExpenses: 0,
          netProfit: 0,
          accountsReceivable: 0,
          accountsPayable: 0,
        );
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Finansal Durum'),
        elevation: 0,
        backgroundColor: Color(0xFF013220),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _loadFinancialData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Detaylı analiz özelliği yakında eklenecek')),
              );
            },
          ),
        ],
      ),
      body: isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF013220)),
                SizedBox(height: 16),
                Text('Finansal veriler yükleniyor...'),
              ],
            ),
          )
        : Container(
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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF013220), Color(0xFF013220).withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Finansal Özet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Net Kar',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '₺${financialData.netProfit.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                financialData.netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                                color: financialData.netProfit >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                financialData.netProfit >= 0 ? 'Karlı' : 'Zararda',
                                style: TextStyle(
                                  color: financialData.netProfit >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Quick Stats Grid
                  Text(
                    'Finansal Göstergeler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF013220),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildStatCard(
                        'Toplam Gelir',
                        '₺${financialData.totalRevenue.toStringAsFixed(2)}',
                        Icons.arrow_upward,
                        Colors.green,
                        'Bu ayki toplam gelir',
                      ),
                      _buildStatCard(
                        'Toplam Gider',
                        '₺${financialData.totalExpenses.toStringAsFixed(2)}',
                        Icons.arrow_downward,
                        Colors.red,
                        'Bu ayki toplam gider',
                      ),
                      _buildStatCard(
                        'Alacaklar',
                        '₺${financialData.accountsReceivable.toStringAsFixed(2)}',
                        Icons.account_balance,
                        Colors.orange,
                        'Müşteri alacakları',
                      ),
                      _buildStatCard(
                        'Borçlar',
                        '₺${financialData.accountsPayable.toStringAsFixed(2)}',
                        Icons.credit_card,
                        Colors.purple,
                        'Tedarikçi borçları',
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Detailed Financial Cards
                  Text(
                    'Detaylı Analiz',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF013220),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  _buildDetailedCard(
                    'Gelir-Gider Analizi',
                    [
                      _buildDetailRow('Brüt Gelir', financialData.totalRevenue, Colors.green),
                      _buildDetailRow('Toplam Gider', financialData.totalExpenses, Colors.red),
                      Divider(),
                      _buildDetailRow('Net Kar/Zarar', financialData.netProfit, 
                        financialData.netProfit >= 0 ? Colors.green : Colors.red),
                    ],
                    Icons.analytics,
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildDetailedCard(
                    'Nakit Akışı',
                    [
                      _buildDetailRow('Müşteri Alacakları', financialData.accountsReceivable, Colors.blue),
                      _buildDetailRow('Tedarikçi Borçları', financialData.accountsPayable, Colors.orange),
                      Divider(),
                      _buildDetailRow('Net Nakit Pozisyonu', 
                        financialData.accountsReceivable - financialData.accountsPayable,
                        (financialData.accountsReceivable - financialData.accountsPayable) >= 0 
                          ? Colors.green : Colors.red),
                    ],
                    Icons.account_balance_wallet,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.add_chart),
                          label: Text('Gelir Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            _showAddRevenueDialog();
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.remove_circle),
                          label: Text('Gider Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            _showAddExpenseDialog();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF013220),
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedCard(String title, List<Widget> children, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xFF013220), size: 24),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF013220),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, double value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            '₺${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRevenueDialog() {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Gelir Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Tutar (₺)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              double amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                await FinanceService.updateFinancials(
                  revenue: amount,
                  expenses: 0,
                  profit: amount,
                );
                Navigator.pop(context);
                _loadFinancialData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gelir başarıyla eklendi')),
                );
              }
            },
            child: Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog() {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Gider Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Tutar (₺)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money_off),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              double amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                await FinanceService.updateFinancials(
                  revenue: 0,
                  expenses: amount,
                  profit: -amount,
                );
                Navigator.pop(context);
                _loadFinancialData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gider başarıyla eklendi')),
                );
              }
            },
            child: Text('Ekle'),
          ),
        ],
      ),
    );
  }
}

