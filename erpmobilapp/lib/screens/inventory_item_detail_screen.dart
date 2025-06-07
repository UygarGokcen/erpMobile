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

class _InventoryItemDetailScreenState extends State<InventoryItemDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _idController;
  late TextEditingController _productionQuantityController;
  
  List<Map<String, TextEditingController>> _customFieldControllers = [];
  bool _isNewItem = false;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bu alan zaten mevcut!')),
        );
      }
    }
  }

  void _showFieldSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alan Seçin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _suggestedFields.map((field) => 
              ListTile(
                title: Text(field),
                onTap: () {
                  Navigator.pop(context);
                  _addCustomField(field);
                },
              ),
            ).toList(),
          ),
        ),
      ),
    );
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
        return AlertDialog(
          title: Text('Delete Inventory Item'),
          content: Text('Are you sure you want to delete ${widget.item.name}?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                InventoryService.removeItem(widget.item.id);
                Navigator.of(context).pop(); // Dialog'u kapat
                Navigator.of(context).pop(); // Ekranı kapat
              },
            ),
          ],
        );
      },
    );
  }

  void _saveChanges() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ürün adı boş olamaz!')),
      );
      return;
    }

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
    
    Navigator.pop(context, updatedItem);
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
      return Card(
        elevation: 2,
        margin: EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Üretim Bilgileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _productionQuantityController,
                decoration: InputDecoration(
                  labelText: 'Üretim/Tedarik Miktarı',
                  border: OutlineInputBorder(),
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
        ),
      );
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewItem ? 'New Inventory Item' : widget.item.name),
        actions: [
          if (!_isNewItem)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteItem,
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Image Section
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[50],
                              ),
                              child: _imagePath != null 
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_imagePath!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: Colors.grey,
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
                                    labelText: 'Item ID',
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                SizedBox(height: 16),
                                TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Item Name *',
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // Basic Fields
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _quantityController,
                              decoration: InputDecoration(
                                labelText: 'Miktar',
                                border: OutlineInputBorder(),
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
                                labelText: 'Fiyat',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Diğer Bilgiler', style: TextStyle(fontSize: 16)),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: Colors.blue),
                            onPressed: _showFieldSelector,
                          ),
                        ],
                      ),
                      ..._customFieldControllers.asMap().entries.map((entry) {
                        int index = entry.key;
                        var controllers = entry.value;
                        String fieldName = controllers['name']?.text ?? '';
                        
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: controllers['name'],
                                  decoration: InputDecoration(
                                    labelText: 'Alan Adı',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: fieldName == 'Status' 
                                  ? DropdownButtonFormField<String>(
                                      value: controllers['value']?.text.isNotEmpty == true 
                                          ? controllers['value']?.text 
                                          : 'Stokta',
                                      decoration: InputDecoration(
                                        labelText: 'Değer',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      ),
                                      keyboardType: ['Maliyet', 'Minimum Stok', 'Maksimum Stok']
                                          .contains(fieldName)
                                          ? TextInputType.numberWithOptions(decimal: true)
                                          : TextInputType.text,
                                    ),
                              ),
                              IconButton(
                                icon: Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => _removeCustomField(index),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              
              _buildProductionSection(),
              
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text('Save Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _saveChanges, // Always enabled now, validation inside method
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
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

