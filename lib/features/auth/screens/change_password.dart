import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
// Pastikan import ini sesuai dengan struktur project Anda
// import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:spot_runner_mobile/features/event/screens/profile_screen.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _loading = false;

  static const String changePasswordUrl =
      'http://127.0.0.1:8000/event-organizer/change-password-flutter/';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New passwords do not match')));
      return;
    }

    setState(() => _loading = true);
    final request = context.read<CookieRequest>();

    try {
      final response = await request.post(changePasswordUrl, {
        'old_password': _oldController.text,
        'new_password1': _newController.text,
        'new_password2': _confirmController.text,
      });

      if (!mounted) return;

      if (response != null && response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password changed successfully')));
            
        // --- BAGIAN YANG DIUBAH ---
        // Mengarahkan ke ProfilePage dan menghapus halaman Change Password dari stack
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()), 
          // Ganti 'ProfilePage' dengan nama class halaman profile Anda
        );
        // --------------------------
        
      } else {
        final message = response != null && response['message'] != null
            ? response['message']
            : 'Failed to change password';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Helper widget untuk membuat input field sesuai desain gambar
  Widget _buildCustomTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: true,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF1D4ED8)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Warna biru utama sesuai gambar
    final Color primaryBlue = const Color(0xFF1D4ED8);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Header ---
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A), // Dark blue/black
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Update your account password',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- Input Fields ---
                  _buildCustomTextField(
                    label: 'Current Password',
                    hint: 'Enter your current password',
                    controller: _oldController,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Please enter old password'
                        : null,
                  ),
                  _buildCustomTextField(
                    label: 'New Password',
                    hint: 'Enter your new password',
                    controller: _newController,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Please enter new password'
                        : null,
                  ),
                  _buildCustomTextField(
                    label: 'Confirm New Password',
                    hint: 'Confirm your new password',
                    controller: _confirmController,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Please confirm new password'
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // --- Submit Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- Back Button ---
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Back to Profile',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}