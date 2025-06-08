import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/customer.dart';
import 'package:erpmobilapp/models/employee.dart';
import 'package:erpmobilapp/screens/customer_detail_screen.dart';
import 'package:erpmobilapp/services/customer_service.dart';
import 'package:erpmobilapp/services/logging_service.dart';
import 'package:erpmobilapp/models/log_entry.dart';

class CustomersScreen extends StatefulWidget {
  final Employee currentUser;
  
  const CustomersScreen({Key? key, required this.currentUser}) : super(key: key);
  
  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with TickerProviderStateMixin {
  List<Customer> customers = [];
  List<Customer> filteredCustomers = [];
  TextEditingController _searchController = TextEditingController();
  String? selectedCountryFilter;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Ülke listesi - CustomerDetailScreen ile aynı liste kullanılmalı
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
    
    _loadCustomers();
    _searchController.addListener(_filterCustomers);
    _animationController.forward();
  }

  void _loadCustomers() {
    setState(() {
      customers = CustomerService.getCustomers();
      _filterCustomers();
    });
  }

  void _filterCustomers() {
    setState(() {
      String searchQuery = _searchController.text.toLowerCase();
      filteredCustomers = customers.where((customer) {
        bool matchesSearch = customer.name.toLowerCase().contains(searchQuery) ||
                           customer.id.toString() == searchQuery;
        bool matchesCountry = selectedCountryFilter == null ||
                            customer.extraFields['Ülke'] == selectedCountryFilter;
        return matchesSearch && matchesCountry;
      }).toList();
    });
  }

  int get _totalCustomers => customers.length;
  int get _domesticCustomers => customers.where((customer) => 
    customer.extraFields['Ülke'] == 'Türkiye').length;
  int get _internationalCustomers => customers.where((customer) => 
    customer.extraFields['Ülke'] != 'Türkiye' && customer.extraFields['Ülke'] != null).length;
  int get _activeCustomers => customers.length; // Tüm müşteriler aktif sayılıyor

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

  Widget _buildCustomerCard(Customer customer, int index) {
    String countryFlag = countries[customer.extraFields['Ülke']] ?? '';
    String country = customer.extraFields['Ülke'] ?? '';
    String city = customer.extraFields['Şehir'] ?? '';
    
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerDetailScreen(customer: customer),
              ),
            ).then((updatedCustomer) {
              if (updatedCustomer != null) {
                CustomerService.updateCustomer(updatedCustomer);
                _logCustomerAction(LogAction.update, updatedCustomer.id.toString(), 'Müşteri bilgileri güncellendi: ${updatedCustomer.name}');
                _loadCustomers();
                _showSnackBar('${updatedCustomer.name} güncellendi!', Colors.green);
              }
            });
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF013220),
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.tag, color: Colors.grey[500], size: 16),
                          SizedBox(width: 4),
                          Text(
                            'ID: ${customer.id}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                      if (country.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.grey[500], size: 16),
                            SizedBox(width: 4),
                            Text(
                              countryFlag.isNotEmpty ? '$countryFlag $country' : country,
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                            if (city.isNotEmpty) ...[
                              Text(
                                ' - $city',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (countryFlag.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          countryFlag,
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    SizedBox(height: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF013220),
                      size: 16,
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
                                      Icons.people,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'Müşteri Takibi ve Yönetimi',
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
                                      'Toplam',
                                      _totalCustomers.toString(),
                                      Icons.people,
                                      Colors.blue,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatsCard(
                                      'Yurtiçi',
                                      _domesticCustomers.toString(),
                                      Icons.home,
                                      Colors.green,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatsCard(
                                      'Yurtdışı',
                                      _internationalCustomers.toString(),
                                      Icons.public,
                                      Colors.orange,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatsCard(
                                      'Aktif',
                                      _activeCustomers.toString(),
                                      Icons.check_circle,
                                      Colors.teal,
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
                      child: Column(
                        children: [
                          Container(
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
                                hintText: 'Müşteri adı veya ID ile ara...',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                prefixIcon: Icon(Icons.search, color: Color(0xFF013220)),
                                suffixIcon: _searchController.text.isNotEmpty
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
                          SizedBox(height: 16),
                          Container(
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
                            child: DropdownButtonFormField<String>(
                              value: selectedCountryFilter,
                              decoration: InputDecoration(
                                labelText: 'Ülkeye Göre Filtrele',
                                labelStyle: TextStyle(color: Color(0xFF013220)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(Icons.flag, color: Color(0xFF013220)),
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Tüm Ülkeler'),
                                ),
                                ...countries.keys.map((String country) {
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
                              ],
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedCountryFilter = newValue;
                                  _filterCustomers();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            filteredCustomers.isEmpty
              ? SliverToBoxAdapter(
                  child: Container(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchController.text.isNotEmpty || selectedCountryFilter != null 
                              ? Icons.search_off 
                              : Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty || selectedCountryFilter != null
                              ? 'Arama sonucu bulunamadı'
                              : 'Henüz müşteri eklenmemiş',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _searchController.text.isNotEmpty || selectedCountryFilter != null
                              ? 'Farklı arama kriterleri deneyin'
                              : 'İlk müşterinizi eklemek için + butonuna tıklayın',
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
                      if (index >= filteredCustomers.length) return null;
                      return _buildCustomerCard(filteredCustomers[index], index);
                    },
                    childCount: filteredCustomers.length,
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
          onPressed: _addNewCustomer,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _addNewCustomer() {
    int newId = 1;
    if (customers.isNotEmpty) {
      newId = customers.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(
          customer: Customer(id: newId),
        ),
      ),
    ).then((newCustomer) {
      if (newCustomer != null) {
        CustomerService.addCustomer(newCustomer);
        _logCustomerAction(LogAction.create, newCustomer.id.toString(), 'Yeni müşteri eklendi: ${newCustomer.name}');
        _loadCustomers();
        _showSnackBar('${newCustomer.name} başarıyla eklendi!', Colors.green);
      }
    });
  }

  void _logCustomerAction(LogAction action, String customerId, String description) {
    LoggingService.logAction(
      userId: widget.currentUser.id.toString(),
      userName: widget.currentUser.name,
      action: action,
      entityType: LogEntityType.customer,
      entityId: customerId,
      description: description,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

