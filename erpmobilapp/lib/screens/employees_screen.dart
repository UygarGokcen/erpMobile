import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/employee.dart';
import 'package:erpmobilapp/screens/employee_detail_screen.dart';
import 'package:erpmobilapp/models/user_role.dart';
import 'package:erpmobilapp/services/employee_service.dart';
import 'package:erpmobilapp/services/logging_service.dart';
import 'package:erpmobilapp/models/log_entry.dart';

class EmployeesScreen extends StatefulWidget {
  final Employee currentUser;

  EmployeesScreen({required this.currentUser});

  @override
  _EmployeesScreenState createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> 
    with TickerProviderStateMixin {
  List<Employee> employees = [];
  List<Employee> _filteredEmployees = [];
  bool isLoading = true;
  String searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadEmployees();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadEmployees() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final loadedEmployees = await EmployeeService.getEmployees();
      setState(() {
        employees = loadedEmployees;
        _filteredEmployees = loadedEmployees;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      print("Çalışan verisi yükleme hatası: $e");
      setState(() {
        employees = [];
        _filteredEmployees = [];
        isLoading = false;
      });
      _animationController.forward();
    }
  }

  void _filterEmployees(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        _filteredEmployees = employees;
      } else {
      _filteredEmployees = employees.where((employee) {
          return employee.name.toLowerCase().contains(query.toLowerCase()) ||
                 (employee.department?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (employee.position?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Modern Header with Stats
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF013220), Color(0xFF015a3a)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Title
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.people_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Çalışanlar',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Ekip üyelerinizi yönetin',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                              onPressed: _addNewEmployee,
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Stats Cards
                        _buildStatsCards(),
                        
                        SizedBox(height: 20),
                        
                        // Search Bar
                        _buildSearchBar(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (isLoading)
                      _buildLoadingState()
                    else if (_filteredEmployees.isEmpty)
                      _buildEmptyState()
                    else
                      _buildEmployeesList(),
                  ],
                ),
              ),
            ),
            
            SliverToBoxAdapter(child: SizedBox(height: 80)), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildStatsCards() {
    int totalEmployees = employees.length;
    int adminCount = employees.where((e) => e.role == UserRole.administrator).length;
    int managerCount = employees.where((e) => e.role == UserRole.administrator).length;
    int employeeCount = employees.where((e) => e.role == UserRole.employee).length;
    
    return Row(
      children: [
        Expanded(child: _buildStatCard('Toplam', totalEmployees.toString(), Icons.people, Colors.blue)),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('Admin', adminCount.toString(), Icons.admin_panel_settings, Colors.purple)),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('Çalışan', employeeCount.toString(), Icons.person, Colors.green)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'İsim, departman veya pozisyona göre ara...',
          hintStyle: TextStyle(color: Colors.white60),
          prefixIcon: Icon(Icons.search, color: Colors.white60),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: _filterEmployees,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(60),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF013220)),
            ),
            SizedBox(height: 16),
            Text(
              'Çalışanlar yükleniyor...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF013220).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 48,
                color: Color(0xFF013220),
              ),
            ),
            SizedBox(height: 20),
            Text(
              searchQuery.isEmpty ? 'Henüz çalışan eklenmedi' : 'Arama sonucu bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF013220),
              ),
            ),
            SizedBox(height: 8),
            Text(
              searchQuery.isEmpty 
                ? 'Yeni çalışan eklemek için + butonunu kullanın'
                : '"$searchQuery" için sonuç bulunamadı',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeesList() {
    return Column(
      children: _filteredEmployees.map((employee) => _buildEmployeeCard(employee)).toList(),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _viewEmployeeDetail(employee),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF013220), Color(0xFF015a3a)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Employee Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name.isNotEmpty ? employee.name : 'İsimsiz Çalışan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF013220),
                        ),
                      ),
                      SizedBox(height: 4),
                      if (employee.department?.isNotEmpty == true || employee.position?.isNotEmpty == true)
                        Text(
                          [
                            if (employee.department?.isNotEmpty == true) employee.department!,
                            if (employee.position?.isNotEmpty == true) employee.position!,
                          ].join(' • '),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(employee.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getRoleText(employee.role),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getRoleColor(employee.role),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                Column(
                  children: [
                    GestureDetector(
                      onTap: () => _editEmployee(employee),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          color: Colors.blue.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showDeleteConfirmation(context, employee),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.delete_outlined,
                          color: Colors.red.shade600,
                          size: 18,
                        ),
                      ),
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

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF013220), Color(0xFF015a3a)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF013220).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: _addNewEmployee,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Yeni Çalışan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.administrator:
        return Colors.purple.shade600;

      case UserRole.employee:
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getRoleText(UserRole? role) {
    switch (role) {
      case UserRole.administrator:
        return 'Yönetici';

      case UserRole.employee:
        return 'Çalışan';
      default:
        return 'Belirsiz';
    }
  }

  void _addNewEmployee() {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployeeDetailScreen(
                    employee: Employee(
            id: _generateNewEmployeeId(), 
                      name: '',
                      email: '', 
                      password: '',
                    ),
                    currentUser: widget.currentUser,
                    isEditMode: true,
                  ),
                ),
              ).then((_) => _loadEmployees());
  }

  void _editEmployee(Employee employee) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EmployeeDetailScreen(
                                        employee: employee,
                                        currentUser: widget.currentUser,
                                        isEditMode: true,
                                      ),
                                    ),
                                  ).then((_) => _loadEmployees());
  }

  void _viewEmployeeDetail(Employee employee) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EmployeeDetailScreen(
                                  employee: employee,
                                  currentUser: widget.currentUser,
                                  isEditMode: false,
                                ),
                              ),
                            ).then((_) => _loadEmployees());
  }

  void _showDeleteConfirmation(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_outlined,
                    color: Colors.red.shade600,
                    size: 32,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Çalışanı Sil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF013220),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${employee.name} adlı çalışanı silmek istediğinize emin misiniz?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
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
                        onPressed: () {
                          EmployeeService.removeEmployee(employee.id);
                          _logEmployeeAction(LogAction.delete, employee.id.toString(), 'Çalışan silindi: ${employee.name}');
                          _loadEmployees();
                          Navigator.of(context).pop();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${employee.name} silindi'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
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
        );
      },
    );
  }

  int _generateNewEmployeeId() {
    if (employees.isEmpty) {
      return 1;
    }
    
    int maxId = employees.fold(0, (max, employee) => 
      employee.id > max ? employee.id : max);
    return maxId + 1;
  }
  
  void _logEmployeeAction(LogAction action, String employeeId, String description) {
    LoggingService.logAction(
      userId: widget.currentUser.id.toString(),
      userName: widget.currentUser.name,
      action: action,
      entityType: LogEntityType.employee,
      entityId: employeeId,
      description: description,
    );
  }
}

