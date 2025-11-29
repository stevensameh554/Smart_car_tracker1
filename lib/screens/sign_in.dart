// lib/screens/sign_in.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/maintenance_provider.dart';
import 'sign_up.dart';
import 'home_shell.dart';
import 'devices.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<MaintenanceProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Color(0xFF061018),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'Smart Car Tracker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Sign in to your account',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailCtl,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'Enter your email',
                        hintStyle: TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: Color(0xFF0D1821),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF0CBAB5)),
                        ),
                        prefixIcon: Icon(Icons.email, color: Colors.white54),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter your email'
                          : (!v.contains('@') ? 'Invalid email' : null),
                    ),
                    SizedBox(height: 18),
                    TextFormField(
                      controller: _passwordCtl,
                      style: TextStyle(color: Colors.white),
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: Color(0xFF0D1821),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF0CBAB5)),
                        ),
                        prefixIcon: Icon(Icons.lock, color: Colors.white54),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : (v.length < 6 ? 'Min 6 characters' : null),
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0CBAB5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            try {
                              // Sign in logic
                              await prov.signIn(_emailCtl.text.trim(), _passwordCtl.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Signed in as ${_emailCtl.text}')),
                              );
                              // Explicitly navigate into the app (replace sign-in route)
                              await Future.delayed(Duration(milliseconds: 200));
                              
                              // First-time users go to Devices to add a device
                              final route = prov.isFirstTimeSignUp
                                  ? MaterialPageRoute(builder: (_) => const DevicesScreen())
                                  : MaterialPageRoute(builder: (_) => const HomeShell());
                              
                              Navigator.of(context).pushReplacement(route);
                            } catch (e) {
                              // Show error if sign in failed
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Invalid email or password. Please sign up first.')),
                              );
                            }
                          }
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Don\'t have an account? ', style: TextStyle(color: Colors.white70)),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => SignUpScreen()),
                          ),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(color: Color(0xFF0CBAB5), fontWeight: FontWeight.bold),
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
    );
  }
}
