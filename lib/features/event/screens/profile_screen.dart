import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import 'package:spot_runner_mobile/core/widgets/left_drawer.dart';
import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:spot_runner_mobile/features/auth/screens/change_password.dart';
import 'package:spot_runner_mobile/features/auth/screens/edit_profile.dart';

// UBAH JADI STATEFUL WIDGET AGAR BISA SETSTATE
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  // Fungsi fetch dipisah agar bisa dipanggil ulang
  Future<Map<String, dynamic>> fetchProfile(CookieRequest request) async {
    final response = await request.get(
      'http://127.0.0.1:8000/event-organizer/profile/json/',
    );
    return response;
  }

  // Method untuk refresh halaman
  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    const Color primaryBlue = Color(0xFF1D4ED8);
    const Color logoutGrey = Color(0xFF9CA3AF);
    const Color deleteRed = Color(0xFFDC2626);
    const Color badgeBg = Color(0xFFFEF9C3);
    const Color badgeText = Color(0xFFCA8A04);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              "SpotRunner",
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.directions_run, color: primaryBlue),
          ],
        ),
      ),
      drawer: const LeftDrawer(),

      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchProfile(request), // Memanggil fungsi fetch
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No profile data found"));
          }

          // Handle struktur data: cek apakah ada key 'data' atau langsung di root
          final dataRaw = snapshot.data!;
          final profile = dataRaw.containsKey('data') ? dataRaw['data'] : dataRaw;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Your Profile",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== PHOTO PROFILE =====
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          profile['profile_picture'] != null &&
                                  profile['profile_picture']
                                      .toString()
                                      .isNotEmpty
                              ? NetworkImage(profile['profile_picture'])
                              : null,
                      child: profile['profile_picture'] == null ||
                              profile['profile_picture']
                                  .toString()
                                  .isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== BADGE =====
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Event Organizer",
                        style: TextStyle(
                          color: badgeText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  _infoText("Joined", profile['joined'] ?? '-'),
                  const SizedBox(height: 16),
                  _infoText("Last login", profile['last_login'] ?? "-"),

                  const SizedBox(height: 24),

                  _label("Username"),
                  _display(profile['username'] ?? '-'),
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

                  Row(
                    children: [
                      Text(
                        "Forget your password? ",
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
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
                            color: primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 1. LOG OUT
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: logoutGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final request = context.read<CookieRequest>();
                        try {
                          await request.logout(
                              "http://127.0.0.1:8000/auth/logout/");
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                            (_) => false,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Logged out successfully')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logout error: $e')),
                          );
                        }
                      },
                      child: const Text(
                        "Log out",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. EDIT PROFILE (BAGIAN PENTING)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        // Gunakan 'await' untuk menunggu hasil dari halaman Edit
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const EditProfilePage()),
                        );

                        // Jika result == true (berhasil simpan), refresh halaman ini
                        if (result == true) {
                          refresh(); 
                        }
                      },
                      child: const Text(
                        "Edit Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Divider(color: Colors.grey[300], thickness: 1),
                  const SizedBox(height: 20),

                  // 3. DELETE ACCOUNT
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: deleteRed, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Account'),
                            content: const Text(
                                'Are you sure you want to delete your account? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  child: const Text('Delete',
                                      style:
                                          TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (shouldDelete != true) return;

                        final request = context.read<CookieRequest>();
                        const String deleteUrl =
                            'http://127.0.0.1:8000/event-organizer/delete-account-flutter/';
                        try {
                          final resp = await request.post(deleteUrl, {});
                          if (resp != null &&
                              resp['status'] == 'success') {
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const LoginPage()),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Account deleted')),
                              );
                            }
                          } else {
                            final msg = resp != null &&
                                    resp['message'] != null
                                ? resp['message']
                                : 'Failed to delete account';
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)));
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_forever, color: deleteRed),
                          const SizedBox(width: 8),
                          Text(
                            "Delete Account",
                            style: TextStyle(
                              color: deleteRed,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== Helper =====
  Widget _infoText(String label, String value) {
    return Column(
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
  }

  Widget _label(String text) => Text(text,
      style:
          const TextStyle(fontWeight: FontWeight.w500, fontSize: 14));

  Widget _display(String value) => Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(value, style: const TextStyle(fontSize: 16)),
      );
}