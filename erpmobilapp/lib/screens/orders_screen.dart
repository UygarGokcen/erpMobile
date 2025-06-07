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

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> activeOrders = [];
  List<Order> previousOrders = [];
  bool showPreviousOrders = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

void _loadOrders() async {
  List<Order> active = OrderService.getActiveOrders();
  List<Order> previous = await OrderService.getPreviousOrders();

  setState(() {
    activeOrders = active;
    previousOrders = previous;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: activeOrders.isEmpty 
              ? Center(
                  child: Text('No active orders. Add using the + button.'),
                )
              : ListView.builder(
                  itemCount: activeOrders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderTile(activeOrders[index]);
                  },
                ),
          ),
          _buildPreviousOrdersSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          _addNewOrder();
        },
      ),
    );
  }

  Widget _buildOrderTile(Order order) {
    return ListTile(
      leading: Icon(Icons.shopping_cart, color: _getOrderColor(order.status)),
      title: Text(order.customer.name ?? 'Unnamed Customer'),
      subtitle: Text('Total: \$${order.totalAmount?.toStringAsFixed(2) ?? '0.00'}'),
      trailing: Chip(
        label: Text(order.status.toString().split('.').last),
        backgroundColor: _getOrderColor(order.status),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ),
        ).then((updatedOrder) {
          if (updatedOrder != null) {
            // Sipariş güncellendiyse OrderService'i güncelleyelim
            OrderService.updateOrder(updatedOrder);
            _logOrderAction(LogAction.update, updatedOrder.id.toString(), 'Sipariş güncellendi: ${updatedOrder.customer.name}');
          }
          // Siparişleri yeniden yükleyelim
          _loadOrders();
        });
      },
    );
  }

  Color _getOrderColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPreviousOrdersSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text('Previous Orders'),
            trailing: Icon(showPreviousOrders ? Icons.expand_less : Icons.expand_more),
            onTap: () {
              setState(() {
                showPreviousOrders = !showPreviousOrders;
              });
            },
          ),
          if (showPreviousOrders)
            previousOrders.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('No previous orders.'),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: previousOrders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderTile(previousOrders[index]);
                  },
                ),
        ],
      ),
    );
  }

  void _addNewOrder() {
    // Müşteriler yüklenmiş mi kontrol et
    final customers = CustomerService.getCustomers();
    if (customers.isEmpty) {
      // Müşteri yoksa bilgilendirme mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add customers before creating an order'),
          action: SnackBarAction(
            label: 'Go to Customers',
            onPressed: () {
              // Burada müşteriler ekranına yönlendirebilirsiniz
              // Navigator.pushNamed(context, '/customers');
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
        // Yeni siparişi OrderService'e ekleyelim
        OrderService.addOrder(newOrder);
        _logOrderAction(LogAction.create, newOrder.id.toString(), 'Yeni sipariş oluşturuldu: ${newOrder.customer.name}');
        // Siparişleri yeniden yükleyelim
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

