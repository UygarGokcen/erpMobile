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

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> 
    with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _departmentController;
  late TextEditingController _positionController;
  late TextEditingController _salaryController;
  late TextEditingController _notesController;
  late TextEditingController _idController;
  late TextEditingController _customFieldNameController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<CustomField> _customFields = [];
  List<Map<String, TextEditingController>> _customFieldControllers = [];
  
  bool _isNewEmployee = false;
  bool _isEditMode = true;
  bool _isAddingCustomField = false;
  bool _isLoading = false;
  DateTime? _startDate;
  
  final List<String> _fieldSuggestions = [
    'Departman', 'Pozisyon', 'Maaş', 'TC Kimlik No', 
    'Telefon', 'Adres', 'E-posta', 'Acil Durum Kişisi', 
    'Kan Grubu', 'Doğum Tarihi', 'Notlar'
  ];

  @override
  void initState() {
    super.initState();
    _isNewEmployee = widget.employee.name == null || widget.employee.name.isEmpty;
    _isEditMode = widget.isEditMode;
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _initializeControllers();
    _loadEmployeeData();
    _animationController.forward();
  }
  
  void _initializeControllers() {
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
  }
  
  void _loadEmployeeData() {
    if (widget.employee.extraFields.isNotEmpty) {
      widget.employee.extraFields.forEach((key, value) {
        Map<String, TextEditingController> controllers = {
          'name': TextEditingController(text: key),
          'value': TextEditingController(text: value),
        };
        _customFieldControllers.add(controllers);
      });
    }
    
    // Temel alanları özel alanlara ekle
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
    
    if (widget.employee.notes != null && widget.employee.notes!.isNotEmpty) {
      _customFieldControllers.add({
        'name': TextEditingController(text: 'Notlar'),
        'value': TextEditingController(text: widget.employee.notes),
      });
    }
  }
  
  void _addCustomField() {
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
                      'Yeni Alan Ekle',
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
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey[50],
                ),
                child: DropdownButtonFormField<String>(
                  value: null,
                  decoration: InputDecoration(
                    labelText: 'Alan Türünü Seçin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    prefixIcon: Icon(Icons.category, color: Color(0xFF013220)),
                  ),
                  hint: Text('Önceden tanımlı alanlardan seçin'),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      if (newValue == 'Özel Ekle') {
                        Navigator.pop(context);
                        _showCustomFieldDialog();
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
                      child: Row(
                        children: [
                          Icon(_getFieldIcon(value), color: Color(0xFF013220), size: 20),
                          SizedBox(width: 8),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList()..add(
                    DropdownMenuItem<String>(
                      value: 'Özel Ekle',
                      child: Row(
                        children: [
                          Icon(Icons.create, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Özel Alan Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'İptal',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
  
  void _showCustomFieldDialog() {
    TextEditingController customController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    Icon(Icons.create, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Özel Alan Oluştur',
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
              TextField(
                controller: customController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Alan Adı',
                  hintText: 'Örn: Ehliyet Türü, Dil Bilgisi...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.edit, color: Color(0xFF013220)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'İptal',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (customController.text.trim().isNotEmpty) {
                        Navigator.pop(context);
                        setState(() {
                          Map<String, TextEditingController> controllers = {
                            'name': TextEditingController(text: customController.text.trim()),
                            'value': TextEditingController(),
                          };
                          _customFieldControllers.add(controllers);
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF013220),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Ekle', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getFieldIcon(String fieldName) {
    switch (fieldName) {
      case 'Departman': return Icons.business;
      case 'Pozisyon': return Icons.work;
      case 'Maaş': return Icons.attach_money;
      case 'TC Kimlik No': return Icons.credit_card;
      case 'Telefon': return Icons.phone;
      case 'Adres': return Icons.home;
      case 'E-posta': return Icons.email;
      case 'Acil Durum Kişisi': return Icons.emergency;
      case 'Kan Grubu': return Icons.bloodtype;
      case 'Doğum Tarihi': return Icons.cake;
      case 'Notlar': return Icons.note;
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

  void _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Çalışan adı boş olamaz!', Colors.red);
      return;
    }
    
    setState(() => _isLoading = true);
    
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
      await Future.delayed(Duration(milliseconds: 500)); // Simulate API call
      
      if (_isNewEmployee) {
        EmployeeService.addEmployee(updatedEmployee);
        _showSnackBar('Yeni çalışan başarıyla eklendi!', Colors.green);
      } else {
        EmployeeService.updateEmployee(updatedEmployee);
        _showSnackBar('Çalışan bilgileri güncellendi!', Colors.green);
      }
      
      await Future.delayed(Duration(milliseconds: 500));
      Navigator.pop(context, updatedEmployee);
    } catch (e) {
      _showSnackBar('Hata: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
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
  
  void _deleteEmployee() {
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
                        'Çalışanı Sil',
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
                Text(
                  '${widget.employee.name} adlı çalışanı silmek istediğinizden emin misiniz?',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
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
                        EmployeeService.removeEmployee(widget.employee.id);
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        _showSnackBar('Çalışan silindi!', Colors.red);
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
                    _isNewEmployee ? '' : widget.employee.name,
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
                                  _isNewEmployee ? Icons.person_add : Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                _isNewEmployee ? 'Yeni Çalışan Ekle' : 'Çalışan Detayları',
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
                if (!_isNewEmployee && _isEditMode)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[300]),
                    onPressed: _deleteEmployee,
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
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
                                  'Temel Bilgiler',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF013220),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            _buildModernTextField(
                              controller: _nameController,
                              label: 'Ad Soyad *',
                              icon: Icons.person,
                              isRequired: true,
                            ),
                            SizedBox(height: 16),
                            _buildModernTextField(
                              controller: _idController,
                              label: 'Çalışan ID',
                              icon: Icons.badge,
                              keyboardType: TextInputType.number,
                            ),
                            if (_isNewEmployee) ...[
                              SizedBox(height: 24),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Color(0xFF013220)),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'İşe Başlama Tarihi',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF013220),
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            _startDate == null 
                                              ? 'Tarih seçilmedi' 
                                              : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
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
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF013220),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text('Seç', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (!_isNewEmployee && _startDate != null) ...[
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Color(0xFF013220)),
                                    SizedBox(width: 12),
                                    Text(
                                      'İşe Başlama: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF013220),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Ek Bilgiler Kartı
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      child: Icon(Icons.assignment, color: Colors.white, size: 24),
                                    ),
                                    SizedBox(width: 16),
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
                                if (_isEditMode)
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF013220), Color(0xFF2E7D57)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.add, color: Colors.white),
                                      onPressed: _addCustomField,
                                      tooltip: 'Yeni Alan Ekle',
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 24),
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
                                      if (_isEditMode) ...[
                                        SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: _addCustomField,
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
                                              readOnly: !_isEditMode,
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
                                          if (_isEditMode)
                                            IconButton(
                                              icon: Icon(Icons.remove_circle, color: Colors.red),
                                              onPressed: () => _removeCustomField(index),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      TextField(
                                        controller: controllers['value'],
                                        readOnly: !_isEditMode,
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
                                        keyboardType: fieldName == 'Maaş' || fieldName == 'TC Kimlik No'
                                          ? TextInputType.numberWithOptions(
                                              decimal: fieldName == 'Maaş',
                                            )
                                          : TextInputType.text,
                                        maxLines: fieldName == 'Notlar' ? 4 : 1,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                      
                      // Kaydet Butonu
                      if (_isEditMode)
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
                                      _isNewEmployee ? 'Çalışan Ekle' : 'Değişiklikleri Kaydet',
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
  
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: !_isEditMode,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF013220)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF013220), width: 2),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    _notesController.dispose();
    _idController.dispose();
    _customFieldNameController.dispose();
    
    for (var controllers in _customFieldControllers) {
      controllers['name']?.dispose();
      controllers['value']?.dispose();
    }
    
    super.dispose();
  }
}

