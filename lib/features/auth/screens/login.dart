import 'package:spot_runner_mobile/core/screens/menu.dart';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/features/auth/screens/register.dart';
import 'package:spot_runner_mobile/core/providers/user_provider.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/core/widgets/error_retry.dart'; // Import Widget Error

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
  bool _isLoading = false;

  // Fungsi Login terpisah untuk memudahkan Retry
  Future<void> _handleLogin() async {
    // 1. Reset error & Validasi
    setState(() {
      _usernameError = null;
      _passwordError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final request = context.read<CookieRequest>();

    try {
      final response = await request.login(
        ApiConfig.login, 
        {
          'username': _usernameController.text,
          'password': _passwordController.text,
        },
      );

      if (!mounted) return;

      if (request.loggedIn) {
        String message = response['message'];
        String uname = response['username'];
        context.read<UserProvider>().setUsername(uname);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage()),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text("$message Welcome, $uname.")));
      } else {
        String message = response['message'] ?? 'Login failed';
        setState(() {
          if (message.toLowerCase().contains('password') && message.toLowerCase().contains('user')) {
            _usernameError = " ";
            _passwordError = message;
          } else if (message.toLowerCase().contains('akun') || message.toLowerCase().contains('account')) {
            _usernameError = message;
          } else {
            _passwordError = message;
          }
        });
        _formKey.currentState!.validate();
      }
    } catch (e) {
      // Tangani Error Koneksi (Wifi Mati)
      if (mounted) {
        showErrorRetryDialog(
          context: context,
          title: "Connection Error",
          message: "Unable to connect to server. Please check your internet connection.",
          onRetry: _handleLogin, // Panggil fungsi ini lagi jika Retry
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
                      style: TextStyle(fontSize: 14.0, color: textGrey),
                    ),
                    const SizedBox(height: 32.0),

                    _buildLabel('Username', textLabel),
                    TextFormField(
                      controller: _usernameController,
                      decoration: _inputDecoration('Enter your username', inputBorder, primaryBlue),
                      onChanged: (value) {
                        if (_usernameError != null) {
                          setState(() => _usernameError = null);
                          _formKey.currentState!.validate();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your username';
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
                          _formKey.currentState!.validate();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your password';
                        return _passwordError;
                      },
                    ),
                    const SizedBox(height: 32.0),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
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
                        : const Text('Sign In'),
                    ),

                    const SizedBox(height: 32.0),
                    Divider(color: Colors.grey[200], thickness: 1.5),
                    const SizedBox(height: 24.0),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: TextStyle(color: Colors.grey[600], fontSize: 14.0)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                          },
                          child: Text("Register Now", style: TextStyle(color: primaryBlue, fontSize: 14.0, fontWeight: FontWeight.bold)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: focusColor, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}