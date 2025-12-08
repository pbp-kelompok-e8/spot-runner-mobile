import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/core/widgets/left_drawer.dart';

// Model sederhana untuk simulasi data pengguna
class UserProfile {
  final String username;
  final String baseLocation;
  final String joinedDate;
  final String lastLogin;
  final String passwordLength; // Hanya untuk simulasi panjang password
  final String profilePhotoUrl;

  UserProfile({
    required this.username,
    required this.baseLocation,
    required this.joinedDate,
    required this.lastLogin,
    this.passwordLength = '123456', // Default dummy
    this.profilePhotoUrl = '',
  });
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- SIMULASI DATA USER YANG SEDANG LOGIN ---
    final request = context.watch<CookieRequest>();
    // Menggunakan Map kosong jika request.jsonData adalah null untuk menghindari error
    final response = request.jsonData ?? {}; 

    final currentUser = UserProfile(
      username: response['username'] ?? 'RunnerDefault',
      baseLocation: response['base_location'] ?? 'Jakarta, Indonesia',
      joinedDate: response['joined'] ?? '2023-01-15',
      lastLogin: response['last_login'] ?? '2025-12-01 10:00:00',
    );

    // Definisi warna
    final Color primaryBlue = const Color(0xFF1D4ED8);
    final Color logoutGrey = const Color(0xFF9CA3AF);
    final Color deleteRed = const Color(0xFFDC2626);
    final Color badgeBg = const Color(0xFFFEF9C3);
    final Color badgeText = const Color(0xFFCA8A04);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "SpotRunner",
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.directions_run, color: primaryBlue),
          ],
        ),
      ),
      drawer: const LeftDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            width: double.infinity,
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
                // --- JUDUL ---
                const Center(
                  child: Text(
                    "Your Profile",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // --- BADGE ---
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Event Organizer",
                      style: TextStyle(
                        color: badgeText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // --- INFO DINAMIS (JOINED & LOGIN) ---
                _buildInfoText("Joined", currentUser.joinedDate),
                const SizedBox(height: 16),
                _buildInfoText("Last login", currentUser.lastLogin),
                const SizedBox(height: 24),

                // --- FORM FIELDS DINAMIS (READ-ONLY) ---
                _buildLabel("Username"),
                // Gunakan _buildTextField untuk tampilan read-only
                _buildTextField(initialValue: currentUser.username, readOnly: true),
                const SizedBox(height: 16),

                _buildLabel("Profile Photo URL"),
                _buildTextField(initialValue: currentUser.profilePhotoUrl.isEmpty ? "(Not set)" : currentUser.profilePhotoUrl, readOnly: true),
                const SizedBox(height: 16),

                _buildLabel("Base Location"),
                _buildTextField(initialValue: currentUser.baseLocation, readOnly: true),
                const SizedBox(height: 16),

                _buildLabel("Password"),
                // Gunakan tampilan read-only dengan teks tersembunyi
                _buildPasswordDisplay(currentUser.passwordLength),
                const SizedBox(height: 12),

                // --- FORGOT PASSWORD ---
                Row(
                  children: [
                    Text(
                      "Forget your password? ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Logika navigasi ke ganti password
                      },
                      child: Text(
                        "Change password",
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // --- TOMBOL ACTION ---

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
                    onPressed: () {
                      // Logika Log out
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

                // 2. EDIT PROFILE
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
                    onPressed: () {
                      // Logika navigasi ke halaman edit profile
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Navigasi ke Halaman Edit Profile (Belum diimplementasi)')),
                      );
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

                // --- DIVIDER PEMISAH ZONA BAHAYA ---
                Divider(color: Colors.grey[300], thickness: 1),
                const SizedBox(height: 20),

                // 3. DELETE ACCOUNT (ZONA BAHAYA)
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
                    onPressed: () {
                      // Logika delete account
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
        ),
      ),
    );
  }

  // Widget pembantu untuk menampilkan info statis (Joined, Last Login)
  Widget _buildInfoText(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Widget pembantu untuk menampilkan label di atas field
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF374151),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  // Widget pembantu untuk menampilkan field data (sekarang readOnly default true)
  Widget _buildTextField({
    String? initialValue,
    String? hintText,
    bool isObscure = false,
    bool readOnly = true, // <-- SETELAH INI MENJADI TRUE SECARA DEFAULT
  }) {
    return TextFormField(
      initialValue: initialValue,
      obscureText: isObscure,
      readOnly: readOnly, // <-- Kunci agar tidak bisa diubah
      style: TextStyle(color: readOnly ? Colors.black87 : Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          // Ubah warna border agar terlihat seperti read-only
          borderSide: BorderSide(color: Colors.grey.shade300), 
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          // Biarkan fokus border tetap normal, tapi readOnly akan mencegah keyboard muncul
          borderSide: BorderSide(color: readOnly ? Colors.grey.shade300 : Colors.blue.shade700),
        ),
        fillColor: Colors.white,
        filled: true,
      ),
    );
  }
  
  // Widget khusus untuk menampilkan password yang tersembunyi
  Widget _buildPasswordDisplay(String password) {
    // Membuat string tersembunyi (contoh: 8 karakter * )
    String hiddenText = '•' * password.length; 

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        hiddenText,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
    );
  }
}