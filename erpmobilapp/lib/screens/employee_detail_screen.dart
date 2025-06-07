import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/employee.dart';
import 'package:erpmobilapp/services/database_service.dart';
import 'package:erpmobilapp/models/user_role.dart';
import 'package:erpmobilapp/services/employee_service.dart';

class CustomField {
  String name;
  String value;
  
  CustomField({required this.name, required this.value});
}

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;
  final Employee currentUser;
  final bool isEditMode;

  EmployeeDetailScreen({
    required this.employee, 
    required this.currentUser, 
    this.isEditMode = true,
  });

  @override
  _EmployeeDetailScreenState createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _departmentController;
  late TextEditingController _positionController;
  late TextEditingController _salaryController;
  late TextEditingController _notesController;
  late TextEditingController _idController;
  late TextEditingController _customFieldNameController;
  
  List<CustomField> _customFields = [];
  List<Map<String, TextEditingController>> _customFieldControllers = [];
  
  bool _isNewEmployee = false;
  bool _isEditMode = true; // Varsayılan olarak düzenleme modu açık
  bool _isAddingCustomField = false;
  DateTime? _startDate;
  
  // Hazır alan önerileri
  final List<String> _fieldSuggestions = ['Departman', 'Pozisyon', 'Maaş', 'TC', 'Telefon', 'Adres', 'E-posta', 'Notlar'];

  @override
  void initState() {
    super.initState();
    _isNewEmployee = widget.employee.name == null || widget.employee.name.isEmpty;
    _isEditMode = widget.isEditMode; // Widget'tan gelen düzenleme modu değerini ayarla
    _nameController = TextEditingController(text: widget.employee.name);
    _departmentController = TextEditingController(text: widget.employee.department);
    _positionController = TextEditingController(text: widget.employee.position);
    _salaryController = TextEditingController(
      text: widget.employee.salary != null ? widget.employee.salary.toString() : '0.0'
    );
    _notesController = TextEditingController(text: widget.employee.notes ?? '');
    _idController = TextEditingController(text: widget.employee.id.toString());
    _customFieldNameController = TextEditingController();
    _startDate = widget.employee.startDate;
    
    // Mevcut özel alanları yükle
    if (widget.employee.extraFields.isNotEmpty) {
      widget.employee.extraFields.forEach((key, value) {
        Map<String, TextEditingController> controllers = {
          'name': TextEditingController(text: key),
          'value': TextEditingController(text: value),
        };
        _customFieldControllers.add(controllers);
      });
    }
    
    // Departman ve pozisyon ekle
    if (widget.employee.department.isNotEmpty) {
      _customFieldControllers.add({
        'name': TextEditingController(text: 'Departman'),
        'value': TextEditingController(text: widget.employee.department),
      });
    }
    
    if (widget.employee.position.isNotEmpty) {
      _customFieldControllers.add({
        'name': TextEditingController(text: 'Pozisyon'),
        'value': TextEditingController(text: widget.employee.position),
      });
    }
    
    if (widget.employee.salary > 0) {
      _customFieldControllers.add({
        'name': TextEditingController(text: 'Maaş'),
        'value': TextEditingController(text: widget.employee.salary.toString()),
      });
    }
    
    if (widget.employee.notes != null && widget.employee.notes.isNotEmpty) {
      _customFieldControllers.add({
        'name': TextEditingController(text: 'Notlar'),
        'value': TextEditingController(text: widget.employee.notes),
      });
    }
  }
  
  void _addCustomField() {
    if (_isAddingCustomField && _customFieldNameController.text.isNotEmpty) {
      setState(() {
        Map<String, TextEditingController> controllers = {
          'name': TextEditingController(text: _customFieldNameController.text),
          'value': TextEditingController(),
        };
        _customFieldControllers.add(controllers);
        _isAddingCustomField = false;
        _customFieldNameController.clear();
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Alan Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: null,
                decoration: InputDecoration(
                  labelText: 'Alan Seçin',
                  border: OutlineInputBorder(),
                ),
                hint: Text('Alan Seçin'),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    if (newValue == 'Özel Ekle') {
                      Navigator.pop(context);
                      setState(() {
                        _isAddingCustomField = true;
                      });
                    } else {
                      Navigator.pop(context);
                      setState(() {
                        Map<String, TextEditingController> controllers = {
                          'name': TextEditingController(text: newValue),
                          'value': TextEditingController(),
                        };
                        _customFieldControllers.add(controllers);
                      });
                    }
                  }
                },
                items: _fieldSuggestions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList()..add(
                  DropdownMenuItem<String>(
                    value: 'Özel Ekle',
                    child: Text('Özel Alan Ekle'),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('İptal'),
            ),
          ],
        ),
      );
    }
  }
  
  void _removeCustomField(int index) {
    setState(() {
      _customFieldControllers[index]['name']?.dispose();
      _customFieldControllers[index]['value']?.dispose();
      _customFieldControllers.removeAt(index);
    });
  }

  void _saveChanges() async {
    // Validate name field
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çalışan adı boş olamaz!')),
      );
      return;
    }
    
    // Özel alanları bir Map'e dönüştür
    Map<String, String> extraFields = {};
    String department = '';
    String position = '';
    double salary = 0.0;
    String notes = '';
    int id = 0;
    
    try {
      id = int.parse(_idController.text);
    } catch (e) {
      id = widget.employee.id;
    }
    
    for (var controller in _customFieldControllers) {
      String name = controller['name']?.text ?? '';
      String value = controller['value']?.text ?? '';
      
      if (name.isNotEmpty) {
        if (name == 'Departman') {
          department = value;
        } else if (name == 'Pozisyon') {
          position = value;
        } else if (name == 'Maaş') {
          salary = double.tryParse(value) ?? 0.0;
        } else if (name == 'Notlar') {
          notes = value;
        } else {
          extraFields[name] = value;
        }
      }
    }
    
    // Temel alanları güncelleme
    Employee updatedEmployee = Employee(
      id: id,
      name: _nameController.text,
      department: department,
      position: position,
      salary: salary,
      email: widget.employee.email,
      password: widget.employee.password,
      role: widget.employee.role,
      notes: notes,
      extraFields: extraFields,
      startDate: _startDate,
    );
    
    try {
      if (_isNewEmployee) {
        // Yeni çalışan ekleme
        EmployeeService.addEmployee(updatedEmployee);
      } else {
        // Varolan çalışanı güncelleme
        EmployeeService.updateEmployee(updatedEmployee);
      }
      Navigator.pop(context, updatedEmployee);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving employee: $e')),
      );
    }
  }
  
  void _deleteEmployee() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Employee'),
          content: Text('Are you sure you want to delete ${widget.employee.name}?'),
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
                EmployeeService.removeEmployee(widget.employee.id);
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
        title: Text(_isNewEmployee ? 'New Employee' : widget.employee.name),
        actions: [
          if (!_isNewEmployee)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteEmployee,
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ana bilgiler
              Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        readOnly: !_isEditMode,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _idController,
                        decoration: InputDecoration(
                          labelText: 'Çalışan ID',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: const Color.fromARGB(255, 255, 255, 255),
                        ),
                        readOnly: !_isEditMode, // Edit modunda ID değiştirilebilir
                      ),
                      SizedBox(height: 16),
                      if (_isAddingCustomField) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customFieldNameController,
                                decoration: InputDecoration(
                                  labelText: 'Özel Alan Adı',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                                autofocus: true,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () {
                                if (_customFieldNameController.text.isNotEmpty) {
                                  _addCustomField();
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.cancel, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _isAddingCustomField = false;
                                  _customFieldNameController.clear();
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                      ],
                      if (_isEditMode)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(Icons.add_circle, color: Colors.blue),
                              onPressed: _addCustomField,
                              tooltip: 'Alan Ekle',
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
                                  readOnly: !_isEditMode,
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
                                  keyboardType: fieldName == 'Maaş' || fieldName == 'TC'
                                    ? TextInputType.numberWithOptions(decimal: fieldName == 'Maaş')
                                    : TextInputType.text,
                                  maxLines: fieldName == 'Notlar' ? 4 : 1,
                                  readOnly: !_isEditMode,
                                ),
                              ),
                              if (_isEditMode)
                                IconButton(
                                  icon: Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => _removeCustomField(index),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      if (_isEditMode && _isNewEmployee) ...[
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(Icons.calendar_today),
                                label: Text(_startDate == null 
                                  ? 'İşe Başlama Tarihi Seç' 
                                  : 'Başlama Tarihi: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                                onPressed: () async {
                                  final DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      _startDate = pickedDate;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      if (!_isEditMode && _startDate != null) ...[
                        SizedBox(height: 24),
                        Text(
                          'İşe Başlama Tarihi: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              if (_isEditMode)
                ElevatedButton.icon(
                  icon: Icon(Icons.save),
                  label: Text('Save Employee'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _saveChanges,
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
    _departmentController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    _notesController.dispose();
    _idController.dispose();
    _customFieldNameController.dispose();
    
    // Özel alan kontrolcülerini temizle
    for (var controllers in _customFieldControllers) {
      controllers['name']?.dispose();
      controllers['value']?.dispose();
    }
    
    super.dispose();
  }
}

