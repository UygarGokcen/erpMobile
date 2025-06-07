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

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> customers = [];
  List<Customer> filteredCustomers = [];
  TextEditingController _searchController = TextEditingController();
  String? selectedCountryFilter;

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
    _loadCustomers();
    _searchController.addListener(_filterCustomers);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Müşteriler'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Müşteri Adı veya ID ile Ara...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCountryFilter,
                  decoration: InputDecoration(
                    labelText: 'Ülkeye Göre Filtrele',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.flag),
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
              ],
            ),
          ),
          Expanded(
            child: filteredCustomers.isEmpty
                ? Center(
                    child: Text('Müşteri bulunamadı'),
                  )
                : ListView.builder(
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      String countryFlag = countries[customer.extraFields['Ülke']] ?? '';
                      
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(customer.name.isNotEmpty ? customer.name[0] : '?'),
                          ),
                          title: Text(customer.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${customer.id}'),
                              if (customer.extraFields['Ülke'] != null)
                                Text('${customer.extraFields['Ülke']}${customer.extraFields['Şehir'] != null ? ' - ${customer.extraFields['Şehir']}' : ''}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (countryFlag.isNotEmpty)
                                Text(
                                  countryFlag,
                                  style: TextStyle(fontSize: 24),
                                ),
                              Icon(Icons.arrow_forward_ios),
                            ],
                          ),
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
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          _addNewCustomer();
        },
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
    _searchController.dispose();
    super.dispose();
  }
}

