import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:spot_runner_mobile/features/auth/screens/change_password.dart';
import 'package:spot_runner_mobile/core/screens/menu.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/features/auth/screens/edit_profile.dart'; // Sesuaikan path jika beda
import 'package:spot_runner_mobile/core/providers/user_provider.dart';

class RunnerProfilePage extends StatefulWidget {
  const RunnerProfilePage({super.key, required this.username});
  final String username;

  @override
  State<RunnerProfilePage> createState() => _RunnerProfilePageState();
}

class _RunnerProfilePageState extends State<RunnerProfilePage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  late String _currentUsername;

  // --- COLORS ---
  final Color _primaryBlue = const Color(0xFF1447E6);
  final Color _textDark = const Color(0xFF393938);
  final Color _textGrey = const Color(0xFF777675);
  final Color _limeGreen = const Color(0xFFA0E228); // Warna Tombol Save Web

  @override
  void initState() {
    super.initState();
    _currentUsername = widget.username;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfileData();
    });
  }

  Future<void> _fetchProfileData() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get(ApiConfig.userProfile(_currentUsername));
      
      if (mounted) {
        setState(() {
          if (response['status'] == 'success') {
            _profileData = response;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? "Failed to load profile")),
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  // --- MODAL EDIT PROFILE (Mirip Web) ---
  void _showEditProfileModal(BuildContext context, String currentUsername, String currentLocation) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController usernameController = TextEditingController(text: currentUsername);
    // Menggunakan value untuk dropdown
    String? selectedLocation = currentLocation;

    // Daftar Lokasi (Sesuai models.py)
    final List<Map<String, String>> locations = [
      {'value': 'jakarta_barat', 'display': 'Jakarta Barat'},
      {'value': 'jakarta_timur', 'display': 'Jakarta Timur'},
      {'value': 'jakarta_utara', 'display': 'Jakarta Utara'},
      {'value': 'jakarta_selatan', 'display': 'Jakarta Selatan'},
      {'value': 'jakarta_pusat', 'display': 'Jakarta Pusat'},
      {'value': 'bekasi', 'display': 'Bekasi'},
      {'value': 'tangerang', 'display': 'Tangerang'},
      {'value': 'bogor', 'display': 'Bogor'},
      {'value': 'depok', 'display': 'Depok'},
    ];

    // Pastikan lokasi saat ini ada di list, jika tidak default ke null
    if (!locations.any((loc) => loc['value'] == selectedLocation)) {
      selectedLocation = null;
    }

    bool isSaving = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Modal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Edit Your Profile",
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.w600, 
                              color: Color(0xFF111827)
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.grey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Username Input
                      const Text(
                        "Username",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _primaryBlue, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Username cannot be empty";
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),

                      // Location Select (Dropdown)
                      const Text(
                        "Base Location",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedLocation,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _primaryBlue, width: 2),
                          ),
                        ),
                        items: locations.map((loc) {
                          return DropdownMenuItem(
                            value: loc['value'],
                            child: Text(loc['display']!),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedLocation = val;
                          });
                        },
                        validator: (val) => val == null ? "Please select a location" : null,
                      ),

                      const SizedBox(height: 32),

                      // Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cancel Button
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              foregroundColor: const Color(0xFF374151), // Text Gray
                            ),
                            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 12),
                          // Save Button (Warna Hijau Stabilo)
                          ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              if (formKey.currentState!.validate()) {
                                setState(() => isSaving = true);
                                
                                final request = context.read<CookieRequest>();
                                
                                try {
                                  final response = await request.postJson(
                                    ApiConfig.editProfile(),
                                    jsonEncode({
                                      "username": usernameController.text,
                                      "base_location": selectedLocation
                                    })
                                  );

                                  if (mounted) {
                                    Navigator.pop(context); // Tutup modal
                                    if (response['status'] == 'success') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green)
                                      );
                                      _fetchProfileData(); // Refresh data halaman
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(response['message'] ?? "Failed to update"), backgroundColor: Colors.red)
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _limeGreen, // #A0E228
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: isSaving 
                              ? const SizedBox(
                                  width: 20, height: 20, 
                                  child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2)
                                )
                              : const Text("Save Changes", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- ACTIONS ---

  Future<void> _handleLogout() async {
    final request = context.read<CookieRequest>();

    try {
      final response = await request.logout(ApiConfig.logout);
      if (context.mounted) {
        if (response['status'] == true) {
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Logged out successfully!")),
          );
        }
      }
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _handleDeleteAccount() async {
    final TextEditingController passwordController = TextEditingController();
    final request = context.read<CookieRequest>();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tindakan ini permanen. Masukkan password Anda untuk konfirmasi:', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: errorMessage,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: isLoading ? null : () async {
                    if (passwordController.text.isEmpty) {
                        setState(() => errorMessage = "Password tidak boleh kosong.");
                        return;
                    }
                    setState(() { isLoading = true; errorMessage = null; });

                    final url = ApiConfig.deleteAccount();

                    try {
                      final response = await request.postJson(url, jsonEncode({'password': passwordController.text}));
                      if (context.mounted) {
                        if (response['status'] == 'success') {
                          Navigator.pop(context);
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Akun berhasil dihapus."), backgroundColor: Colors.green));
                        } else {
                          setState(() { isLoading = false; errorMessage = response['message'] ?? "Password salah."; });
                        }
                      }
                    } catch (e) {
                      if (context.mounted) setState(() { isLoading = false; errorMessage = "Terjadi kesalahan koneksi."; });
                    }
                  },
                  child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- HELPERS FORMATTING ---
  
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty || dateStr == '-' || dateStr == 'Never') return dateStr;
    try {
      final DateTime parsed = DateTime.parse(dateStr);
      final DateFormat formatter = DateFormat('d MMM yyyy');
      return formatter.format(parsed);
    } catch (e) {
      return dateStr; 
    }
  }

  String _formatLastLogin(String dateStr) {
    if (dateStr.isEmpty || dateStr == '-' || dateStr == 'Never') return dateStr;
    try {
      final DateTime parsed = DateTime.parse(dateStr);
      final DateFormat formatter = DateFormat("MMMM d, yyyy 'at' hh:mm a");
      return formatter.format(parsed);
    } catch (e) {
      return dateStr; 
    }
  }

  String _formatString(String? value) {
    if (value == null || value.isEmpty || value == '-') return '-';
    String text = value.replaceAll('_', ' ');
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // ==================== WIDGETS UI ====================

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFBFBFB),
            border: Border.all(color: const Color(0xFFD7D5D3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: _textGrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(String username, String location, String lastLogin) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 35,
            offset: const Offset(-35, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Your Profile",
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Text(
              "Runner",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF016630),
              ),
            ),
          ),
          
          const SizedBox(height: 32),

          // Fields Area
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  "Last login: ${_formatLastLogin(lastLogin)}", 
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              _buildField("Username", username),
              const SizedBox(height: 20),
              _buildField("Location", _formatString(location)),
              const SizedBox(height: 20),
              _buildField("Password", "........"),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  "Forgot your password? ",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: _textDark),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordPage()));
                  },
                  child: Text(
                    "Change password",
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: _primaryBlue),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    String cleanLocation = (location == 'Not set' || location == '-') ? '' : location;

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(
                          currentUsername: _currentUsername, // Gunakan variabel lokal
                          currentLocation: cleanLocation,
                        ),
                      ),
                    );

                    // PERBAIKAN LOGIKA UPDATE
                    if (result != null && result is Map) {
                      String newName = result['new_username'];
                      String newLoc = result['new_location'];

                      // 1. Update Global State (Provider)
                      // Agar Drawer dan halaman lain tahu username sudah ganti
                      context.read<UserProvider>().setUsername(newName);

                      // 2. Update Local State (UI Profile saat ini)
                      setState(() {
                        _currentUsername = newName;
                        _profileData!['base_location'] = newLoc;
                        // Update widget.username tidak bisa dilakukan karena final, 
                        // tapi _currentUsername sudah cukup untuk fetch ulang.
                      });
                      
                      // 3. Refresh data dari server dengan username BARU
                      _fetchProfileData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _handleLogout,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF99A1AF),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Log out", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _handleDeleteAccount,
                  child: const Text("Delete Account", style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventDataRow(String label, String value, {bool isStatus = false}) {
    String displayValue = value;
    if (label == 'Location' || label == 'Type') {
      displayValue = _formatString(value);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayValue,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildEventCard(dynamic record, dynamic event, String status, String eventStatus, String category, String participantId) {
    Color cardBg;
    Color cardBorder;
    Color badgeBg;
    Color badgeText;
    String statusLabel;

    if (status == 'canceled') {
      cardBg = const Color(0xFFFEF2F2);
      cardBorder = const Color(0xFFFB2C36);
      badgeBg = const Color(0xFFFFC9C9);
      badgeText = const Color(0xFF82181A);
      statusLabel = "Canceled";
    } else if (status == 'finished') {
      cardBg = const Color(0xFFF0FDF4);
      cardBorder = const Color(0xFF00C951);
      badgeBg = const Color(0xFFB9F8CF);
      badgeText = const Color(0xFF0D542B);
      statusLabel = "Finished";
    } else { 
      cardBg = const Color(0xFFEFF6FF);
      cardBorder = const Color(0xFF2B7FFF);
      badgeBg = const Color(0xFFBEDBFF);
      badgeText = const Color(0xFF1C398E);
      statusLabel = "On Going";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: cardBorder, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['name'] ?? "Unknown Event",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                       _formatString(event['location_display']),
                       style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    )
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: badgeText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1, color: Color(0xFFD1D5DC)),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventDataRow("Date", _formatDate(event['event_date'] ?? '')),
              const SizedBox(height: 12),
              _buildEventDataRow("Location", event['location_display'] ?? '-'),
              const SizedBox(height: 12),
              _buildEventDataRow("Type", category),
              const SizedBox(height: 12),
              _buildEventDataRow("Participant ID", participantId), 
            ],
          ),

          const SizedBox(height: 24),
          
          if (status == 'attending') 
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _showCancelConfirmation(event['id'], event['name']),
                icon: const Icon(Icons.delete_outline, color: Color(0xFFE7000B)),
                label: const Text("Cancel Booking", style: TextStyle(color: Color(0xFFE7000B), fontSize: 15, fontWeight: FontWeight.w500)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  side: const BorderSide(color: Color(0xFFFB2C36)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          if (status == 'finished' && record['review'] == null)
              SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.star_outline, color: Color(0xFF35530E)),
                label: const Text("Rate this event", style: TextStyle(color: Color(0xFF35530E), fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _limeGreen, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Cancel Modal Logic ---
  Future<void> _showCancelConfirmation(String? eventId, String? eventName) async {
    if (eventId == null) return;
    
    _showWebStyleConfirmationDialog(
      title: "Are you sure you want to cancel?",
      message: "You'll lose your spot in ${eventName ?? 'this event'}.",
      confirmText: "Cancel Booking",
      confirmColor: Colors.red,
      onConfirm: () => _handleCancelEvent(eventId),
    );
  }

  void _showWebStyleConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close, size: 20, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF111827)
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14, 
                  color: Color(0xFF6B7280)
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Color(0xFF374151))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(confirmText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCancelEvent(String? eventId) async {
      final request = context.read<CookieRequest>();
      try {
        final response = await request.post(ApiConfig.cancelParticipation(widget.username, eventId!), {});
        if (mounted && response['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message']), backgroundColor: Colors.green));
            _fetchProfileData(); 
        } else {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? "Failed to cancel"), backgroundColor: Colors.red));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final userData = _profileData!;
    final username = userData['username'] ?? 'User';
    final location = userData['base_location'] ?? 'Not set';
    final lastLogin = userData['last_login'] != null 
        ? userData['last_login'].toString()
        : 'Never'; 
    final List attendanceList = userData['attendance_list'] ?? [];
    
    final List reviewList = userData['user_reviews'] ?? []; 

    return PopScope(
      canPop: false, // Kita handle pop secara manual
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Saat user tekan back, kirim username terbaru ke halaman sebelumnya (Home)
        Navigator.pop(context, _currentUsername);
      },
    child: Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text(
          "SpotRunner",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            fontSize: 18,
            color: _primaryBlue,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(username, location, lastLogin),
            
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Event History",
                  style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 24, color: _textDark),
                ),
                ElevatedButton(
                  onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  child: const Text("+ Join New Event", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                )
              ],
            ),
            const SizedBox(height: 20),

            if (attendanceList.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("You haven't joined any events yet.", style: TextStyle(color: Colors.grey))))
            else
              ...attendanceList.map((record) => _buildEventCard(
                  record, 
                  record['event'], 
                  record['status'], 
                  record['event']['event_status'],
                  record['category'] ?? '-',
                  record['participant_id']?.toString() ?? '-'
              )),

            const SizedBox(height: 40),
            
            Text(
              "Your Review",
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 24, color: _textDark),
            ),
            const SizedBox(height: 20),
            
            if (reviewList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6), 
                  border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    "You haven't written any reviews yet.",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              )
            else
                Column(
                  children: reviewList.map((review) => Text("Review Item (Implement later)")).toList(),
                )
          ],
        ),
      ),
    )
    );
  }
}