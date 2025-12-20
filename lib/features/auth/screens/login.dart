import 'package:spot_runner_mobile/core/screens/menu.dart';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/features/auth/screens/register.dart';
import 'package:spot_runner_mobile/core/providers/user_provider.dart';

void main() {
  runApp(const LoginApp());
}

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D4ED8),
          background: const Color(0xFFF3F4F6),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _usernameError;
  String? _passwordError;

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
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
                    Text(
                      'Sign In',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Hello, welcome back to Spot Runner!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: textGrey,
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // --- FORM INPUTS ---
                    
                    _buildLabel('Username', textLabel),
                    TextFormField(
                      controller: _usernameController,
                      decoration: _inputDecoration('Enter your username', inputBorder, primaryBlue),
                      onChanged: (value) {
                        if (_usernameError != null) {
                          setState(() => _usernameError = null);
                          _formKey.currentState!.validate(); // Hapus merah saat ketik
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return _usernameError;
                      },
                    ),
                    
                    const SizedBox(height: 20.0),

                    _buildLabel('Password', textLabel),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: _inputDecoration('Enter your password', inputBorder, primaryBlue),
                      onChanged: (value) {
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                          _formKey.currentState!.validate(); // Hapus merah saat ketik
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return _passwordError;
                      },
                    ),

                    const SizedBox(height: 32.0),

                    // --- BUTTON ---
                    ElevatedButton(
                      onPressed: () async {
                        // 1. Reset error state
                        setState(() {
                          _usernameError = null;
                          _passwordError = null;
                        });

                        // 2. Validasi lokal (kosong atau tidak)
                        if (_formKey.currentState!.validate()) {
                          String username = _usernameController.text;
                          String password = _passwordController.text;

                          final response = await request.login(
                              "http://localhost:8000/auth/login/", {
                            'username': username,
                            'password': password,
                          });

                          if (request.loggedIn) {
                            String message = response['message'];
                            String uname = response['username'];

                            context.read<UserProvider>().setUsername(uname);

                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MyHomePage()),
                              );
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(content: Text("$message Welcome, $uname.")),
                                );
                            }
                          } else {
                            if (context.mounted) {
                              String message = response['message'] ?? 'Login failed';
                              
                              setState(() {
                                // --- LOGIKA BARU UNTUK UI ---
                                
                                // Cek pesan spesifik dari Backend (views.py: "Username atau password salah.")
                                // Atau pesan default Django "Please enter a correct username and password"
                                if (message.toLowerCase().contains('password') && message.toLowerCase().contains('user')) {
                                  // Jika error menyebut keduanya, nyalakan merah di KEDUA kolom
                                  _usernameError = " "; // Spasi kosong agar border merah tapi teks tidak double
                                  _passwordError = message; // Pesan lengkap ditaruh di bawah password
                                } 
                                // Jika error spesifik (misal "Akun dinonaktifkan")
                                else if (message.toLowerCase().contains('akun') || message.toLowerCase().contains('account')) {
                                    _usernameError = message;
                                }
                                // Fallback error
                                else {
                                  _passwordError = message;
                                }
                              });
                              
                              _formKey.currentState!.validate();
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
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Sign In'),
                    ),

                    const SizedBox(height: 32.0),

                    Divider(
                      color: Colors.grey[200],
                      thickness: 1.5,
                    ),

                    const SizedBox(height: 24.0),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14.0,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const RegisterPage()),
                            );
                          },
                          child: Text(
                            "Register Now",
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
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

  InputDecoration _inputDecoration(String hint, Color borderColor, Color focusColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0, vertical: 14.0),
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
}