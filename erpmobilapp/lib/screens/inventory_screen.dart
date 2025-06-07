import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/inventory_item.dart';
import 'package:erpmobilapp/screens/inventory_item_detail_screen.dart';
import 'package:erpmobilapp/services/inventory_service.dart';
import 'package:erpmobilapp/services/logging_service.dart';
import 'package:erpmobilapp/models/log_entry.dart';
import 'dart:io';

class InventoryScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  InventoryScreen({required this.currentUser});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _isLoading = true;
  List<InventoryItem> _inventoryItems = [];
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  List<InventoryItem> _filteredItems = [];

  final List<String> _statusOptions = [
    'Tedarik Edildi',
    'Sipariş Verildi',
    'Üretimde',
    'Stokta',
    'Kritik Seviye',
    'Tükendi'
  ];

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
  }

  Future<void> _loadInventoryItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await InventoryService.getItems();
      setState(() {
        _inventoryItems = items;
        _filteredItems = items;
      });
    } catch (e) {
      // Hata yönetimi
      print('Envanter yüklenirken hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = _inventoryItems;
      } else {
        _filteredItems = _inventoryItems.where((item) {
          return item.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showQuickUpdateDialog(InventoryItem item) {
    TextEditingController quantityController = TextEditingController(text: item.quantity.toString());
    String selectedStatus = item.extraFields['Status'] ?? 'Stokta';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Miktar',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: InputDecoration(
                labelText: 'Durum',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  selectedStatus = newValue;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              int newQuantity = int.tryParse(quantityController.text) ?? item.quantity;
              Map<String, String> updatedFields = Map.from(item.extraFields);
              updatedFields['Status'] = selectedStatus;

              InventoryItem updatedItem = InventoryItem(
                id: item.id,
                name: item.name,
                quantity: newQuantity,
                price: item.price,
                extraFields: updatedFields,
                imagePath: item.imagePath,
              );

              InventoryService.updateItem(updatedItem);
              _logInventoryAction(LogAction.update, updatedItem.id.toString(), 'Envanter hızlı güncelleme: ${updatedItem.name}');
              _loadInventoryItems();
              Navigator.pop(context);
            },
            child: Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(InventoryItem item) {
    if (item.imagePath != null && File(item.imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(item.imagePath!),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.image,
          color: Colors.grey[600],
          size: 24,
        ),
      );
    }
  }

  String _getStatusDisplay(InventoryItem item) {
    String status = item.extraFields['Status'] ?? 'Stokta';
    String productionQty = item.extraFields['Üretim Miktarı'] ?? '';
    
    if ((status == 'Üretimde' || status == 'Tedarik Edildi') && productionQty.isNotEmpty) {
      return 'Durum: $status\n${item.quantity} adet - ${productionQty} adet $status';
    } else {
      return 'Durum: $status';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Envanter'),
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ürün ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          
          // İçerik
          Expanded(
            child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _filteredItems.isEmpty
                ? Center(child: Text('Ürün bulunamadı'))
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: _buildItemImage(item),
                          title: Text(item.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Stok: ${item.quantity} | Fiyat: ${item.price.toStringAsFixed(2)} ₺'),
                              Text(
                                _getStatusDisplay(item),
                                style: TextStyle(
                                  color: _getStatusColor(item.extraFields['Status'] ?? 'Stokta'),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_attributes),
                                onPressed: () => _showQuickUpdateDialog(item),
                                tooltip: 'Hızlı Güncelle',
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editItem(item),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteItem(item),
                              ),
                            ],
                          ),
                          onTap: () => _showQuickUpdateDialog(item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewItem,
        child: Icon(Icons.add),
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _editItem(InventoryItem item) async {
    final updatedItem = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryItemDetailScreen(item: item),
      ),
    );
    
    if (updatedItem != null) {
      try {
        InventoryService.updateItem(updatedItem);
        _logInventoryAction(LogAction.update, updatedItem.id.toString(), 'Envanter güncellendi: ${updatedItem.name}');
        await _loadInventoryItems(); // Listeyi yenile
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme sırasında hata oluştu: $e')),
        );
      }
    }
  }

  void _deleteItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ürünü Sil'),
        content: Text('${item.name} ürününü silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                InventoryService.deleteItem(item.id);
                _logInventoryAction(LogAction.delete, item.id.toString(), 'Envanter silindi: ${item.name}');
                await _loadInventoryItems(); // Listeyi yenile
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ürün başarıyla silindi')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Silme sırasında hata oluştu: $e')),
                );
              }
            },
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addNewItem() async {
    // Yeni bir boş InventoryItem oluştur
    final newItem = InventoryItem(
      id: DateTime.now().millisecondsSinceEpoch,
      name: '',
      quantity: 0,
      price: 0.0,
    );
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryItemDetailScreen(item: newItem),
      ),
    );
    
    if (result != null) {
      try {
        InventoryService.addItem(result);
        _logInventoryAction(LogAction.create, result.id.toString(), 'Yeni envanter eklendi: ${result.name}');
        await _loadInventoryItems(); // Listeyi yenile
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün başarıyla eklendi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün eklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Tedarik Edildi':
        return Colors.green;
      case 'Sipariş Verildi':
        return Colors.blue;
      case 'Üretimde':
        return Colors.orange;
      case 'Kritik Seviye':
        return Colors.red;
      case 'Tükendi':
        return Colors.grey;
      default:
        return Colors.black54;
    }
  }
  
  void _logInventoryAction(LogAction action, String itemId, String description) {
    LoggingService.logAction(
      userId: widget.currentUser['id'].toString(),
      userName: widget.currentUser['name'],
      action: action,
      entityType: LogEntityType.inventory,
      entityId: itemId,
      description: description,
    );
  }
}

