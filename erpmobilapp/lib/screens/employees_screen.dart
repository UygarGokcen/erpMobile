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

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Employee> employees = [];
  bool isLoading = true;
  List<Employee> _filteredEmployees = [];
  TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadEmployees();
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
    } catch (e) {
      print("Çalışan verisi yükleme hatası: $e");
      setState(() {
        employees = [];
        _filteredEmployees = [];
        isLoading = false;
      });
    }
  }

  void _filterEmployees(String query) {
    setState(() {
      _filteredEmployees = employees.where((employee) {
        return employee.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showDeleteConfirmation(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Çalışanı Sil'),
          content: Text('Bu çalışanı silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                EmployeeService.removeEmployee(employee.id);
                _logEmployeeAction(LogAction.delete, employee.id.toString(), 'Çalışan silindi: ${employee.name}');
                _loadEmployees();
                Navigator.of(context).pop();
              },
              child: Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  int generateNewEmployeeId() {
    if (employees.isEmpty) {
      return 1;
    }
    
    int maxId = employees.fold(0, (max, employee) => 
      employee.id > max ? employee.id : max);
    return maxId + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Çalışanlar'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployeeDetailScreen(
                    employee: Employee(
                      id: generateNewEmployeeId(), 
                      name: '',
                      email: '', 
                      password: '',
                    ),
                    currentUser: widget.currentUser,
                    isEditMode: true,
                  ),
                ),
              ).then((_) => _loadEmployees());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                _filterEmployees(value);
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = _filteredEmployees[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                              style: TextStyle(color: Colors.blue.shade800),
                            ),
                          ),
                          title: Text(employee.name),
                          subtitle: Text(
                            [
                              if (employee.department != null && employee.department.isNotEmpty) 
                                employee.department,
                              if (employee.position != null && employee.position.isNotEmpty) 
                                employee.position,
                            ].join(' - '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
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
                                },
                                child: Text('✏️', style: TextStyle(fontSize: 20)),
                              ),
                              SizedBox(width: 16),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _showDeleteConfirmation(context, employee);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
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
                          },
                          onLongPress: () {
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
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

