import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/order.dart';
import 'package:erpmobilapp/models/customer.dart';
import 'package:erpmobilapp/models/order_status.dart';
import 'package:erpmobilapp/models/employee.dart';
import 'package:erpmobilapp/screens/order_detail_screen.dart';
import 'package:erpmobilapp/services/order_service.dart';
import 'package:erpmobilapp/services/customer_service.dart';
import 'package:erpmobilapp/services/logging_service.dart';
import 'package:erpmobilapp/models/log_entry.dart';

class OrdersScreen extends StatefulWidget {
  final Employee? currentUser;
  
  const OrdersScreen({Key? key, this.currentUser}) : super(key: key);
  
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with TickerProviderStateMixin {
  List<Order> activeOrders = [];
  List<Order> previousOrders = [];
  List<Order> filteredOrders = [];
  bool showPreviousOrders = false;
  String searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadOrders();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

void _loadOrders() async {
  List<Order> active = OrderService.getActiveOrders();
  List<Order> previous = await OrderService.getPreviousOrders();

  setState(() {
    activeOrders = active;
    previousOrders = previous;
      _filterOrders();
    });
  }

  void _filterOrders() {
    List<Order> allOrders = showPreviousOrders 
        ? [...activeOrders, ...previousOrders] 
        : activeOrders;
    
    if (searchQuery.isEmpty) {
      filteredOrders = allOrders;
    } else {
      filteredOrders = allOrders.where((order) {
        return order.customer.name?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false;
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Modern Header with Stats
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF013220), Color(0xFF015a3a)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Title
                        Row(
        children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 16),
          Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Siparişler',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Tüm siparişlerinizi yönetin',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                              onPressed: _addNewOrder,
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Stats Cards
                        _buildStatsCards(),
                        
                        SizedBox(height: 20),
                        
                        // Search Bar
                        _buildSearchBar(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Filter Tabs
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildFilterTabs(),
              ),
            ),
            
            // Orders List
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: filteredOrders.isEmpty 
                  ? _buildEmptyState()
                  : _buildOrdersList(),
              ),
            ),
            
            SliverToBoxAdapter(child: SizedBox(height: 80)), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildStatsCards() {
    int pendingCount = activeOrders.where((o) => o.status == OrderStatus.pending).length;
    int processingCount = activeOrders.where((o) => o.status == OrderStatus.processing).length;
    int completedCount = previousOrders.where((o) => o.status == OrderStatus.completed).length;
    
    return Row(
      children: [
        Expanded(child: _buildStatCard('Bekleyen', pendingCount.toString(), Icons.schedule, Colors.orange)),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('İşlemde', processingCount.toString(), Icons.sync, Colors.blue)),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('Tamamlanan', completedCount.toString(), Icons.check_circle, Colors.green)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Müşteri adına göre ara...',
          hintStyle: TextStyle(color: Colors.white60),
          prefixIcon: Icon(Icons.search, color: Colors.white60),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            _filterOrders();
          });
        },
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                showPreviousOrders = false;
                _filterOrders();
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !showPreviousOrders ? Color(0xFF013220) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFF013220),
                  width: 1,
                ),
              ),
              child: Text(
                'Aktif Siparişler (${activeOrders.length})',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: !showPreviousOrders ? Colors.white : Color(0xFF013220),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                showPreviousOrders = true;
                _filterOrders();
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: showPreviousOrders ? Color(0xFF013220) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFF013220),
                  width: 1,
                ),
              ),
              child: Text(
                'Geçmiş Siparişler (${previousOrders.length})',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: showPreviousOrders ? Colors.white : Color(0xFF013220),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList() {
    return Column(
      children: filteredOrders.map((order) => _buildModernOrderCard(order)).toList(),
    );
  }

  Widget _buildModernOrderCard(Order order) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToOrderDetail(order),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getOrderColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getOrderIcon(order.status),
                        color: _getOrderColor(order.status),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customer.name ?? 'Unnamed Customer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF013220),
                            ),
                          ),
                          Text(
                            'Sipariş #${order.id}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getOrderColor(order.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getOrderStatusText(order.status),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Amount and Date Row
                Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.grey.shade600, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '₺${order.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF013220),
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.access_time, color: Colors.grey.shade600, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Bugün', // order.date gibi bir alan eklenebilir
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                
                if (order.items?.isNotEmpty == true) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: Colors.grey.shade600, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '${order.items!.length} ürün',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 12),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF013220).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                color: Color(0xFF013220),
              ),
            ),
            SizedBox(height: 20),
            Text(
              showPreviousOrders ? 'Henüz geçmiş sipariş yok' : 'Henüz aktif sipariş yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF013220),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Yeni sipariş oluşturmak için + butonunu kullanın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF013220), Color(0xFF015a3a)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF013220).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: _addNewOrder,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Yeni Sipariş',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getOrderColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.shade600;
      case OrderStatus.processing:
        return Colors.blue.shade600;
      case OrderStatus.completed:
        return Colors.green.shade600;
      case OrderStatus.cancelled:
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getOrderIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.processing:
        return Icons.sync;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getOrderStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Bekleyen';
      case OrderStatus.processing:
        return 'İşlemde';
      case OrderStatus.completed:
        return 'Tamamlandı';
      case OrderStatus.cancelled:
        return 'İptal';
      default:
        return 'Bilinmiyor';
    }
  }

  void _navigateToOrderDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(order: order),
      ),
    ).then((updatedOrder) {
      if (updatedOrder != null) {
        OrderService.updateOrder(updatedOrder);
        _logOrderAction(LogAction.update, updatedOrder.id.toString(), 'Sipariş güncellendi: ${updatedOrder.customer.name}');
      }
      _loadOrders();
    });
  }

  void _addNewOrder() {
    final customers = CustomerService.getCustomers();
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş oluşturmadan önce müşteri eklemelisiniz'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Müşteri Ekle',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to customers screen
            },
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(
          order: Order(id: 0, customer: Customer(id: 0), status: OrderStatus.pending),
        ),
      ),
    ).then((newOrder) {
      if (newOrder != null) {
        OrderService.addOrder(newOrder);
        _logOrderAction(LogAction.create, newOrder.id.toString(), 'Yeni sipariş oluşturuldu: ${newOrder.customer.name}');
        _loadOrders();
      }
    });
  }
  
  void _logOrderAction(LogAction action, String orderId, String description) {
    if (widget.currentUser != null) {
      LoggingService.logAction(
        userId: widget.currentUser!.id.toString(),
        userName: widget.currentUser!.name,
        action: action,
        entityType: LogEntityType.order,
        entityId: orderId,
        description: description,
      );
    }
  }
}

