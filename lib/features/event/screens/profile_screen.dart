import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:spot_runner_mobile/core/widgets/left_drawer.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/core/widgets/error_handler.dart';

import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:spot_runner_mobile/features/auth/screens/change_password.dart';
import 'package:spot_runner_mobile/features/auth/screens/edit_profile.dart';
import 'package:spot_runner_mobile/features/auth/screens/edit_profile_eo.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    final request = context.read<CookieRequest>();

    try {
      final response =
          await request.get(ApiConfig.eventOrganizerProfile());

      final data =
          response.containsKey('data') ? response['data'] : response;

      if (!mounted) return;

      setState(() {
        _profile = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      context.read<ConnectivityProvider>().setError(
        "Gagal memuat profil. Periksa koneksi internet Anda.",
        _loadProfile,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final role = request.jsonData['role'] ?? '';
    final isRunner = role.toLowerCase() == 'runner';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: _buildAppBar(),
      drawer: const LeftDrawer(),
      body: _buildBody(isRunner),
    );
  }

  Widget _buildBody(bool isRunner) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profile == null) {
      return const Center(
        child: Text(
          "Data profil tidak tersedia.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final profile = _profile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Your Profile",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            _buildAvatar(profile),
            const SizedBox(height: 16),
            _buildBadge(),
            const SizedBox(height: 30),

            _infoText("Joined", profile['joined'] ?? "-"),
            const SizedBox(height: 16),
            _infoText("Last login", profile['last_login'] ?? "-"),
            const SizedBox(height: 24),

            _label("Username"),
            _display(profile['username'] ?? "-"),
            const SizedBox(height: 16),

            _label("Profile Photo URL"),
            _display(profile['profile_picture'] ?? "(Not set)"),
            const SizedBox(height: 16),

            _label("Base Location"),
            _display(profile['base_location'] ?? "-"),
            const SizedBox(height: 16),

            _label("Password"),
            _display("••••••••"),
            const SizedBox(height: 12),

            _buildChangePassword(context),
            const SizedBox(height: 30),

            _buildLogoutButton(context),
            const SizedBox(height: 16),

            if (!isRunner) _buildEditProfileButton(context, isRunner),

            const SizedBox(height: 40),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 20),

            _buildDeleteAccountButton(context),
          ],
        ),
      ),
    );
  }

  // ================= UI =================

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              "SpotRunner",
              style: TextStyle(
                color: Color(0xFF1D4ED8),
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.directions_run, color: Color(0xFF1D4ED8)),
          ],
        ),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      );

  Widget _buildAvatar(Map<String, dynamic> profile) {
    final img = profile['profile_picture'];
    return Center(
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey.shade200,
        backgroundImage:
            img != null && img.toString().isNotEmpty ? NetworkImage(img) : null,
        child: img == null || img.toString().isEmpty
            ? const Icon(Icons.person, size: 50, color: Colors.grey)
            : null,
      ),
    );
  }

  Widget _buildBadge() => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9C3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "Event Organizer",
            style: TextStyle(
              color: Color(0xFFCA8A04),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

  Widget _buildChangePassword(BuildContext context) => Row(
        children: [
          Text("Forget your password? ",
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordPage(),
                ),
              );
            },
            child: const Text(
              "Change password",
              style: TextStyle(
                color: Color(0xFF1D4ED8),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );

  Widget _buildLogoutButton(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9CA3AF),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            final request = context.read<CookieRequest>();
            try {
              await request.logout(ApiConfig.logout);
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            } catch (_) {
              context.read<ConnectivityProvider>().setError(
                "Gagal logout. Periksa koneksi internet Anda.",
                () {},
              );
            }
          },
          child: const Text("Log out",
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      );

  Widget _buildEditProfileButton(BuildContext context, bool isRunner) =>
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D4ED8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    isRunner ? const EditProfilePage(currentUsername: "ayay", currentLocation: "babi",) : const EditEOProfilePage(),
              ),
            );
            if (updated == true) _loadProfile();
          },
          child: const Text("Edit Profile",
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      );

  Widget _buildDeleteAccountButton(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFDC2626), width: 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            final request = context.read<CookieRequest>();
            try {
              final resp =
                  await request.post(ApiConfig.deleteAccountUrl(), {});
              if (resp != null && resp['status'] == 'success') {
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            } catch (_) {
              context.read<ConnectivityProvider>().setError(
                "Gagal menghapus akun. Periksa koneksi internet Anda.",
                () {},
              );
            }
          },
          child: const Text(
            "Delete Account",
            style: TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

  // ================= HELPERS =================

  Widget _infoText(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      );

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontSize: 14));

  Widget _display(String value) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(value, style: const TextStyle(fontSize: 16)),
      );
}
