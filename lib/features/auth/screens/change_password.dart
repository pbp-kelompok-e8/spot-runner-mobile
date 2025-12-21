import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/core/widgets/error_retry.dart'; // Import Widget Error

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = context.read<CookieRequest>();
    final url = ApiConfig.changePassword();

    try {
      final response = await request.postJson(
        url,
        jsonEncode({
          'old_password': _oldPasswordController.text,
          'new_password1': _newPasswordController.text,
          'new_password2': _confirmPasswordController.text,
        }),
      );

      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password berhasil diubah!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? "Gagal mengubah password"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorRetryDialog(
          context: context,
          title: "Connection Error",
          message: "Failed to change password. Please check your internet connection.",
          onRetry: _handleSubmit,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ... (Sisa kode Widget _buildLabel dan _inputDecoration tetap sama) ...
  // Salin bagian bawah dari kode asli Anda di sini
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151), 
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {VoidCallback? onToggleVisibility, bool? isObscure}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      suffixIcon: onToggleVisibility != null
          ? IconButton(
              icon: Icon(isObscure! ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey[500], size: 20),
              onPressed: onToggleVisibility,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF1D4ED8);
    final Color bgPage = const Color(0xFFF3F4F6); 

    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.lock_reset_rounded, size: 40, color: primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("Update Password", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    const SizedBox(height: 8),
                    Text("Ensure your account is secure by using a strong password.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 32),

                    _buildLabel("Current Password"),
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: _obscureOld,
                      decoration: _inputDecoration("Enter current password", isObscure: _obscureOld, onToggleVisibility: () => setState(() => _obscureOld = !_obscureOld)),
                      validator: (val) => val!.isEmpty ? "Current password is required" : null,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("New Password"),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      decoration: _inputDecoration("Enter new password", isObscure: _obscureNew, onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew)),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "New password is required";
                        if (val.length < 8) return "Password must be at least 8 characters";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("Confirm New Password"),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: _inputDecoration("Re-enter new password", isObscure: _obscureConfirm, onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                      validator: (val) {
                        if (val!.isEmpty) return "Confirmation is required";
                        if (val != _newPasswordController.text) return "Passwords do not match";
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), elevation: 0),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                      child: const Text("Cancel"),
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
}