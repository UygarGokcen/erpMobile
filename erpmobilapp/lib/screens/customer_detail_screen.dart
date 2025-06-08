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

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _customFieldNameController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Map<String, TextEditingController>> _customFieldControllers = [];
  bool _isNewCustomer = false;
  bool _isLoading = false;
  String? selectedCountry;
  String? selectedCity;
  
  // Önerilen alanlar listesi
  final Map<String, IconData> _suggestedFields = {
    'Telefon': Icons.phone,
    'E-posta': Icons.email,
    'Vergi Numarası': Icons.receipt,
    'Şirket': Icons.business,
    'Adres': Icons.location_on,
    'Web Sitesi': Icons.web,
    'Fax': Icons.fax,
    'Notlar': Icons.notes,
    'Özel Alan Ekle': Icons.add_circle_outline,
  };

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

  void _setNewCustomerId() async {
    try {
      final customers = await CustomerService.getCustomers();
      int newId = 1;
      
      if (customers.isNotEmpty) {
        // En yüksek ID'yi bul ve 1 ekle
        int maxId = customers.map((customer) => customer.id).reduce((a, b) => a > b ? a : b);
        newId = maxId + 1;
      }
      
      setState(() {
        _idController.text = newId.toString();
      });
    } catch (e) {
      // Hata durumunda varsayılan ID
      setState(() {
        _idController.text = '1';
      });
    }
  }

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
    
    _isNewCustomer = widget.customer.name.isEmpty;
    _nameController = TextEditingController(text: widget.customer.name);
    _idController = TextEditingController();
    _customFieldNameController = TextEditingController();
    
    // Yeni müşteri için ID'yi ayarla
    if (_isNewCustomer) {
      _setNewCustomerId();
    } else {
      _idController.text = widget.customer.id.toString();
    }
    
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
    
    _animationController.forward();
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(20),
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
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF013220).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_circle, color: Color(0xFF013220), size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Alan Seçin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF013220),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                constraints: BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    children: _suggestedFields.entries.map((entry) => 
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF013220).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(entry.value, color: Color(0xFF013220), size: 20),
                          ),
                          title: Text(
                            entry.key,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            Navigator.pop(context);
                            _addCustomField(entry.key);
                          },
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeCustomField(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(20),
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
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline, color: Colors.red, size: 32),
              ),
              SizedBox(height: 16),
              Text(
                'Alanı Sil',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF013220),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Bu alanı silmek istediğinize emin misiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('İptal'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _customFieldControllers[index]['name']?.dispose();
                          _customFieldControllers[index]['value']?.dispose();
                          _customFieldControllers.removeAt(index);
                        });
                      },
                      child: Text('Sil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
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
      ),
    );
  }
  
  void _deleteCustomer() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(20),
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
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_outlined, color: Colors.red, size: 40),
                ),
                SizedBox(height: 16),
                Text(
                  'Müşteriyi Sil',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF013220),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '${widget.customer.name} müşterisini silmek istediğinize emin misiniz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Bu işlem geri alınamaz!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        child: Text('İptal'),
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        child: Text('Sil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          CustomerService.removeCustomer(widget.customer.id);
                          Navigator.of(context).pop(); // Dialog'u kapat
                          Navigator.of(context).pop(); // Ekranı kapat
                          _showSnackBar('Müşteri başarıyla silindi!', Colors.red);
                        },
                      ),
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

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: Color(0xFF013220)) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF013220), width: 2),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: Color(0xFF013220)),
        ),
      ),
    );
  }

  Widget _buildCustomFieldRow(int index) {
    var controllers = _customFieldControllers[index];
    String fieldName = controllers['name']?.text ?? '';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: controllers['name'],
                  decoration: InputDecoration(
                    labelText: 'Alan Adı',
                    labelStyle: TextStyle(color: Color(0xFF013220)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF013220)),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: controllers['value'],
                  decoration: InputDecoration(
                    labelText: 'Değer',
                    labelStyle: TextStyle(color: Color(0xFF013220)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF013220)),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  maxLines: fieldName == 'Notlar' ? 3 : 1,
                ),
              ),
              SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _removeCustomField(index),
                ),
              ),
            ],
          ),
        ],
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
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (selectedCountry != null)
                  Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      countries[selectedCountry] ?? '',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                if (!_isNewCustomer)
                  Container(
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: _deleteCustomer,
                    ),
                  ),
              ],
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
                    _isNewCustomer ? '' : (widget.customer.name.isNotEmpty ? widget.customer.name : 'Müşteri Düzenle'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                          top: 80,
                          right: -50,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 100,
                          left: -30,
                          child: Container(
                            width: 80,
                            height: 80,
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
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _isNewCustomer ? Icons.person_add : Icons.person,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _isNewCustomer ? 'Yeni Müşteri Ekleme' : 'Müşteri Bilgilerini Düzenleme',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 8,
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.info_outline, color: Color(0xFF013220), size: 24),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Temel Bilgiler',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF013220),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            _buildModernTextField(
                              controller: _idController,
                              label: 'Müşteri ID',
                              icon: Icons.tag,
                              keyboardType: TextInputType.number,
                              enabled: false,
                            ),
                            _buildModernTextField(
                              controller: _nameController,
                              label: 'Müşteri Adı',
                              icon: Icons.person,
                              required: true,
                              hint: 'Müşteri adını giriniz',
                            ),
                            Container(
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedCountry,
                                decoration: InputDecoration(
                                  labelText: 'Ülke',
                                  labelStyle: TextStyle(color: Color(0xFF013220)),
                                  prefixIcon: Icon(Icons.public, color: Color(0xFF013220)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            ),
                            if (selectedCountry != null && cities.containsKey(selectedCountry))
                              Container(
                                margin: EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: selectedCity,
                                  decoration: InputDecoration(
                                    labelText: 'Şehir',
                                    labelStyle: TextStyle(color: Color(0xFF013220)),
                                    prefixIcon: Icon(Icons.location_city, color: Color(0xFF013220)),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                              ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Ek Bilgiler Kartı
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF013220).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.add_circle, color: Color(0xFF013220), size: 24),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Ek Bilgiler',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF013220),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.add, color: Colors.white),
                                    onPressed: _showFieldSelector,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            if (_customFieldControllers.isEmpty)
                              Container(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Henüz ek bilgi eklenmemiş',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '+ butonuna tıklayarak yeni alan ekleyin',
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._customFieldControllers.asMap().entries.map((entry) {
                                return _buildCustomFieldRow(entry.key);
                              }).toList(),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Kaydet Butonu
                      Container(
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
                        child: ElevatedButton.icon(
                          icon: _isLoading 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.save, color: Colors.white),
                          label: Text(
                            _isLoading ? 'Kaydediliyor...' : 'Müşteriyi Kaydet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _nameController.text.isNotEmpty && !_isLoading ? () async {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            await Future.delayed(Duration(milliseconds: 500)); // Simulate loading
                            
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
                            
                            setState(() {
                              _isLoading = false;
                            });
                            
                            Navigator.pop(context, updatedCustomer);
                          } : null,
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
    _idController.dispose();
    _customFieldNameController.dispose();
    
    for (var controllers in _customFieldControllers) {
      controllers['name']?.dispose();
      controllers['value']?.dispose();
    }
    
    super.dispose();
  }
}

