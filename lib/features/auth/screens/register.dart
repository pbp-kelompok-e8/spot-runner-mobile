import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/core/widgets/error_retry.dart'; // Import Widget Error

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _profilePictureController = TextEditingController();

  String _role = 'runner';
  String? _selectedLocation;
  String? _usernameServerMsg;
  String? _emailServerMsg;
  bool _isLoading = false;

  final List<String> _locations = [
    'Jakarta Barat', 'Jakarta Pusat', 'Jakarta Selatan', 'Jakarta Timur', 'Jakarta Utara',
    'Bekasi', 'Bogor', 'Depok', 'Tangerang',
  ];

  String _formatLocationValue(String location) {
    return location.toLowerCase().replaceAll(' ', '_');
  }

  // Fungsi Register terpisah untuk Retry
  Future<void> _handleRegister() async {
    setState(() {
      _usernameServerMsg = null;
      _emailServerMsg = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final request = context.read<CookieRequest>();

    final Map<String, dynamic> data = {
      "username": _usernameController.text,
      "password": _passwordController.text,
      "password_confirm": _confirmPasswordController.text,
      "email": _emailController.text,
      "role": _role,
      "base_location": _formatLocationValue(_selectedLocation!),
    };

    if (_role == 'event_organizer') {
      data["profile_picture"] = _profilePictureController.text;
    }

    try {
      final response = await request.postJson(
        ApiConfig.register,
        jsonEncode(data),
      );

      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully registered! Please login.'), backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          String message = response['message'] ?? 'Failed to register';
          setState(() {
            if (message.toLowerCase().contains("username")) {
              _usernameServerMsg = message;
            } else if (message.toLowerCase().contains("email")) {
              _emailServerMsg = message;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message), backgroundColor: Colors.red),
              );
            }
          });
          _formKey.currentState!.validate();
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorRetryDialog(
          context: context,
          title: "Connection Error",
          message: "Failed to register. Please check your internet connection.",
          onRetry: _handleRegister,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF1D4ED8);
    final Color textDark = const Color(0xFF111827);
    final Color textGrey = const Color(0xFF6B7280);
    final Color textLabel = const Color(0xFF374151);
    final Color inputBorder = const Color(0xFFD1D5DB);
    final Color bgPage = const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgPage,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Register', textAlign: TextAlign.center, style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w800, color: textDark)),
                    const SizedBox(height: 8.0),
                    Text('Create your Spot Runner account!', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.0, color: textGrey)),
                    const SizedBox(height: 32.0),

                    _buildLabel('Username', textLabel),
                    TextFormField(
                      controller: _usernameController,
                      decoration: _inputDecoration('Enter your username', inputBorder, primaryBlue),
                      onChanged: (value) {
                        if (_usernameServerMsg != null) {
                          setState(() => _usernameServerMsg = null);
                          _formKey.currentState!.validate();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your username';
                        if (_usernameServerMsg != null) return _usernameServerMsg;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    _buildLabel('Password', textLabel),
                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecoration('Enter your password', inputBorder, primaryBlue),
                      obscureText: true,
                      validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
                    ),
                    const SizedBox(height: 16.0),

                    _buildLabel('Confirm Password', textLabel),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: _inputDecoration('Confirm your password', inputBorder, primaryBlue),
                      obscureText: true,
                      validator: (value) {
                        if (value!.isEmpty) return 'Please confirm your password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    _buildLabel('Email', textLabel),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('Enter your email', inputBorder, primaryBlue),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        if (_emailServerMsg != null) {
                          setState(() => _emailServerMsg = null);
                          _formKey.currentState!.validate();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your email';
                        if (_emailServerMsg != null) return _emailServerMsg;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    _buildLabel('Select Role', textLabel),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _role = 'runner'),
                          child: Row(children: [
                            Radio<String>(value: 'runner', groupValue: _role, activeColor: primaryBlue, onChanged: (val) => setState(() => _role = val!)),
                            Text('Runner', style: TextStyle(color: textLabel)),
                          ]),
                        ),
                        const SizedBox(width: 16.0),
                        GestureDetector(
                          onTap: () => setState(() => _role = 'event_organizer'),
                          child: Row(children: [
                            Radio<String>(value: 'event_organizer', groupValue: _role, activeColor: primaryBlue, onChanged: (val) => setState(() => _role = val!)),
                            Text('Event Organizer', style: TextStyle(color: textLabel)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    _buildLabel(_role == 'event_organizer' ? 'Base Location' : 'Location', textLabel),
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      hint: Text('Select your location', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                      decoration: _inputDecoration('', inputBorder, primaryBlue),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: _locations.map((String loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                      onChanged: (val) => setState(() => _selectedLocation = val),
                      validator: (value) => value == null ? 'Please select your location' : null,
                    ),
                    const SizedBox(height: 16.0),

                    if (_role == 'event_organizer') ...[
                      _buildLabel('Profile Photo', textLabel),
                      TextFormField(
                        controller: _profilePictureController,
                        decoration: _inputDecoration('Enter Image URL', inputBorder, primaryBlue),
                        validator: (value) => value!.isEmpty ? 'Please enter image URL' : null,
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    const SizedBox(height: 24.0),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        textStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Create Account'),
                    ),

                    const SizedBox(height: 24.0),
                    Divider(color: Colors.grey[200], thickness: 1.5),
                    const SizedBox(height: 16.0),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account? ", style: TextStyle(color: textGrey, fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                          child: Text("Sign In", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: color)),
    );
  }

  InputDecoration _inputDecoration(String hint, Color borderColor, Color focusColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: focusColor, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _profilePictureController.dispose();
    super.dispose();
  }
}