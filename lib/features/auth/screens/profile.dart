import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:spot_runner_mobile/features/auth/screens/change_password.dart';
import 'package:spot_runner_mobile/core/screens/menu.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/features/auth/screens/edit_profile.dart'; 
import 'package:spot_runner_mobile/core/providers/user_provider.dart';
import 'package:spot_runner_mobile/core/widgets/error_retry.dart'; // Import Widget Error

import 'package:spot_runner_mobile/features/review/screens/review_modal.dart';
import 'package:spot_runner_mobile/features/review/service/review_service.dart';

class RunnerProfilePage extends StatefulWidget {
  const RunnerProfilePage({super.key, required this.username});
  final String username;

  @override
  State<RunnerProfilePage> createState() => _RunnerProfilePageState();
}

class _RunnerProfilePageState extends State<RunnerProfilePage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  bool _isConnectionError = false; // State untuk error koneksi
  late String _currentUsername;

  // --- COLORS ---
  final Color _primaryBlue = const Color(0xFF1447E6);
  final Color _textDark = const Color(0xFF393938);
  final Color _textGrey = const Color(0xFF777675);
  final Color _limeGreen = const Color(0xFFA0E228); 
  final Color _starLime = const Color(0xFFCDFA5D);

  @override
  void initState() {
    super.initState();
    _currentUsername = widget.username;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfileData();
    });
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
      _isConnectionError = false;
    });

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
        setState(() {
          _isLoading = false;
          _isConnectionError = true; // Set error koneksi
        });
      }
    }
  }

  // --- REVIEW LOGIC ---
  Future<void> _handleRateEvent(String eventId, String eventName) async {
    await showDialog(
      context: context,
      builder: (context) => ReviewModal(
        eventName: eventName,
        eventId: eventId,
        onSubmit: (rating, reviewText) async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );

          try {
            final request = context.read<CookieRequest>();
            final result = await ReviewService.createReview(
              request,
              eventId: eventId,
              rating: rating,
              reviewText: reviewText,
            );

            if (mounted) Navigator.pop(context);

            if (mounted) {
              bool isSuccess = (result['status'] == 'success') || (result['success'] == true);
              if (isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Review submitted!"), backgroundColor: Colors.green),
                );
                await _fetchProfileData(); 
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'] ?? "Failed"), backgroundColor: Colors.red),
                );
              }
            }
          } catch (e) {
            if (mounted) Navigator.pop(context);
            // Retry Dialog untuk submit review
            showErrorRetryDialog(
              context: context,
              title: "Connection Error",
              message: "Failed to submit review. Check your connection.",
              onRetry: () => _handleRateEvent(eventId, eventName), // Sedikit tricky, akan membuka modal lagi
            );
          }
        },
      ),
    );
  }

  Future<void> _handleEditReview(Map<String, dynamic> review) async {
    await showDialog(
      context: context,
      builder: (context) => ReviewModal(
        eventName: review['event']['name'] ?? 'Event',
        eventId: review['event']['id']?.toString() ?? '',
        reviewId: review['id']?.toString() ?? '', 
        initialRating: review['rating'] ?? 0,
        initialReview: review['review_text'] ?? '',
        onSubmit: (rating, reviewText) async {
           showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

           final request = context.read<CookieRequest>();
           try {
             final response = await ReviewService.editReview(
               request, 
               reviewId: review['id'].toString(), 
               rating: rating, 
               reviewText: reviewText
             );
             
             if (mounted) Navigator.pop(context); 

             bool isSuccess = (response['status'] == 'success') || (response['success'] == true);

             if (isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review updated!"), backgroundColor: Colors.green));
                await _fetchProfileData();
             } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update"), backgroundColor: Colors.red));
             }
           } catch (e) {
             if(mounted) Navigator.pop(context);
             showErrorRetryDialog(
                context: context,
                title: "Connection Error",
                message: "Failed to update review.",
                onRetry: () async {}, // User harus klik edit lagi manual
             );
           }
        },
      ),
    );
  }

  Future<void> _handleDeleteReview(String reviewId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Review?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );

    if (confirm == true) {
      final request = context.read<CookieRequest>();
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
      
      try {
        final response = await ReviewService.deleteReview(request, reviewId);
        if(mounted) Navigator.pop(context); 

        bool isSuccess = (response['status'] == 'success') || (response['success'] == true);

        if (isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review deleted."), backgroundColor: Colors.green));
          await _fetchProfileData();
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete"), backgroundColor: Colors.red));
        }
      } catch(e) {
        if(mounted) Navigator.pop(context);
        showErrorRetryDialog(
          context: context,
          title: "Connection Error",
          message: "Failed to delete review.",
          onRetry: () => _handleDeleteReview(reviewId),
        );
      }
    }
  }

  // --- ACTIONS LAINNYA ---
  Future<void> _handleLogout() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.logout(ApiConfig.logout);
      if (context.mounted && response['status'] == true) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logged out successfully!")));
      }
    } catch (e) {
      if (mounted) {
        showErrorRetryDialog(
          context: context,
          title: "Logout Failed",
          message: "Could not log out. Check connection.",
          onRetry: _handleLogout,
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final TextEditingController passwordController = TextEditingController();
    final request = context.read<CookieRequest>();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter password to confirm deletion:'),
            TextField(controller: passwordController, obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (passwordController.text.isEmpty) return;
              // Tutup dialog input password dulu
              Navigator.pop(ctx);
              
              // Loading
              showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

              try {
                final response = await request.postJson(ApiConfig.deleteAccount(), jsonEncode({'password': passwordController.text}));
                
                if (mounted) Navigator.pop(context); // Tutup loading

                if (mounted) {
                  if (response['status'] == 'success') {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? "Failed"), backgroundColor: Colors.red));
                  }
                }
              } catch (e) {
                if(mounted) Navigator.pop(context); // Tutup loading
                showErrorRetryDialog(
                  context: context,
                  title: "Connection Error",
                  message: "Failed to delete account.",
                  onRetry: _handleDeleteAccount,
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty || dateStr == '-' || dateStr == 'Never') return dateStr;
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(dateStr));
    } catch (e) { return dateStr; }
  }

  String _formatLastLogin(String dateStr) {
    if (dateStr.isEmpty || dateStr == '-' || dateStr == 'Never') return dateStr;
    try {
      return DateFormat("MMMM d, yyyy 'at' hh:mm a").format(DateTime.parse(dateStr));
    } catch (e) { return dateStr; }
  }

  String _formatString(String? value) {
    if (value == null || value.isEmpty || value == '-') return '-';
    return value.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '').join(' ');
  }

  // ==================== WIDGETS UI ====================

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: _textDark)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFFBFBFB), border: Border.all(color: const Color(0xFFD7D5D3)), borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 14, color: _textGrey)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 35, offset: const Offset(-35, 3))],
      ),
      child: Column(
        children: [
          Text("Your Profile", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 24, color: _textDark)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(50)),
            child: const Text("Runner", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF016630))),
          ),
          const SizedBox(height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Text("Last login: ${_formatLastLogin(lastLogin)}", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 12, color: _textGrey))),
              _buildField("Username", username), const SizedBox(height: 20),
              _buildField("Location", _formatString(location)), const SizedBox(height: 20),
              _buildField("Password", "........"),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(children: [
              Text("Forgot your password? ", style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: _textDark)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordPage())),
                child: Text("Change password", style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: _primaryBlue)),
              ),
            ]),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () async {
                String cleanLocation = (location == 'Not set' || location == '-') ? '' : location;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfilePage(currentUsername: _currentUsername, currentLocation: cleanLocation)),
                );
                if (result != null && result is Map) {
                  context.read<UserProvider>().setUsername(result['new_username']);
                  setState(() { _currentUsername = result['new_username']; _profileData!['base_location'] = result['new_location']; });
                  _fetchProfileData();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 48,
            child: OutlinedButton(
              onPressed: _handleLogout,
              style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFF99A1AF), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Log out", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: _handleDeleteAccount, child: const Text("Delete Account", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildEventCard(dynamic record, dynamic event, String status, String eventStatus, String category, String participantId) {
    Color cardBg = const Color(0xFFEFF6FF); Color badgeBg = const Color(0xFFBEDBFF); Color badgeText = const Color(0xFF1C398E); String statusLabel = "On Going"; Color cardBorder = const Color(0xFF2B7FFF);

    if (status == 'canceled') {
      cardBg = const Color(0xFFFEF2F2); cardBorder = const Color(0xFFFB2C36); badgeBg = const Color(0xFFFFC9C9); badgeText = const Color(0xFF82181A); statusLabel = "Canceled";
    } else if (eventStatus == 'finished' || status == 'finished') {
      cardBg = const Color(0xFFF0FDF4); cardBorder = const Color(0xFF00C951); badgeBg = const Color(0xFFB9F8CF); badgeText = const Color(0xFF0D542B); statusLabel = "Finished";
    } else if (eventStatus == 'coming_soon') {
      cardBg = const Color(0xFFFEFCE8); cardBorder = const Color(0xFFFACC15); badgeBg = const Color(0xFFFEF08A); badgeText = const Color(0xFF854D0E); statusLabel = "Coming Soon";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBg, border: Border.all(color: cardBorder, width: 1.5), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(event['name'] ?? "Unknown", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(_formatString(event['location_display']), style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)))
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(50)),
                child: Text(statusLabel, style: TextStyle(color: badgeText, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider(height: 1, color: Color(0xFFD1D5DC))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildEventDataRow("Date", _formatDate(event['event_date'] ?? '')), const SizedBox(height: 12),
            _buildEventDataRow("Location", event['location_display'] ?? '-'), const SizedBox(height: 12),
            _buildEventDataRow("Type", category), const SizedBox(height: 12),
            _buildEventDataRow("Participant ID", participantId),
          ]),
          const SizedBox(height: 24),
          
          if (status == 'attending' && eventStatus != 'finished') 
            SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(
              onPressed: () => _showCancelConfirmation(event['id'], event['name']),
              icon: const Icon(Icons.delete_outline, color: Color(0xFFE7000B)),
              label: const Text("Cancel Booking", style: TextStyle(color: Color(0xFFE7000B), fontSize: 15, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFFEF2F2), side: const BorderSide(color: Color(0xFFFB2C36)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            )),
            
          if ((eventStatus == 'finished' || status == 'finished') && record['review'] == null)
            SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
              onPressed: () => _handleRateEvent(event['id'].toString(), event['name']),
              icon: const Icon(Icons.star_outline, color: Color(0xFF35530E)),
              label: const Text("Rate this event", style: TextStyle(color: Color(0xFF35530E), fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: _limeGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
            )),
        ],
      ),
    );
  }

  Widget _buildEventDataRow(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
      const SizedBox(height: 4),
      Text(_formatString(value), style: const TextStyle(fontSize: 15, color: Color(0xFF111827), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1),
    ]);
  }

  Future<void> _showCancelConfirmation(String? eventId, String? eventName) async {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Cancel Booking?"), content: Text("Are you sure you want to cancel ${eventName ?? 'this event'}?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("No")),
        ElevatedButton(onPressed: () { Navigator.pop(ctx); _handleCancelEvent(eventId!); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white))),
      ],
    ));
  }

  Future<void> _handleCancelEvent(String eventId) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(ApiConfig.cancelParticipation(_currentUsername, eventId), {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? "Status updated"), backgroundColor: response['status'] == 'success' ? Colors.green : Colors.red));
        _fetchProfileData();
      }
    } catch (e) {
      if (mounted) {
        showErrorRetryDialog(
          context: context,
          title: "Connection Error",
          message: "Failed to cancel booking.",
          onRetry: () => _handleCancelEvent(eventId),
        );
      }
    }
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    String reviewId = review['id']?.toString() ?? '';
    String eventName = review['event']['name'] ?? 'Event';
    String reviewText = review['review_text'] ?? '';
    double rating = (review['rating'] ?? 0).toDouble();

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16, bottom: 8, top: 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Text(
                _currentUsername,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                "Participant $eventName",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: Center(
                  child: Text(
                    "\"$reviewText\"",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: _textGrey, height: 1.5, fontStyle: FontStyle.italic),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.only(top: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: _starLime, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      rating.toString(),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "/5.0",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              )
            ],
          ),
          
          Positioned(
            top: -10,
            right: -10,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') {
                  _handleEditReview(review);
                } else if (value == 'delete') {
                  _handleDeleteReview(reviewId);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('Edit', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(fontSize: 14, color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnectionError) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
          title: Text("SpotRunner", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, fontSize: 18, color: _primaryBlue)),
        ),
        body: ErrorRetryWidget(
          message: "Unable to load profile. Please check your connection.",
          onRetry: _fetchProfileData,
        ),
      );
    }

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final userData = _profileData!;
    final username = userData['username'] ?? 'User';
    final location = userData['base_location'] ?? 'Not set';
    final lastLogin = userData['last_login'] != null ? userData['last_login'].toString() : 'Never'; 
    final List attendanceList = userData['attendance_list'] ?? [];
    final List reviewList = userData['user_reviews'] ?? []; 

    return RefreshIndicator(
      onRefresh: _fetchProfileData,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
          title: Text("SpotRunner", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, fontSize: 18, color: _primaryBlue)),
        ),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(username, location, lastLogin),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Event History", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 24, color: _textDark)),
                  ElevatedButton(
                    onPressed: () { Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage())); },
                    style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0)),
                    child: const Text("+ Join New Event", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  )
                ],
              ),
              const SizedBox(height: 20),
              if (attendanceList.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("You haven't joined any events yet.", style: TextStyle(color: Colors.grey))))
              else
                ...attendanceList.map((record) => _buildEventCard(record, record['event'], record['status'], record['event']['event_status'], record['category'] ?? '-', record['participant_id']?.toString() ?? '-')),
              const SizedBox(height: 40),
              Text("Your Reviews", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 24, color: _textDark)),
              const SizedBox(height: 20),
              if (reviewList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
                  child: const Center(child: Text("You haven't written any reviews yet.", style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF6B7280)))),
                )
              else
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: reviewList.length,
                    itemBuilder: (context, index) => _buildReviewItem(reviewList[index]),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}