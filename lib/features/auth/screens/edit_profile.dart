import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'dart:convert';

class EditProfilePage extends StatefulWidget {
  // Terima data saat ini agar form terisi otomatis
  final String currentUsername;
  final String currentLocation;

  const EditProfilePage({
    super.key, 
    required this.currentUsername,
    required this.currentLocation,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  String? _baseLocation;
  bool _isLoading = false;

  final List<String> locations = [
    'jakarta', 'surabaya', 'bandung', 'medan', 'semarang',
    'makassar', 'palembang', 'denpasar', 'yogyakarta',
    'surakarta', 'malang', 'pekanbaru', 'depok',
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
    
    // Set lokasi awal (case insensitive matching)
    if (widget.currentLocation.isNotEmpty && widget.currentLocation != '-') {
      try {
        _baseLocation = locations.firstWhere(
          (loc) => loc.toLowerCase() == widget.currentLocation.toLowerCase()
        );
      } catch (e) {
        _baseLocation = null;
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final request = context.read<CookieRequest>();
    setState(() => _isLoading = true);

    // --- URL ---
    final String url = ApiConfig.editProfile();

    try {
      // --- REQUEST ---
      final response = await request.postJson(
        url,
        jsonEncode({
          'username': _usernameController.text,
          'base_location': _baseLocation ?? '',
        }),
      );

      if (!mounted) return;

      // Cek status berdasarkan respon JSON dari api_edit_profile
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Colors.green),
        );
        
        // Kembalikan Map data, bukan cuma boolean
        Navigator.pop(context, {
          'new_username': _usernameController.text,
          'new_location': _baseLocation ?? '',
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal memperbarui profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username Field
              const Text("Username", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Enter username",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Username cannot be empty";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Location Dropdown
              const Text("Base Location", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _baseLocation,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                hint: const Text("Select location"),
                items: locations.map((loc) {
                  return DropdownMenuItem(
                    value: loc,
                    child: Text(loc[0].toUpperCase() + loc.substring(1)), // Capitalize
                  );
                }).toList(),
                onChanged: (val) => setState(() => _baseLocation = val),
              ),
              
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCDFA5D), // Warna Lime Green sesuai web
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}