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

class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<InventoryItem> _inventoryItems = [];
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  List<InventoryItem> _filteredItems = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedFilter = 'Tümü';

  final List<String> _statusOptions = [
    'Tedarik Edildi',
    'Sipariş Verildi',
    'Üretimde',
    'Stokta',
    'Kritik Seviye',
    'Tükendi'
  ];

  final List<String> _filterOptions = [
    'Tümü',
    'Stokta',
    'Kritik Seviye',
    'Tükendi',
    'Üretimde'
  ];

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
    
    _loadInventoryItems();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
    _animationController.forward();
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
      print('Envanter yüklenirken hata oluştu: $e');
      _showSnackBar('Envanter yüklenirken hata oluştu: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<InventoryItem> filteredBySearch = _searchQuery.isEmpty
        ? _inventoryItems
        : _inventoryItems.where((item) {
            return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    if (_selectedFilter == 'Tümü') {
      _filteredItems = filteredBySearch;
    } else {
      _filteredItems = filteredBySearch.where((item) {
        String itemStatus = item.extraFields['Status'] ?? 'Stokta';
        return itemStatus == _selectedFilter;
      }).toList();
    }
  }

  int get _totalItems => _inventoryItems.length;
  int get _inStockItems => _inventoryItems.where((item) => 
    (item.extraFields['Status'] ?? 'Stokta') == 'Stokta').length;
  int get _criticalItems => _inventoryItems.where((item) => 
    (item.extraFields['Status'] ?? 'Stokta') == 'Kritik Seviye').length;
  int get _outOfStockItems => _inventoryItems.where((item) => 
    (item.extraFields['Status'] ?? 'Stokta') == 'Tükendi').length;

  void _showQuickUpdateDialog(InventoryItem item) {
    TextEditingController quantityController = TextEditingController(text: item.quantity.toString());
    String selectedStatus = item.extraFields['Status'] ?? 'Stokta';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_attributes, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hızlı Güncelleme',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF013220).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.inventory, color: Color(0xFF013220)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF013220),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                  labelText: 'Stok Miktarı',
                  prefixIcon: Icon(Icons.inventory_2, color: Color(0xFF013220)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey[50],
                ),
                child: DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: InputDecoration(
                labelText: 'Durum',
                    prefixIcon: Icon(Icons.flag, color: Color(0xFF013220)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
              ),
              items: _statusOptions.map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(status),
                        ],
                      ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  selectedStatus = newValue;
                }
              },
            ),
        ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
                    child: Text(
                      'İptal',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
          ),
                  ElevatedButton(
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
                      _showSnackBar('${item.name} başarıyla güncellendi!', Colors.green);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF013220),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Güncelle', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemImage(InventoryItem item) {
    if (item.imagePath != null && File(item.imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(item.imagePath!),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF013220).withOpacity(0.1), Color(0xFF2E7D57).withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.inventory,
          color: Color(0xFF013220),
          size: 28,
        ),
      );
    }
  }

  String _getStatusDisplay(InventoryItem item) {
    String status = item.extraFields['Status'] ?? 'Stokta';
    String productionQty = item.extraFields['Üretim Miktarı'] ?? '';
    
    if ((status == 'Üretimde' || status == 'Tedarik Edildi') && productionQty.isNotEmpty) {
      return '$status • ${item.quantity} adet + $productionQty adet';
    } else {
      return status;
    }
  }

  Widget _buildStatsCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF013220),
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(InventoryItem item, int index) {
    String status = item.extraFields['Status'] ?? 'Stokta';
    Color statusColor = _getStatusColor(status);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showQuickUpdateDialog(item),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildItemImage(item),
                SizedBox(width: 16),
          Expanded(
                  child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF013220),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6),
                              Text(
                                _getStatusDisplay(item),
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                                ),
                              ),
                            ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.inventory_2, color: Colors.grey[500], size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Stok: ${item.quantity}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                          SizedBox(width: 16),
                          Icon(Icons.attach_money, color: Colors.grey[500], size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${item.price.toStringAsFixed(2)} ₺',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                            children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF013220).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.edit_attributes, color: Color(0xFF013220), size: 20),
                                onPressed: () => _showQuickUpdateDialog(item),
                                tooltip: 'Hızlı Güncelle',
                              ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue, size: 18),
                                onPressed: () => _editItem(item),
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ),
                        SizedBox(width: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red, size: 18),
                            onPressed: () => _deleteItem(item),
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          String filter = _filterOptions[index];
          bool isSelected = _selectedFilter == filter;
          
          return Container(
            margin: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                  _applyFilters();
                });
              },
              backgroundColor: Colors.white,
              selectedColor: Color(0xFF013220).withOpacity(0.1),
              checkmarkColor: Color(0xFF013220),
              labelStyle: TextStyle(
                color: isSelected ? Color(0xFF013220) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Color(0xFF013220) : Colors.grey[300]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: FlexibleSpaceBar(
                  title: Text(
                    '',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 100,
                          right: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 120,
                          left: -30,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.inventory,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'Envanter ve Stok Takibi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatsCard(
                                      'Toplam Ürün',
                                      _totalItems.toString(),
                                      Icons.inventory_2,
                                      Colors.blue,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatsCard(
                                      'Stokta',
                                      _inStockItems.toString(),
                                      Icons.check_circle,
                                      Colors.green,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatsCard(
                                      'Kritik',
                                      _criticalItems.toString(),
                                      Icons.warning,
                                      Colors.orange,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatsCard(
                                      'Tükendi',
                                      _outOfStockItems.toString(),
                                      Icons.remove_circle,
                                      Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    // Arama ve Filtreler
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Ürün ara...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon: Icon(Icons.search, color: Color(0xFF013220)),
                            suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildFilterChips(),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _isLoading
              ? SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF013220)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Envanter yükleniyor...',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : _filteredItems.isEmpty
                ? SliverToBoxAdapter(
                    child: Container(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty 
                                ? 'Arama sonucu bulunamadı'
                                : 'Henüz ürün eklenmemiş',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                ? 'Farklı anahtar kelimeler deneyin'
                                : 'İlk ürününüzü eklemek için + butonuna tıklayın',
                              style: TextStyle(color: Colors.grey[500]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= _filteredItems.length) return null;
                        return _buildInventoryCard(_filteredItems[index], index);
                      },
                      childCount: _filteredItems.length,
                    ),
                  ),
            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF013220), Color(0xFF2E7D57)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF013220).withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _addNewItem,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
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
        await _loadInventoryItems();
        _showSnackBar('${updatedItem.name} başarıyla güncellendi!', Colors.green);
      } catch (e) {
        _showSnackBar('Güncelleme sırasında hata oluştu: $e', Colors.red);
      }
    }
  }

  void _deleteItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.red[50]!],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[600]!, Colors.red[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Ürünü Sil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.inventory, color: Colors.red),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF013220),
                          ),
                        ),
                        Text(
                          'Stok: ${item.quantity} • ${item.price.toStringAsFixed(2)} ₺',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Bu ürünü silmek istediğinizden emin misiniz?',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Bu işlem geri alınamaz!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[600],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
          TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'İptal',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                InventoryService.deleteItem(item.id);
                _logInventoryAction(LogAction.delete, item.id.toString(), 'Envanter silindi: ${item.name}');
                        await _loadInventoryItems();
                        _showSnackBar('${item.name} başarıyla silindi!', Colors.red);
              } catch (e) {
                        _showSnackBar('Silme sırasında hata oluştu: $e', Colors.red);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Sil', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addNewItem() async {
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
        await _loadInventoryItems();
        _showSnackBar('${result.name} başarıyla eklendi!', Colors.green);
      } catch (e) {
        _showSnackBar('Ürün eklenirken hata oluştu: $e', Colors.red);
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
      case 'Stokta':
        return Colors.teal;
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

