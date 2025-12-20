import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/core/models/user_entry.dart';
import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:spot_runner_mobile/features/auth/screens/change_password.dart';
import 'package:spot_runner_mobile/core/screens/menu.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class RunnerProfilePage extends StatefulWidget {
  const RunnerProfilePage({super.key, required this.username});
  final String username;

  @override
  State<RunnerProfilePage> createState() => _RunnerProfilePageState();
}

class _RunnerProfilePageState extends State<RunnerProfilePage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  // --- COLORS FROM CSS ---
  final Color _primaryBlue = const Color(0xFF1447E6);
  final Color _textDark = const Color(0xFF393938);
  final Color _textGrey = const Color(0xFF777675);
  final Color _fieldBg = const Color(0xFFFBFBFB);
  final Color _fieldBorder = const Color(0xFFD7D5D3);
  final Color _limeGreen = const Color(0xFFCDFA5D);
  
  // Status Colors
  final Color _statusGoingBg = const Color(0xFFEFF6FF);
  final Color _statusGoingBorder = const Color(0xFF2B7FFF);
  final Color _statusGoingBadgeBg = const Color(0xFFBEDBFF);
  final Color _statusGoingBadgeText = const Color(0xFF1C398E);

  final Color _statusFinishedBg = const Color(0xFFF0FDF4);
  final Color _statusFinishedBorder = const Color(0xFF00C951);
  final Color _statusFinishedBadgeBg = const Color(0xFFB9F8CF);
  final Color _statusFinishedBadgeText = const Color(0xFF0D542B);

  final Color _statusCanceledBg = const Color(0xFFFEF2F2);
  final Color _statusCanceledBorder = const Color(0xFFFB2C36);
  final Color _statusCanceledBadgeBg = const Color(0xFFFFC9C9);
  final Color _statusCanceledBadgeText = const Color(0xFF82181A);

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
      String baseUrl = "http://10.0.2.2:8000";
      if (kIsWeb) {
        baseUrl = "http://localhost:8000";
      }
      
      final response = await request.get('$baseUrl/${widget.username}/json');
      
      if (mounted) {
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

  Future<void> _handleLogout() async {
    final request = context.read<CookieRequest>();
    String baseUrl = kIsWeb ? "http://localhost:8000" : "http://10.0.2.2:8000";

    try {
      final response = await request.logout("$baseUrl/auth/logout/");
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _primaryBlue, width: 2.0)),
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

                    String baseUrl = kIsWeb ? "http://localhost:8000" : "http://10.0.2.2:8000";
                    final url = "$baseUrl/api/delete-account/";

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

  // --- Helpers: Formatting ---
  
  // 1. Format Tanggal Event (31 Dec 2025)
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

  // 2. Format Last Login (December 20, 2025 at 04:24 PM)
  String _formatLastLogin(String dateStr) {
    if (dateStr.isEmpty || dateStr == '-' || dateStr == 'Never') return dateStr;
    try {
      final DateTime parsed = DateTime.parse(dateStr);
      // Pattern: Full Month Day, Year 'at' Hour:Minute AM/PM
      final DateFormat formatter = DateFormat("MMMM d, yyyy 'at' hh:mm a");
      return formatter.format(parsed);
    } catch (e) {
      return dateStr; 
    }
  }

  // 3. Format String (jakarta_selatan -> Jakarta Selatan)
  String _formatString(String? value) {
    if (value == null || value.isEmpty || value == '-') return '-';
    String text = value.replaceAll('_', ' ');
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // ==================== WIDGETS ====================

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
            color: _fieldBg,
            border: Border.all(color: _fieldBorder),
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
              // Last Login Text (Using specific formatter)
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
              // Format Location (jakarta_selatan -> Jakarta Selatan)
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
                  onPressed: () {}, 
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

  Widget _buildEventCard(dynamic record, dynamic event, String status, String eventStatus) {
    Color cardBg;
    Color cardBorder;
    Color badgeBg;
    Color badgeText;
    String statusLabel;

    if (status == 'canceled') {
      cardBg = _statusCanceledBg;
      cardBorder = _statusCanceledBorder;
      badgeBg = _statusCanceledBadgeBg;
      badgeText = _statusCanceledBadgeText;
      statusLabel = "Canceled";
    } else if (status == 'finished') {
      cardBg = _statusFinishedBg;
      cardBorder = _statusFinishedBorder;
      badgeBg = _statusFinishedBadgeBg;
      badgeText = _statusFinishedBadgeText;
      statusLabel = "Finished";
    } else { 
      cardBg = _statusGoingBg;
      cardBorder = _statusGoingBorder;
      badgeBg = _statusGoingBadgeBg;
      badgeText = _statusGoingBadgeText;
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

          // SEMUA DATA DALAM SATU KOLOM
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventDataRow("Date", _formatDate(event['event_date'] ?? '')),
              const SizedBox(height: 12),
              _buildEventDataRow("Location", event['location_display'] ?? '-'),
              const SizedBox(height: 12),
              _buildEventDataRow("Type", record['category'] ?? '-'),
              const SizedBox(height: 12),
              _buildEventDataRow("Participant ID", record['participant_id']?.toString() ?? '-'), 
            ],
          ),

          const SizedBox(height: 24),
          
          // Action Buttons
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

  Future<void> _showCancelConfirmation(String? eventId, String? eventName) async {
    if (eventId == null) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            "Are you sure you want to cancel?",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF111827)),
            textAlign: TextAlign.center,
          ),
          content: Text(
            "You'll lose your spot in ${eventName ?? 'this event'}.",
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleCancelEvent(eventId);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD1D5DC)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Cancel Registration", style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _limeGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Stay", style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Future<void> _handleCancelEvent(String? eventId) async {
      final request = context.read<CookieRequest>();
      String baseUrl = kIsWeb ? "http://localhost:8000" : "http://10.0.2.2:8000";
      try {
        final response = await request.post("$baseUrl/api/cancel/${widget.username}/$eventId/", {});
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

    return Scaffold(
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
              ...attendanceList.map((record) => _buildEventCard(record, record['event'], record['status'], record['event']['event_status'])),

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
    );
  }
}
