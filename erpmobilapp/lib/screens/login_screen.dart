import 'package:flutter/material.dart';
import 'package:erpmobilapp/screens/registration_screen.dart';
import 'package:erpmobilapp/screens/forgot_password_screen.dart';
import 'package:erpmobilapp/screens/erp_screen.dart';
import 'package:erpmobilapp/models/employee.dart';
import 'package:erpmobilapp/services/database_service.dart';
import 'package:erpmobilapp/services/logging_service.dart';
import 'package:erpmobilapp/services/notification_service.dart';
import 'package:erpmobilapp/models/log_entry.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    // Debug message on screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login button pressed - starting validation...')),
    );
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Debug message on screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Validation passed - calling database...')),
      );

      try {
        print('Starting login process...');
        Employee? loggedInEmployee = await DatabaseService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        print('Login completed. Result: ${loggedInEmployee != null ? 'Success' : 'Failed'}');
        
        // Debug message on screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database call completed: ${loggedInEmployee != null ? 'Success' : 'Failed'}')),
        );

        if (loggedInEmployee != null) {
          print('Navigating to ERP screen...');
          
          try {
            await Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ERPScreen(currentUser: loggedInEmployee),
              ),
            );
            print('Navigation completed successfully');
          } catch (navError) {
            print('Navigation error: $navError');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Navigation error: $navError'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          print('Login failed - showing error message');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid email or password'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Login error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                Image.asset(
                  'assets/founder_logo.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
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
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text('Forgot Password?'),
                        ),
                      ),
                      SizedBox(height: 24),
                      _isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _login,
                              child: Text(
                                'Login',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? "),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegistrationScreen(),
                                ),
                              );
                            },
                            child: Text('Register'),
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
    );
  }
}
