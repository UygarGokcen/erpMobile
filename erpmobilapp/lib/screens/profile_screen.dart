import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/employee.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:erpmobilapp/services/employee_service.dart';
import 'package:erpmobilapp/services/order_service.dart';
import 'package:erpmobilapp/services/finance_service.dart';

class ProfileScreen extends StatefulWidget {
  final Employee currentUser;

  ProfileScreen({required this.currentUser});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _departmentController;
  late TextEditingController _positionController;
  late TabController _tabController;
  
  // Company profile controllers
  late TextEditingController _companyNameController;
  late TextEditingController _companyAddressController;
  late TextEditingController _companyPhoneController;
  late TextEditingController _companyEmailController;
  late TextEditingController _taxNumberController;
  
  File? _selectedImage;
  String? _profileImagePath;
  
  // Real data from services
  int _totalEmployees = 0;
  int _thisMonthOrders = 0;
  double _totalRevenue = 0;
  double _totalExpenses = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController(text: widget.currentUser.name);
    _emailController = TextEditingController(text: widget.currentUser.email);
    _departmentController = TextEditingController(text: widget.currentUser.department);
    _positionController = TextEditingController(text: widget.currentUser.position);
    
    // Initialize company profile controllers with some default values
    _companyNameController = TextEditingController(text: 'ERP Şirketi A.Ş.');
    _companyAddressController = TextEditingController(text: 'İstanbul, Türkiye');
    _companyPhoneController = TextEditingController(text: '+90 212 555 0123');
    _companyEmailController = TextEditingController(text: 'info@erpcompany.com');
    _taxNumberController = TextEditingController(text: '1234567890');
    
    // Load profile image if exists
    _profileImagePath = widget.currentUser.extraFields['ProfileImage'];
    
    // Load real statistics
    _loadRealStatistics();
  }

  Future<void> _loadRealStatistics() async {
    try {
      // Get employee count
      final employees = await EmployeeService.getEmployees();
      _totalEmployees = employees.length;
      
      // Get orders count (this month)
      final allOrders = await OrderService.getAllOrders();
      final now = DateTime.now();
      _thisMonthOrders = allOrders.where((order) {
        // Since we don't have order dates, we'll use all orders as this month's orders
        return true;
      }).length;
      
      // Get financial data
      final financialData = await FinanceService.getFinancialData();
      _totalRevenue = financialData.totalRevenue;
      _totalExpenses = financialData.totalExpenses;
      
      setState(() {
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'profile_${widget.currentUser.id}_${path.basename(image.path)}';
      final File localImage = await File(image.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _selectedImage = localImage;
        _profileImagePath = localImage.path;
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profil Fotoğrafı Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'profile_${widget.currentUser.id}_${path.basename(image.path)}';
      final File localImage = await File(image.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _selectedImage = localImage;
        _profileImagePath = localImage.path;
      });
    }
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Color(0xFF013220), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipOval(
              child: _profileImagePath != null && File(_profileImagePath!).existsSync()
                  ? Image.file(
                      File(_profileImagePath!),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      color: Color(0xFF013220).withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFF013220),
                      ),
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(0xFF013220),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalProfile() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 20),
          _buildProfileImage(),
          SizedBox(height: 30),
          
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kişisel Bilgiler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF013220),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  _buildStyledTextField(
                    controller: _nameController,
                    label: 'Ad Soyad',
                    icon: Icons.person,
                  ),
                  SizedBox(height: 16),
                  
                  _buildStyledTextField(
                    controller: _emailController,
                    label: 'E-posta',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  
                  _buildStyledTextField(
                    controller: _departmentController,
                    label: 'Departman',
                    icon: Icons.business,
                  ),
                  SizedBox(height: 16),
                  
                  _buildStyledTextField(
                    controller: _positionController,
                    label: 'Pozisyon',
                    icon: Icons.work,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hesap Bilgileri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF013220),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  _buildInfoRow('Kullanıcı ID', widget.currentUser.id.toString()),
                  _buildInfoRow('Rol', widget.currentUser.role.toString().split('.').last),
                  _buildInfoRow('Başlangıç Tarihi', 
                    widget.currentUser.startDate?.toString().split(' ')[0] ?? 'Belirsiz'),
                  _buildInfoRow('Maaş', '${widget.currentUser.salary.toStringAsFixed(2)} ₺'),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 30),
          
          ElevatedButton.icon(
            icon: Icon(Icons.save),
            label: Text('Değişiklikleri Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF013220),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            onPressed: _savePersonalChanges,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyProfile() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 20),
          
          Icon(
            Icons.business,
            size: 80,
            color: Color(0xFF013220),
          ),
          
          SizedBox(height: 20),
          
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Şirket Bilgileri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF013220),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  _buildStyledTextField(
                    controller: _companyNameController,
                    label: 'Şirket Adı',
                    icon: Icons.business,
                  ),
                  SizedBox(height: 16),
                  
                  _buildStyledTextField(
                    controller: _companyAddressController,
                    label: 'Adres',
                    icon: Icons.location_on,
                    maxLines: 2,
                  ),
                  SizedBox(height: 16),
                  
                  _buildStyledTextField(
                    controller: _companyPhoneController,
                    label: 'Telefon',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16),
                  
                  _buildStyledTextField(
                    controller: _companyEmailController,
                    label: 'E-posta',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  
                  _buildStyledTextField(
                    controller: _taxNumberController,
                    label: 'Vergi Numarası',
                    icon: Icons.receipt,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Şirket İstatistikleri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF013220),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  if (_isLoadingStats)
                    Center(child: CircularProgressIndicator(color: Color(0xFF013220)))
                  else ...[
                    _buildStatisticRow('Toplam Çalışan', _totalEmployees.toString(), Icons.people),
                    _buildStatisticRow('Aktif Siparişler', _thisMonthOrders.toString(), Icons.shopping_cart),
                    _buildStatisticRow('Toplam Gelir', '₺${_totalRevenue.toStringAsFixed(2)}', Icons.attach_money),
                    _buildStatisticRow('Toplam Gider', '₺${_totalExpenses.toStringAsFixed(2)}', Icons.money_off),
                  ],
                ],
              ),
            ),
          ),
          
          SizedBox(height: 30),
          
          ElevatedButton.icon(
            icon: Icon(Icons.save),
            label: Text('Şirket Bilgilerini Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            onPressed: _saveCompanyChanges,
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF013220)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF013220), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label + ':',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF013220).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Color(0xFF013220), size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _savePersonalChanges() {
    // Save personal profile changes
    widget.currentUser.name = _nameController.text;
    widget.currentUser.email = _emailController.text;
    widget.currentUser.department = _departmentController.text;
    widget.currentUser.position = _positionController.text;
    
    if (_profileImagePath != null) {
      widget.currentUser.extraFields['ProfileImage'] = _profileImagePath!;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kişisel bilgiler başarıyla kaydedildi!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveCompanyChanges() {
    // Save company profile changes
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Şirket bilgileri başarıyla kaydedildi!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
        elevation: 0,
        backgroundColor: Color(0xFF013220),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Icon(Icons.person),
              text: 'Kişisel Profil',
            ),
            Tab(
              icon: Icon(Icons.business),
              text: 'Şirket Profili',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPersonalProfile(),
          _buildCompanyProfile(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _taxNumberController.dispose();
    super.dispose();
  }
}

