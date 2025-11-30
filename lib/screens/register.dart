import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:spot_runner_mobile/screens/login.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _profilePictureController = TextEditingController();

  // State Variables
  String _role = 'runner'; // Default value
  String? _selectedLocation;

  // Location Options
  final List<String> _locations = [
    'Jakarta Barat',
    'Jakarta Pusat',
    'Jakarta Selatan',
    'Jakarta Timur',
    'Jakarta Utara',
    'Bekasi',
    'Bogor',
    'Depok',
    'Tangerang',
  ];

  String _formatLocationValue(String location) {
    return location.toLowerCase().replaceAll(' ', '_');
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    // Color Palette sesuai Desain
    final Color primaryBlue = const Color(0xFF1D4ED8);
    final Color textDark = const Color(0xFF111827);
    final Color textGrey = const Color(0xFF6B7280);
    final Color textLabel = const Color(0xFF374151); // Gray-700
    final Color inputBorder = const Color(0xFFD1D5DB);
    final Color bgPage = const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgPage,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450), // Batas lebar agar rapi di tablet/web
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0), // Rounded besar
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- HEADER ---
                    Text(
                      'Register',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Create your Spot Runner account!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: textGrey,
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // --- INPUT FIELDS ---
                    
                    // Username
                    _buildLabel('Username', textLabel),
                    TextFormField(
                      controller: _usernameController,
                      decoration: _inputDecoration('Enter your username', inputBorder, primaryBlue),
                      validator: (value) => value!.isEmpty ? 'Please enter your username' : null,
                    ),
                    const SizedBox(height: 16.0),

                    // Password
                    _buildLabel('Password', textLabel),
                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecoration('Enter your password', inputBorder, primaryBlue),
                      obscureText: true,
                      validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
                    ),
                    const SizedBox(height: 16.0),

                    // Confirm Password
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

                    // Email (Required for Runner)
                    _buildLabel('Email', textLabel),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('Enter your email', inputBorder, primaryBlue),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (_role == 'runner' && value!.isEmpty) return 'Please enter your email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // --- ROLE SELECTION ---
                    _buildLabel('Select Role', textLabel),
                    Row(
                      children: [
                        // Runner Option
                        GestureDetector(
                          onTap: () => setState(() => _role = 'runner'),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'runner',
                                groupValue: _role,
                                activeColor: primaryBlue,
                                onChanged: (val) => setState(() => _role = val!),
                              ),
                              Text('Runner', style: TextStyle(color: textLabel)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        // Organizer Option
                        GestureDetector(
                          onTap: () => setState(() => _role = 'event_organizer'),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'event_organizer',
                                groupValue: _role,
                                activeColor: primaryBlue,
                                onChanged: (val) => setState(() => _role = val!),
                              ),
                              Text('Event Organizer', style: TextStyle(color: textLabel)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // --- LOCATION DROPDOWN ---
                    // Menggunakan dropdown untuk kedua role demi konsistensi data, 
                    // tapi dilabeli "Base Location" atau "Location" sesuai konteks.
                    _buildLabel(_role == 'event_organizer' ? 'Base Location' : 'Location', textLabel),
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      hint: Text('Select your location', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                      decoration: _inputDecoration('', inputBorder, primaryBlue),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: _locations.map((String loc) {
                        return DropdownMenuItem<String>(
                          value: loc,
                          child: Text(loc),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedLocation = val),
                      validator: (value) => value == null ? 'Please select your location' : null,
                    ),
                    const SizedBox(height: 16.0),

                    // --- PROFILE PHOTO (Organizer Only) ---
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

                    // --- BUTTON ---
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // Logic Kirim Data
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
                              "http://localhost:8000/auth/register/", 
                              jsonEncode(data),
                            );

                            if (context.mounted) {
                              if (response['status'] == 'success') {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Successfully registered! Please login.'),
                                  backgroundColor: Colors.green,
                                ));
                                Navigator.pushReplacement(context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(response['message'] ?? 'Failed to register'),
                                  backgroundColor: Colors.red,
                                ));
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Error: $e"),
                                backgroundColor: Colors.red,
                              ));
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0), // Rounded tombol
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Create Account'),
                    ),

                    const SizedBox(height: 24.0),

                    // --- DIVIDER & FOOTER ---
                    Divider(color: Colors.grey[200], thickness: 1.5),
                    const SizedBox(height: 16.0),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(color: textGrey, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          child: Text(
                            "Sign In",
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  // Helper untuk Label di atas input
  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  // Helper untuk Style Input
  InputDecoration _inputDecoration(String hint, Color borderColor, Color focusColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: focusColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
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