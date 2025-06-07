import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/employee.dart';
import 'package:erpmobilapp/screens/dashboard_screen.dart';
import 'package:erpmobilapp/screens/employees_screen.dart';
import 'package:erpmobilapp/screens/inventory_screen.dart';
import 'package:erpmobilapp/screens/finance_screen.dart';
import 'package:erpmobilapp/screens/orders_screen.dart';
import 'package:erpmobilapp/screens/customers_screen.dart';
import 'package:erpmobilapp/screens/profile_screen.dart';
import 'package:erpmobilapp/screens/messaging_screen.dart';
import 'package:erpmobilapp/models/financial_data.dart';
import 'package:erpmobilapp/screens/notifications_drawer.dart';
import 'package:erpmobilapp/screens/admin_logs_screen.dart';
import 'package:erpmobilapp/models/user_role.dart';

class ERPScreen extends StatefulWidget {
  final Employee currentUser;

  ERPScreen({required this.currentUser});

  @override
  _ERPScreenState createState() => _ERPScreenState();
}

class _ERPScreenState extends State<ERPScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _screens = [
      DashboardScreen(),
      EmployeesScreen(currentUser: widget.currentUser),
      InventoryScreen(currentUser: {
        'id': widget.currentUser.id,
        'name': widget.currentUser.name,
        'role': widget.currentUser.role.toString()
      }),
      FinanceScreen(currentUser: widget.currentUser),
              OrdersScreen(currentUser: widget.currentUser),
      CustomersScreen(currentUser: widget.currentUser),
      MessagingScreen(currentUser: widget.currentUser),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset('assets/founder_logo.png', fit: BoxFit.contain),
        actions: [
          // Admin Logs button (only for administrators)
          if (widget.currentUser.role == UserRole.administrator)
            IconButton(
              icon: Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Logları',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminLogsScreen(),
                  ),
                );
              },
            ),
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.notifications),
                tooltip: 'Bildirimler',
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              if (widget.currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(currentUser: widget.currentUser)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User data not available')),
                );
              }
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Finance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
        ],
        currentIndex: _selectedIndex < 7 ? _selectedIndex : 0,
        onTap: _onItemTapped,
      ),
      endDrawer: NotificationsDrawer(currentUser: widget.currentUser),
    );
  }
}

