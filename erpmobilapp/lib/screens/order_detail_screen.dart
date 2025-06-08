import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/order.dart';
import 'package:erpmobilapp/models/inventory_item.dart';
import 'package:erpmobilapp/models/customer.dart';
import 'package:erpmobilapp/screens/bill_screen.dart';
import 'package:erpmobilapp/models/order_status.dart';
import 'package:provider/provider.dart';
import 'package:erpmobilapp/services/inventory_service.dart';
import 'package:erpmobilapp/services/customer_service.dart';
import 'package:erpmobilapp/services/finance_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  OrderDetailScreen({required this.order});

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> 
    with TickerProviderStateMixin {
  List<InventoryItem> _availableItems = [];
  List<Customer> _availableCustomers = [];
  Customer? _selectedCustomer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _itemAnimationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _itemAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadInventoryItems();
    _loadCustomers();
    
    // Eğer mevcut bir sipariş düzenleniyorsa, müşteriyi ayarlayalım
    if (widget.order.customer.id != 0) {
      _selectedCustomer = widget.order.customer;
    }
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _itemAnimationController.dispose();
    super.dispose();
  }
  
  void _loadInventoryItems() async {
    try {
      final items = InventoryService.getItems();
      
      setState(() {
        // Sadece stokta olan ürünleri gösterelim (quantity > 0)
        _availableItems = items.where((item) => item.quantity != null && item.quantity! > 0).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Envanter ürünleri yüklenemedi: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _loadCustomers() {
    try {
      final customers = CustomerService.getCustomers();
      
      setState(() {
        _availableCustomers = customers;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Müşteriler yüklenemedi: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            // Modern App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
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
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  widget.order.id == 0 ? Icons.add_shopping_cart : Icons.receipt_long,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.order.id == 0 ? 'Yeni Sipariş' : 'Sipariş #${widget.order.id}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      widget.order.id == 0 ? 'Sipariş detaylarını oluşturun' : 'Sipariş detaylarını düzenleyin',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              backgroundColor: Color(0xFF013220),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Selection Card
                    _buildCustomerCard(),
                    
                    SizedBox(height: 20),
                    
                    // Order Items Section
                    _buildOrderItemsSection(),
                    
                    SizedBox(height: 20),
                    
                    // Total Card
                    _buildTotalCard(),
                    
                    SizedBox(height: 20),
                    
                    // Action Buttons
                    _buildActionButtons(),
                    
                    SizedBox(height: 80), // Space for bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Container(
      padding: EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF013220).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: Color(0xFF013220),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Müşteri Seçimi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF013220),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<Customer>(
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: InputBorder.none,
                hintText: _availableCustomers.isEmpty ? 'Önce müşteri ekleyin' : 'Müşteri seçin...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
              ),
              isExpanded: true,
              value: _selectedCustomer,
              items: _availableCustomers.map((customer) {
                return DropdownMenuItem<Customer>(
                  value: customer,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Color(0xFF013220).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.business,
                          color: Color(0xFF013220),
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(customer.name ?? 'Müşteri #${customer.id}'),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _availableCustomers.isEmpty ? null : (Customer? newValue) {
                setState(() {
                  _selectedCustomer = newValue;
                  if (newValue != null) {
                    widget.order.customer = newValue;
                  }
                });
              },
            ),
          ),
          if (_availableCustomers.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Sipariş oluşturmadan önce müşteri eklemelisiniz',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    return Container(
      padding: EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF013220).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF013220),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sipariş Ürünleri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF013220),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF013220), Color(0xFF015a3a)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.add, color: Colors.white, size: 20),
                  onPressed: _availableItems.isEmpty ? null : _addItemToOrder,
                  tooltip: 'Ürün Ekle',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          widget.order.items.isEmpty
              ? _buildEmptyItemsState()
              : _buildItemsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyItemsState() {
    return Container(
      padding: EdgeInsets.all(30),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Henüz ürün eklenmedi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Siparişe ürün eklemek için + butonunu kullanın',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: widget.order.items.asMap().entries.map((entry) {
        int index = entry.key;
        OrderItem item = entry.value;
        return _buildOrderItemCard(item, index);
      }).toList(),
    );
  }

  Widget _buildOrderItemCard(OrderItem orderItem, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF013220).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_outlined,
              color: Color(0xFF013220),
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderItem.item.name ?? 'İsimsiz Ürün',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF013220),
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Adet: ${orderItem.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Birim: ₺${orderItem.item.price?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${((orderItem.item.price ?? 0) * orderItem.quantity).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF013220),
                ),
              ),
              SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.order.items.removeAt(index);
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade600,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    double total = _calculateTotal();
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF013220), Color(0xFF015a3a)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF013220).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calculate_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toplam Tutar',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '₺${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (widget.order.items.isNotEmpty)
            Text(
              '${widget.order.items.length} ürün',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary Actions
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Siparişi Tamamla',
                Icons.check_circle_outline,
                _canCompleteOrder() ? _completeOrder : null,
                Colors.green.shade600,
                isPrimary: true,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Siparişi İptal Et',
                Icons.cancel_outlined,
                widget.order.status == OrderStatus.pending ? _cancelOrder : null,
                Colors.red.shade600,
                isPrimary: false,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 12),
        
        // Save Button
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            'Siparişi Kaydet',
            Icons.save_outlined,
            _canSaveOrder() ? _saveOrder : null,
            Color(0xFF013220),
            isPrimary: true,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback? onPressed, Color color, {bool isPrimary = false}) {
    return Container(
      height: 50,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? color : Colors.transparent,
          foregroundColor: isPrimary ? Colors.white : color,
          elevation: isPrimary ? 4 : 0,
          side: isPrimary ? null : BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _addItemToOrder() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        InventoryItem? selectedItem;
        int quantity = 1;
        int availableQuantity = 0;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF013220).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add_shopping_cart,
                            color: Color(0xFF013220),
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Ürün Ekle',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF013220),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    
                    // Product Selection
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<InventoryItem>(
                        decoration: InputDecoration(
                          labelText: 'Ürün Seçin',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                        ),
                        isExpanded: true,
                        items: _availableItems.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text('${item.name ?? "İsimsiz"} (${item.quantity} stok)'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedItem = value;
                            availableQuantity = value?.quantity ?? 0;
                            quantity = 1;
                          });
                        },
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Quantity Input
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Adet (Maksimum: $availableQuantity)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                          helperText: selectedItem != null 
                            ? 'Mevcut: $availableQuantity adet' 
                            : 'Önce ürün seçin',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          int newQuantity = int.tryParse(value) ?? 1;
                          if (newQuantity > availableQuantity) {
                            newQuantity = availableQuantity;
                          }
                          setState(() {
                            quantity = newQuantity > 0 ? newQuantity : 1;
                          });
                        },
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            child: Text('İptal'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            child: Text('Ekle'),
                            onPressed: (selectedItem != null && quantity > 0) ? () {
                              final orderItem = OrderItem(item: selectedItem!, quantity: quantity);
                              
                              this.setState(() {
                                widget.order.items.add(orderItem);
                                
                                // Stok miktarını güncelle
                                final index = _availableItems.indexWhere((item) => item.id == selectedItem!.id);
                                if (index != -1) {
                                  _availableItems[index].quantity = (_availableItems[index].quantity ?? 0) - quantity;
                                  
                                  if (_availableItems[index].quantity! <= 0) {
                                    _availableItems.removeAt(index);
                                  }
                                }
                              });
                              
                              Navigator.of(context).pop();
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF013220),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  bool _canSaveOrder() {
    return _selectedCustomer != null && widget.order.items.isNotEmpty;
  }

  bool _canCompleteOrder() {
    return widget.order.status == OrderStatus.pending && 
           _selectedCustomer != null && 
           widget.order.items.isNotEmpty;
  }

  double _calculateTotal() {
    return widget.order.items.fold(0, (total, item) => total + ((item.item.price ?? 0) * item.quantity));
  }

  void _completeOrder() async {
    try {
      // Siparişi tamamla
      setState(() {
        widget.order.status = OrderStatus.completed;
        widget.order.totalAmount = _calculateTotal();
      });

      // Finansal verileri güncelle
      double totalRevenue = widget.order.totalAmount;
      double totalExpenses = widget.order.items.fold(0.0, (sum, item) {
        double itemCost = double.tryParse(item.item.extraFields['Maliyet'] ?? '0') ?? 0;
        return sum + (itemCost * item.quantity);
      });
      double profit = totalRevenue - totalExpenses;

      await FinanceService.updateFinancials(
        revenue: totalRevenue,
        expenses: totalExpenses,
        profit: profit
      );

      // Show bill screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BillScreen(
            order: widget.order,
            onComplete: () async {
              for (var orderItem in widget.order.items) {
                final updatedItem = InventoryService.getItem(orderItem.item.id);
                if (updatedItem != null) {
                  if (updatedItem.quantity == 0) {
                    updatedItem.extraFields['Status'] = 'Tükendi';
                  } else if (updatedItem.quantity < 10) {
                    updatedItem.extraFields['Status'] = 'Kritik Seviye';
                  }
                  InventoryService.updateItem(updatedItem);
                }
              }
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş tamamlanırken hata oluştu: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _cancelOrder() {
    setState(() {
      widget.order.status = OrderStatus.cancelled;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sipariş iptal edildi'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveOrder() {
    if (_selectedCustomer != null) {
      widget.order.customer = _selectedCustomer!;
      widget.order.totalAmount = _calculateTotal();
      Navigator.pop(context, widget.order);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen bir müşteri seçin'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

