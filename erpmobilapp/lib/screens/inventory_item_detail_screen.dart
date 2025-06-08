import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/inventory_item.dart';
import 'package:erpmobilapp/services/inventory_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CustomField {
  String name;
  String value;
  
  CustomField({required this.name, required this.value});
}

class InventoryItemDetailScreen extends StatefulWidget {
  final InventoryItem item;

  InventoryItemDetailScreen({required this.item});

  @override
  _InventoryItemDetailScreenState createState() => _InventoryItemDetailScreenState();
}

class _InventoryItemDetailScreenState extends State<InventoryItemDetailScreen>
    with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _idController;
  late TextEditingController _productionQuantityController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Map<String, TextEditingController>> _customFieldControllers = [];
  bool _isNewItem = false;
  bool _isLoading = false;
  File? _selectedImage;
  String? _imagePath;
  
  // Önerilen alanlar listesi
  final List<String> _suggestedFields = [
    'Maliyet',
    'Tedarikçi',
    'Stok Kodu',
    'Birim',
    'Minimum Stok',
    'Maksimum Stok',
    'Raf Konumu',
    'Açıklama',
    'Kategori',
    'Özel Alan Ekle'
  ];

  final List<String> _statusOptions = [
    'Stokta',
    'Kritik Seviye',
    'Tükendi',
    'Tedarik Edildi',
    'Sipariş Verildi',
    'Üretimde'
  ];

  @override
  void initState() {
    super.initState();
    _isNewItem = widget.item.name == null || widget.item.name.isEmpty;
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(
      text: widget.item.quantity != null ? widget.item.quantity.toString() : '0'
    );
    _priceController = TextEditingController(
      text: widget.item.price != null ? widget.item.price.toStringAsFixed(2) : '0.00'
    );
    _idController = TextEditingController(text: _isNewItem ? '1' : widget.item.id.toString());
    _productionQuantityController = TextEditingController(text: '0');
    _imagePath = widget.item.imagePath;
    
    // Mevcut özel alanları yükle (Miktar ve Fiyat hariç)
    if (widget.item.extraFields.isNotEmpty) {
      widget.item.extraFields.forEach((key, value) {
        if (key != 'Miktar' && key != 'Fiyat') {
          Map<String, TextEditingController> controllers = {
            'name': TextEditingController(text: key),
            'value': TextEditingController(text: value),
          };
          _customFieldControllers.add(controllers);
        }
      });
    }
    
    _animationController.forward();
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = path.basename(image.path);
      final File localImage = await File(image.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _selectedImage = localImage;
        _imagePath = localImage.path;
      });
    }
  }

  void _addCustomField([String? selectedField]) {
    if (selectedField == 'Özel Alan Ekle') {
      setState(() {
        Map<String, TextEditingController> controllers = {
          'name': TextEditingController(),
          'value': TextEditingController(),
        };
        _customFieldControllers.add(controllers);
      });
    } else if (selectedField != null) {
      // Check if field already exists
      bool fieldExists = _customFieldControllers.any((controller) => 
          controller['name']?.text == selectedField);
      
      if (!fieldExists && selectedField != 'Miktar' && selectedField != 'Fiyat') {
        setState(() {
          Map<String, TextEditingController> controllers = {
            'name': TextEditingController(text: selectedField),
            'value': TextEditingController(),
          };
          _customFieldControllers.add(controllers);
        });
      } else {
        _showSnackBar('Bu alan zaten mevcut!', Colors.orange);
      }
    }
  }

  void _showFieldSelector() {
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
                    Icon(Icons.add_circle, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Alan Ekle',
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
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: _suggestedFields.map((field) => 
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          leading: Icon(_getFieldIcon(field), color: Color(0xFF013220)),
                          title: Text(
                            field,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF013220),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _addCustomField(field);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'İptal',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getFieldIcon(String fieldName) {
    switch (fieldName) {
      case 'Maliyet': return Icons.attach_money;
      case 'Tedarikçi': return Icons.business;
      case 'Stok Kodu': return Icons.qr_code;
      case 'Birim': return Icons.straighten;
      case 'Minimum Stok': return Icons.trending_down;
      case 'Maksimum Stok': return Icons.trending_up;
      case 'Raf Konumu': return Icons.location_on;
      case 'Açıklama': return Icons.description;
      case 'Kategori': return Icons.category;
      case 'Özel Alan Ekle': return Icons.add;
      default: return Icons.info;
    }
  }
  
  void _removeCustomField(int index) {
    setState(() {
      _customFieldControllers[index]['name']?.dispose();
      _customFieldControllers[index]['value']?.dispose();
      _customFieldControllers.removeAt(index);
    });
  }
  
  void _deleteItem() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
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
                            widget.item.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF013220),
                            ),
                          ),
                          Text(
                            'Bu ürünü kalıcı olarak silinecek',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
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
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'İptal',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        InventoryService.removeItem(widget.item.id);
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        _showSnackBar('Ürün başarıyla silindi!', Colors.red);
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
        );
      },
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

  void _saveChanges() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar('Ürün adı boş olamaz!', Colors.red);
      return;
    }
    
    setState(() => _isLoading = true);

    int quantity = int.tryParse(_quantityController.text) ?? 0;
    double price = double.tryParse(_priceController.text) ?? 0.0;
    Map<String, String> extraFields = {};
    
    for (var controller in _customFieldControllers) {
      String name = controller['name']?.text ?? '';
      String value = controller['value']?.text ?? '';
      
      if (name.isNotEmpty) {
        extraFields[name] = value;
      }
    }
    
    // Handle production quantity for status tracking
    String currentStatus = extraFields['Status'] ?? 'Stokta';
    if (currentStatus == 'Üretimde' || currentStatus == 'Tedarik Edildi') {
      int productionQty = int.tryParse(_productionQuantityController.text) ?? 0;
      if (productionQty > 0) {
        extraFields['Üretim Miktarı'] = productionQty.toString();
      }
    }
    
    InventoryItem updatedItem = InventoryItem(
      id: int.tryParse(_idController.text) ?? widget.item.id,
      name: _nameController.text,
      quantity: quantity,
      price: price,
      extraFields: extraFields,
      imagePath: _imagePath,
    );

    // Stok durumunu kontrol et ve güncelle
    if (quantity == 0) {
      updatedItem.extraFields['Status'] = 'Tükendi';
    } else if (quantity < 10) {
      updatedItem.extraFields['Status'] = 'Kritik Seviye';
    } else if (currentStatus != 'Üretimde' && currentStatus != 'Tedarik Edildi') {
      updatedItem.extraFields['Status'] = 'Stokta';
    } else {
      updatedItem.extraFields['Status'] = currentStatus;
    }
    
    try {
      await Future.delayed(Duration(milliseconds: 500)); // Simulate API call
      Navigator.pop(context, updatedItem);
      _showSnackBar(_isNewItem ? 'Yeni ürün başarıyla eklendi!' : 'Ürün başarıyla güncellendi!', Colors.green);
    } catch (e) {
      _showSnackBar('Hata: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildProductionSection() {
    String currentStatus = '';
    for (var controller in _customFieldControllers) {
      if (controller['name']?.text == 'Status') {
        currentStatus = controller['value']?.text ?? '';
        break;
      }
    }
    
    if (currentStatus == 'Üretimde' || currentStatus == 'Tedarik Edildi') {
      return Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.precision_manufacturing, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Text(
                  'Üretim Bilgileri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF013220),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            TextField(
              controller: _productionQuantityController,
              decoration: InputDecoration(
                labelText: 'Üretim/Tedarik Miktarı',
                prefixIcon: Icon(Icons.factory, color: Color(0xFF013220)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 8),
            Text(
              'Bu miktar stok altında "${currentStatus}" olarak gösterilecek',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
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
              expandedHeight: 200,
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
                    _isNewItem ? '' : widget.item.name,
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
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 40),
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isNewItem ? Icons.add_box : Icons.inventory_2,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                _isNewItem ? 'Yeni Ürün Ekle' : 'Ürün Detayları',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (!_isNewItem)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[300]),
                    onPressed: _deleteItem,
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Temel Bilgiler Kartı
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.info, color: Colors.white, size: 24),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'Ürün Bilgileri',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF013220),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            
                            // Image and Basic Info Section
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Color(0xFF013220).withOpacity(0.3)),
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: [Colors.grey[50]!, Colors.white],
                                      ),
                                    ),
                                    child: _imagePath != null 
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.file(
                                              File(_imagePath!),
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo,
                                                size: 32,
                                                color: Color(0xFF013220),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Resim Ekle',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF013220),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: _idController,
                                        decoration: InputDecoration(
                                          labelText: 'Ürün ID',
                                          prefixIcon: Icon(Icons.tag, color: Color(0xFF013220)),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                      SizedBox(height: 16),
                                      TextField(
                                        controller: _nameController,
                                        decoration: InputDecoration(
                                          labelText: 'Ürün Adı *',
                                          prefixIcon: Icon(Icons.inventory_2, color: Color(0xFF013220)),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            
                            // Quantity and Price
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _quantityController,
                                    decoration: InputDecoration(
                                      labelText: 'Stok Miktarı',
                                      prefixIcon: Icon(Icons.inventory, color: Color(0xFF013220)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _priceController,
                                    decoration: InputDecoration(
                                      labelText: 'Fiyat (₺)',
                                      prefixIcon: Icon(Icons.attach_money, color: Color(0xFF013220)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            
                            // Custom Fields Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ek Bilgiler',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF013220),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.add, color: Colors.white),
                                    onPressed: _showFieldSelector,
                                    tooltip: 'Alan Ekle',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            
                            // Custom Fields
                            if (_customFieldControllers.isEmpty)
                              Container(
                                padding: EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                                      SizedBox(height: 16),
                                      Text(
                                        'Henüz ek bilgi eklenmemiş',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: _showFieldSelector,
                                        icon: Icon(Icons.add),
                                        label: Text('İlk Alanı Ekle'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF013220),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ..._customFieldControllers.asMap().entries.map((entry) {
                                int index = entry.key;
                                var controllers = entry.value;
                                String fieldName = controllers['name']?.text ?? '';
                                
                                return Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.grey[50]!, Colors.white],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
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
                                              _getFieldIcon(fieldName),
                                              color: Color(0xFF013220),
                                              size: 20,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: TextField(
                                              controller: controllers['name'],
                                              decoration: InputDecoration(
                                                labelText: 'Alan Adı',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                contentPadding: EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.remove_circle, color: Colors.red),
                                            onPressed: () => _removeCustomField(index),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      fieldName == 'Status'
                                        ? DropdownButtonFormField<String>(
                                            value: controllers['value']?.text.isNotEmpty == true 
                                                ? controllers['value']?.text 
                                                : 'Stokta',
                                            decoration: InputDecoration(
                                              labelText: 'Durum',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                            items: _statusOptions.map((String status) {
                                              return DropdownMenuItem<String>(
                                                value: status,
                                                child: Text(status),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              if (newValue != null) {
                                                controllers['value']?.text = newValue;
                                                setState(() {}); // Refresh to show/hide production section
                                              }
                                            },
                                          )
                                        : TextField(
                                            controller: controllers['value'],
                                            decoration: InputDecoration(
                                              labelText: 'Değer',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                            keyboardType: ['Maliyet', 'Minimum Stok', 'Maksimum Stok']
                                                .contains(fieldName)
                                                ? TextInputType.numberWithOptions(decimal: true)
                                                : TextInputType.text,
                                          ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                      
                      // Production Section
                      _buildProductionSection(),
                      
                      // Save Button
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF013220).withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Kaydediliyor...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    _isNewItem ? 'Ürün Ekle' : 'Değişiklikleri Kaydet',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                        ),
                      ),
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

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _idController.dispose();
    _productionQuantityController.dispose();
    
    for (var controllers in _customFieldControllers) {
      controllers['name']?.dispose();
      controllers['value']?.dispose();
    }
    
    super.dispose();
  }
}

