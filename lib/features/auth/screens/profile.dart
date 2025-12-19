import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/core/models/user_entry.dart';
import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:spot_runner_mobile/features/auth/screens/change_password.dart';
import 'package:spot_runner_mobile/core/screens/menu.dart'; // For navigation to Home
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfileData();
    });
  }

  Future<void> _fetchProfileData() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get('http://localhost:8000/${widget.username}/json');
      
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

  Future<void> _handleLogout() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.logout("http://localhost:8000/auth/logout/");
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

    // Variabel untuk state di dalam dialog
    bool isLoading = false;
    String? errorMessage;

    // Tampilkan Dialog
    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa klik luar untuk tutup saat loading
      builder: (context) {
        // StatefulBuilder agar kita bisa update tampilan DI DALAM dialog (loading/error)
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Delete Account', 
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tindakan ini permanen. Masukkan password Anda untuk konfirmasi penghapusan akun:',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  
                  // --- INPUT FIELD DENGAN STYLE BIRU ---
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      // Tampilkan pesan error merah di sini jika ada
                      errorText: errorMessage, 
                      
                      // Border default (saat tidak diklik)
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      
                      // Border saat diklik (FOKUS) - Warna Biru Spot Runner
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF1D4ED8), 
                          width: 2.0
                        ),
                      ),
                      
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                ],
              ),
              actions: [
                // Tombol Cancel (Disable saat loading)
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                
                // Tombol Delete
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, 
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: isLoading ? null : () async {
                    // 1. Validasi Input Kosong
                    if (passwordController.text.isEmpty) {
                        setState(() {
                          errorMessage = "Password tidak boleh kosong.";
                        });
                        return;
                    }

                    // 2. Mulai Loading & Reset Error
                    setState(() {
                      isLoading = true;
                      errorMessage = null; 
                    });

                    // 3. Setup URL
                    String baseUrl = "http://10.0.2.2:8000"; 
                    try {
                       // ignore: undefined_identifier
                        if (kIsWeb) baseUrl = "http://localhost:8000"; 
                    } catch (_) {}
                    final url = "$baseUrl/api/delete-account/";

                    try {
                      // 4. Kirim Request
                      final response = await request.postJson(
                        url,
                        jsonEncode({'password': passwordController.text}),
                      );

                      if (context.mounted) {
                        if (response['status'] == 'success') {
                          // SUKSES: Tutup dialog, arahkan ke Login
                          Navigator.pop(context); // Tutup dialog
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Akun berhasil dihapus."), 
                              backgroundColor: Colors.green
                            ),
                          );
                        } else {
                          // GAGAL (Password Salah): Tampilkan error di bawah field
                          setState(() {
                            isLoading = false;
                            errorMessage = response['message'] ?? "Password salah.";
                          });
                        }
                      }
                    } catch (e) {
                      // ERROR JARINGAN / 500
                      if (context.mounted) {
                        setState(() {
                          isLoading = false;
                          errorMessage = "Terjadi kesalahan koneksi atau server.";
                        });
                        // Opsional: Print error ke console untuk debug
                        debugPrint("Error delete account: $e");
                      }
                    }
                  },
                  child: isLoading 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text('Delete Permanently'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bgPage = const Color(0xFFF9F9F9);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgPage,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profileData == null) {
      return Scaffold(
        backgroundColor: bgPage,
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(child: Text("Failed to load profile data")),
      );
    }

    // Extract data safely
    final userData = _profileData!; // Assuming flattened or specific structure from API
    final username = userData['username'] ?? 'User';
    final location = userData['base_location'] ?? 'Not set';
    final lastLogin = userData['last_login'] != null 
        ? DateFormat('MMMM dd, yyyy, hh:mm a').format(DateTime.parse(userData['last_login']))
        : 'Never';
    
    // Mocking list data if not present in the current API response structure
    // In a real scenario, ensure your API returns 'attendance_list' and 'user_reviews'
    final List<dynamic> attendanceList = userData['attendance_list'] ?? [];
    final List<dynamic> userReviews = userData['user_reviews'] ?? [];

    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(), 
        ),
        title: Text(
          "$username - Spot Runner",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            // ================== PROFILE CARD ==================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Your Profile",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Runner",
                              style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      // Last Login (Hide on small screens if needed, or wrap)
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Last login: $lastLogin",
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),

                  // Inputs
                  _buildDisabledInput("Username", username),
                  const SizedBox(height: 16),
                  _buildDisabledInput("Location", location),
                  const SizedBox(height: 16),
                  _buildDisabledInput("Password", "********"),
                  const SizedBox(height: 8),
                  
                  // Forgot Password Link
                  Row(
                    children: [
                      Text("Forgot your password? ", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                      GestureDetector(
                        onTap: () {
                          // Handle change password navigation
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                          );
                        },
                        child: const Text(
                          "Change password",
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _handleLogout,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.grey[500],
                          foregroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text("Log out"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Handle Edit Profile
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Edit Profile clicked")));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text("Edit Profile"),
                      ),
                      ElevatedButton(
                        onPressed: _handleDeleteAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text("Delete Account"),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ================== EVENT HISTORY ==================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Event History",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text("Join New Event +"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (attendanceList.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text("You haven't joined any events yet.", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: attendanceList.length,
                      itemBuilder: (context, index) {
                        final record = attendanceList[index];
                        final event = record['event'];
                        final status = record['status'];
                        final eventStatus = event['event_status']; // 'on_going', 'coming_soon', etc.
                        
                        return _buildEventCard(record, event, status, eventStatus);
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ================== REVIEWS ==================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Reviews",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),

                  if (userReviews.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid), // Dashed border tricky in Flutter without package
                      ),
                      child: const Center(
                        child: Text("You haven't written any reviews yet.", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    SizedBox(
                      height: 300,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: userReviews.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 20),
                        itemBuilder: (context, index) {
                          final review = userReviews[index];
                          return _buildReviewCard(review, username);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledInput(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          enabled: false,
          style: const TextStyle(color: Colors.black54),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(dynamic record, dynamic event, String status, String eventStatus) {
    Color borderColor = Colors.grey[300]!;
    Color bgColor = Colors.grey[50]!;
    Color badgeBg = Colors.grey[100]!;
    Color badgeText = Colors.grey[800]!;
    String statusText = status;

    if (status == 'canceled') {
      borderColor = Colors.red[300]!;
      bgColor = Colors.red[50]!;
      badgeBg = Colors.red[100]!;
      badgeText = Colors.red[800]!;
      statusText = "Canceled";
    } else if (status == 'finished') {
      borderColor = Colors.green[300]!;
      bgColor = Colors.green[50]!;
      badgeBg = Colors.green[100]!;
      badgeText = Colors.green[800]!;
      statusText = "Finished";
    } else if (status == 'attending') {
      if (eventStatus == 'on_going') {
        borderColor = Colors.blue[300]!;
        bgColor = Colors.blue[50]!;
        badgeBg = Colors.blue[100]!;
        badgeText = Colors.blue[800]!;
        statusText = "On Going";
      } else if (eventStatus == 'coming_soon') {
        borderColor = Colors.yellow[600]!; // Darker yellow for visibility
        bgColor = Colors.yellow[50]!;
        badgeBg = Colors.yellow[100]!;
        badgeText = Colors.yellow[900]!;
        statusText = "Coming Soon";
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Header: Name + Badge + Dropdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['name'] ?? 'Unknown Event',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    ),
                    Text(
                      event['location_display'] ?? event['location'] ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: badgeText, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (status == 'attending') ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        // Di dalam profile.dart, cari bagian PopupMenuButton 'cancel'
                        if (value == 'cancel') {
                          // 1. Ambil ID Event
                          final eventId = event['id']; 
                          if (eventId == null) return;

                          final request = context.read<CookieRequest>();
                          
                          // 2. Gunakan URL API Baru (Gunakan 10.0.2.2 untuk emulator)
                          // Pattern: /api/cancel/<username>/<id>/
                          final url = "http://localhost:8000/api/cancel/${widget.username}/$eventId/";

                          try {
                            // 3. Ubah menjadi POST Request (Karena @require_POST di backend)
                            final response = await request.post(url, {}); // Body kosong {}

                            if (mounted) {
                              // Cek status dari JSON response backend
                              if (response['status'] == 'success') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(response['message'])),
                                  );
                                  
                                  // Refresh halaman
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  _fetchProfileData(); 
                              } else {
                                  // Tampilkan pesan error/warning dari backend
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response['message']),
                                      backgroundColor: response['status'] == 'warning' ? Colors.orange : Colors.red,
                                    ),
                                  );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Terjadi kesalahan: $e")),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Cancel Booking', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ];
                      },
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                    ),
                  ]
                ],
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Colors.grey[300]),
          ),

          // Details Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(Icons.calendar_today, "Date", event['event_date'] ?? '-'),
                    const SizedBox(height: 12),
                    _buildDetailItem(Icons.category, "Type", record['category'] ?? '-'),
                  ],
                ),
              ),
              // Column 2
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(Icons.location_on_outlined, "Location", event['location_display'] ?? '-'),
                    const SizedBox(height: 12),
                    _buildDetailItem(Icons.qr_code, "Participant ID", record['participant_id'] ?? '-'),
                  ],
                ),
              ),
            ],
          ),

          // Footer Action (Rate)
          if (status == 'finished') ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: record['review'] != null 
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                      const SizedBox(width: 4),
                      Text("Already reviewed", style: TextStyle(color: Colors.green[600], fontSize: 14)),
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
                    icon: const Icon(Icons.star, size: 16),
                    label: const Text("Rate this event"),
                  ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  Widget _buildReviewCard(dynamic review, String username) {
    final eventName = review['event'] != null ? review['event']['name'] : 'Unknown Event';
    final rating = review['rating'] ?? 0.0;
    final reviewText = review['review_text'] ?? '';

    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Menu + User Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 2),
                    Text("Participant $eventName", 
                      style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  // Handle Edit/Delete review
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text("Edit")),
                  const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                ],
                icon: Icon(Icons.more_horiz, color: Colors.grey[300]),
              ),
            ],
          ),
          
          // Review Text
          Expanded(
            child: Center(
              child: Text(
                reviewText,
                style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Footer: Rating
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[50]!, style: BorderStyle.solid)), // Dashed logic omitted for simplicity
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Color(0xFFCDFA5D), size: 24),
                const SizedBox(width: 8),
                Text("$rating", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                const SizedBox(width: 4),
                Text("/5.0 rating", style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}