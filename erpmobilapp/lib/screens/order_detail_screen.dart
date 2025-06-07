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

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<InventoryItem> _availableItems = [];
  List<Customer> _availableCustomers = [];
  Customer? _selectedCustomer;
  
  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
    _loadCustomers();
    
    // Eğer mevcut bir sipariş düzenleniyorsa, müşteriyi ayarlayalım
    if (widget.order.customer.id != 0) {
      _selectedCustomer = widget.order.customer;
    }
  }
  
  void _loadInventoryItems() async {
    try {
      final items = await InventoryService.getItems();
      
      setState(() {
        // Sadece stokta olan ürünleri gösterelim (quantity > 0)
        _availableItems = items.where((item) => item.quantity != null && item.quantity! > 0).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load inventory items: $e')),
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
        SnackBar(content: Text('Failed to load customers: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order.id == 0 ? 'New Order' : 'Order #${widget.order.id}'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Customer', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            _buildCustomerDropdown(),
            SizedBox(height: 16),
            Text('Order Items', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            widget.order.items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text('No items in this order yet'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: widget.order.items.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(widget.order.items[index].item.name ?? 'Unnamed Item'),
                        subtitle: Text('Quantity: ${widget.order.items[index].quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('\$${((widget.order.items[index].item.price ?? 0) * widget.order.items[index].quantity).toStringAsFixed(2)}'),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  widget.order.items.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Add Item'),
              onPressed: _availableItems.isEmpty ? null : _addItemToOrder,
            ),
            SizedBox(height: 16),
            Text('Total: \$${_calculateTotal().toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: Text('Complete Order'),
                  onPressed: _canCompleteOrder() ? _completeOrder : null,
                ),
                ElevatedButton(
                  child: Text('Cancel Order'),
                  onPressed: widget.order.status == OrderStatus.pending ? _cancelOrder : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Save Order'),
              onPressed: _canSaveOrder() ? _saveOrder : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    return DropdownButtonFormField<Customer>(
      decoration: InputDecoration(
        labelText: 'Customer',
        border: OutlineInputBorder(),
        helperText: _availableCustomers.isEmpty ? 'Add customers first' : null,
      ),
      isExpanded: true,
      value: _selectedCustomer,
      items: _availableCustomers.map((customer) {
        return DropdownMenuItem<Customer>(
          value: customer,
          child: Text(customer.name ?? 'Customer #${customer.id}'),
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
            return AlertDialog(
              title: Text('Add Item to Order'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<InventoryItem>(
                      decoration: InputDecoration(labelText: 'Select Item'),
                      isExpanded: true,
                      items: _availableItems.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text('${item.name ?? "Unnamed"} (${item.quantity} in stock)'),
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
                    SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Quantity (Max: ${availableQuantity})',
                        helperText: selectedItem != null 
                          ? 'Available: ${availableQuantity}' 
                          : 'Select an item first',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        int newQuantity = int.tryParse(value) ?? 1;
                        if (newQuantity > availableQuantity) {
                          newQuantity = availableQuantity;
                        }
                        setState(() {
                          quantity = newQuantity;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Add'),
                  onPressed: (selectedItem != null && quantity > 0) ? () {
                    final orderItem = OrderItem(item: selectedItem!, quantity: quantity);
                    
                    this.setState(() {
                      widget.order.items.add(orderItem);
                      
                      // Stok miktarını güncelle ama henüz kaydetme
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
                ),
              ],
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

      // Show bill screen and handle inventory updates there
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BillScreen(
            order: widget.order,
            onComplete: () async {
              // This will be called after the bill is shown and before returning to dashboard
              for (var orderItem in widget.order.items) {
                final updatedItem = await InventoryService.getItem(orderItem.item.id);
                if (updatedItem != null) {
                  if (updatedItem.quantity == 0) {
                    updatedItem.extraFields['Status'] = 'Tükendi';
                  } else if (updatedItem.quantity < 10) {
                    updatedItem.extraFields['Status'] = 'Kritik Seviye';
                  }
                  InventoryService.updateItem(updatedItem); // No await needed as it's void
                }
              }
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing order: $e')),
      );
    }
  }

  void _cancelOrder() {
    setState(() {
      widget.order.status = OrderStatus.cancelled;
    });
  }

  void _saveOrder() {
    if (_selectedCustomer != null) {
      widget.order.customer = _selectedCustomer!;
      widget.order.totalAmount = _calculateTotal();
      Navigator.pop(context, widget.order);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a customer')),
      );
    }
  }
}

