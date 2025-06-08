import 'package:flutter/material.dart';
import 'package:erpmobilapp/models/employee.dart';
import 'package:erpmobilapp/services/database_service.dart';
import 'package:erpmobilapp/models/user_role.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _userRole = UserRole.employee;
  String _founderCode = '';
  bool _isCreatingNewFounder = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        Employee newEmployee = Employee(
          id: DateTime.now().millisecondsSinceEpoch,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _userRole,
        );

        await DatabaseService.addEmployee(newEmployee);
        
        print('Employee added successfully: ${newEmployee.email}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful! You can now login.')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  value: _userRole,
                  decoration: InputDecoration(
                    labelText: 'User Role',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: UserRole.values.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.toString().split('.').last),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _userRole = value!;
                    });
                  },
                ),
                if (_userRole == UserRole.administrator)
                  Column(
                    children: [
                      SizedBox(height: 16),
                      CheckboxListTile(
                        title: Text('Create new Founder account'),
                        value: _isCreatingNewFounder,
                        onChanged: (value) {
                          setState(() {
                            _isCreatingNewFounder = value!;
                          });
                        },
                      ),
                    ],
                  ),
                if (_userRole == UserRole.employee || (_userRole == UserRole.administrator && !_isCreatingNewFounder))
                  Column(
                    children: [
                      SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Founder Code',
                          prefixIcon: Icon(Icons.code),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the Founder code';
                          }
                          return null;
                        },
                        onSaved: (value) => _founderCode = value!,
                      ),
                    ],
                  ),
                SizedBox(height: 24),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        child: Text(
                          'Register',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

