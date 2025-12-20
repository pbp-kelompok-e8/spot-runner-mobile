import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/core/models/user_entry.dart';
import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:spot_runner_mobile/core/screens/menu.dart'; // For navigation to Home
import 'package:intl/intl.dart';

class RunnerProfilePage extends StatefulWidget {
  const RunnerProfilePage({super.key, required this.username});
  final String username;

  @override
  State<RunnerProfilePage> createState() => _RunnerProfilePageState();
}

class _RunnerProfilePageState extends State<RunnerProfilePage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfileData();
    });
  }

  /* ===================== FETCH PROFILE ===================== */

  Future<void> _fetchProfileData() async {
    final request = context.read<CookieRequest>();

    try {
      final response = await request.get(
        'http://127.0.0.1:8000/api/runner-profile/',
      );

      if (!mounted) return;

      if (response['status'] == 'success') {
        setState(() {
          _profileData = response;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to load profile')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /* ===================== LOGOUT ===================== */

  Future<void> _handleLogout(
    BuildContext context,
    CookieRequest request,
  ) async {
    try {
      final response = await request.logout(
        "http://127.0.0.1:8000/auth/logout/",
      );

      if (!context.mounted) return;

      final bool success = response['status'] == true ||
    response['message']?.toString().toLowerCase().contains('logout') == true;
      final String message = response['message'] ?? 'Logout failed';
      final String username = response['username'] ?? '';

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$message Sampai jumpa, $username.")),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /* ===================== DELETE ACCOUNT ===================== */

  Future<void> _handleDeleteAccount(
    BuildContext context,
    CookieRequest request,
  ) async {
    try {
      final response = await request.post(
        "http://127.0.0.1:8000/event-organizer/delete-account-flutter/",
        {},
      );

      if (!context.mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Delete failed')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /* ===================== UI ===================== */

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    const Color primaryBlue = Color(0xFF1D4ED8);
    const Color bgPage = Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBlue,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchProfileData,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
              ? const Center(child: Text("Failed to load profile"))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(primaryBlue),
                      const SizedBox(height: 20),
                      _buildDetails(primaryBlue),
                      const SizedBox(height: 30),

                      /* LOGOUT */
                      OutlinedButton.icon(
                        onPressed: () => _handleLogout(context, request),
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /* DELETE ACCOUNT */
                      OutlinedButton.icon(
                        onPressed: () => _handleDeleteAccount(context, request),
                        icon: const Icon(Icons.delete),
                        label: const Text("Delete Account"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: () {
                        // Open review modal
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCDFA5D),
                        foregroundColor: Colors.black87,
                        elevation: 0,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(Color primaryBlue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              _profileData!['username'][0].toUpperCase(),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _profileData!['username'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _profileData!['email'],
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(Color primaryBlue) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _infoRow("Weight", "${_profileData!['weight']} kg"),
          _infoRow("Height", "${_profileData!['height']} cm"),
          _infoRow("Gender", _profileData!['gender'] ?? "-"),
          _infoRow("Location", _profileData!['base_location'] ?? "-"),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
