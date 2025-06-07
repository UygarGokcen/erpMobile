import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/customer.dart';
import 'package:erpmobilapp/services/customer_service.dart';

class CustomField {
  String name;
  String value;
  
  CustomField({required this.name, required this.value});
}

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  CustomerDetailScreen({required this.customer});

  @override
  _CustomerDetailScreenState createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _customFieldNameController;
  
  List<Map<String, TextEditingController>> _customFieldControllers = [];
  bool _isNewCustomer = false;
  String? selectedCountry;
  String? selectedCity;
  
  // Önerilen alanlar listesi
  final List<String> _suggestedFields = [
    'Telefon',
    'E-posta',
    'Vergi Numarası',
    'Şirket',
    'Adres',
    'Web Sitesi',
    'Fax',
    'Notlar',
    'Özel Alan Ekle'
  ];

  // Örnek ülke listesi - Gerçek uygulamada daha kapsamlı bir liste kullanılmalı
  final Map<String, String> countries = {
    'Türkiye': '🇹🇷',
    'Amerika': '🇺🇸',
    'İngiltere': '🇬🇧',
    'Almanya': '🇩🇪',
    'Fransa': '🇫🇷',
    'İtalya': '🇮🇹',
    'İspanya': '🇪🇸',
    'Rusya': '🇷🇺',
    'Çin': '🇨🇳',
    'Japonya': '🇯🇵',
  };

  // Örnek şehir listesi - Seçilen ülkeye göre dinamik olarak değişmeli
  final Map<String, List<String>> cities = {
    'Türkiye': ['İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya'],
    'Amerika': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'],
    'Almanya': ['Berlin', 'Hamburg', 'Munich', 'Cologne', 'Frankfurt'],
    // Diğer ülkeler için şehirler eklenebilir
  };

  @override
  void initState() {
    super.initState();
    _isNewCustomer = widget.customer.name.isEmpty;
    _nameController = TextEditingController(text: widget.customer.name);
    _idController = TextEditingController(text: _isNewCustomer ? '1' : widget.customer.id.toString());
    _customFieldNameController = TextEditingController();
    
    // Mevcut ülke ve şehir bilgilerini yükle
    if (widget.customer.extraFields.containsKey('Ülke')) {
      selectedCountry = widget.customer.extraFields['Ülke'];
    }
    if (widget.customer.extraFields.containsKey('Şehir')) {
      selectedCity = widget.customer.extraFields['Şehir'];
    }
    
    // Mevcut özel alanları yükle
    if (widget.customer.extraFields.isNotEmpty) {
      widget.customer.extraFields.forEach((key, value) {
        if (key != 'Ülke' && key != 'Şehir') {
          Map<String, TextEditingController> controllers = {
            'name': TextEditingController(text: key),
            'value': TextEditingController(text: value),
          };
          _customFieldControllers.add(controllers);
        }
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
      setState(() {
        Map<String, TextEditingController> controllers = {
          'name': TextEditingController(text: selectedField),
          'value': TextEditingController(),
        };
        _customFieldControllers.add(controllers);
      });
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
  
  void _deleteCustomer() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Müşteriyi Sil'),
          content: Text('${widget.customer.name} müşterisini silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () {
                CustomerService.removeCustomer(widget.customer.id);
                Navigator.of(context).pop(); // Dialog'u kapat
                Navigator.of(context).pop(); // Ekranı kapat
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewCustomer ? 'Yeni Müşteri' : widget.customer.name),
        actions: [
          if (selectedCountry != null)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                countries[selectedCountry] ?? '',
                style: TextStyle(fontSize: 24),
              ),
            ),
          if (!_isNewCustomer)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteCustomer,
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
                        'Müşteri Bilgileri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _idController,
                        decoration: InputDecoration(
                          labelText: 'Müşteri ID',
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
                          labelText: 'Müşteri Adı *',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCountry,
                        decoration: InputDecoration(
                          labelText: 'Ülke',
                          border: OutlineInputBorder(),
                        ),
                        items: countries.keys.map((String country) {
                          return DropdownMenuItem<String>(
                            value: country,
                            child: Row(
                              children: [
                                Text(countries[country] ?? ''),
                                SizedBox(width: 8),
                                Text(country),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCountry = newValue;
                            selectedCity = null; // Ülke değiştiğinde şehri sıfırla
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      if (selectedCountry != null && cities.containsKey(selectedCountry))
                        DropdownButtonFormField<String>(
                          value: selectedCity,
                          decoration: InputDecoration(
                            labelText: 'Şehir',
                            border: OutlineInputBorder(),
                          ),
                          items: cities[selectedCountry]?.map((String city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCity = newValue;
                            });
                          },
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
                                child: TextField(
                                  controller: controllers['value'],
                                  decoration: InputDecoration(
                                    labelText: 'Değer',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                  maxLines: fieldName == 'Notlar' ? 4 : 1,
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
              
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text('Müşteriyi Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _nameController.text.isNotEmpty ? () {
                  Map<String, String> extraFields = {};
                  
                  // Ülke ve şehir bilgilerini ekle
                  if (selectedCountry != null) {
                    extraFields['Ülke'] = selectedCountry!;
                  }
                  if (selectedCity != null) {
                    extraFields['Şehir'] = selectedCity!;
                  }
                  
                  // Diğer özel alanları ekle
                  for (var controller in _customFieldControllers) {
                    String name = controller['name']?.text ?? '';
                    String value = controller['value']?.text ?? '';
                    
                    if (name.isNotEmpty) {
                      extraFields[name] = value;
                    }
                  }
                  
                  Customer updatedCustomer = Customer(
                    id: int.tryParse(_idController.text) ?? widget.customer.id,
                    name: _nameController.text,
                    location: selectedCity ?? '',
                    phoneNumber: '',
                    orderIds: widget.customer.orderIds,
                    notes: extraFields['Notlar'] ?? '',
                    extraFields: extraFields,
                  );
                  
                  Navigator.pop(context, updatedCustomer);
                } : null,
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
    _idController.dispose();
    _customFieldNameController.dispose();
    
    for (var controllers in _customFieldControllers) {
      controllers['name']?.dispose();
      controllers['value']?.dispose();
    }
    
    super.dispose();
  }
}

