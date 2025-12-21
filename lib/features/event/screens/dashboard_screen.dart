import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/core/models/event_entry.dart';
import 'package:spot_runner_mobile/core/models/user_entry.dart';
import 'package:spot_runner_mobile/core/widgets/error_handler.dart';
import 'package:spot_runner_mobile/core/widgets/left_drawer.dart';
import 'package:spot_runner_mobile/features/event/screens/detailevent_page.dart';
import 'package:spot_runner_mobile/features/event/screens/editevent_form.dart';
import 'package:spot_runner_mobile/features/event/screens/event_form.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserProfile? _userProfile;
  List<EventEntry> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Fungsi untuk load semua data (profile + events milik EO yang login)
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final request = context.read<CookieRequest>();
    final connectivity = context.read<ConnectivityProvider>();
    final String currentUserName = request.jsonData['username'] ?? '';
    bool hasConnectionError = false;

    // Load profile
    try {
      final profileResp = await request.get(ApiConfig.profile);
      if (profileResp is Map<String, dynamic>) {
        _userProfile = UserProfile.fromJson(profileResp);
      } else if (profileResp is List && profileResp.isNotEmpty) {
        final first = profileResp.first;
        if (first is Map<String, dynamic>) {
          _userProfile = UserProfile.fromJson(first);
        }
      }
    } catch (e) {
      _userProfile = null;
      hasConnectionError = true;
    }

    // Load events dan filter hanya milik EO yang login
    try {
      final eventsResp = await request.get(ApiConfig.eventJson);
      if (eventsResp is List) {
        final allEvents = eventsResp
            .map((e) => EventEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // Filter: hanya event yang userEo.id == currentUserId
        _events = allEvents
            .where((event) => event.userEo.username == currentUserName)
            .toList();
      }
    } catch (e) {
      _events = [];
      hasConnectionError = true;
    }

    if (mounted) {
      setState(() => _isLoading = false);

      // Tampilkan error overlay jika ada connection error
      if (hasConnectionError) {
        connectivity.setError(
          "Failed to load data. Please check your connection.",
          () => _loadData(),
        );
      }
    }
  }

  // Fungsi untuk menghapus event dari list lokal
  void _removeEvent(String eventId) {
    setState(() {
      _events.removeWhere((e) => e.id.toString() == eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        drawer: const LeftDrawer(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Memastikan tidak error jika userProfile null
    final safeUserProfile =
        _userProfile ??
        UserProfile(
          id: 0,
          username: 'Guest',
          email: '',
          role: 'guest',
          details: null,
        );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      drawer: const LeftDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(safeUserProfile),
            const SizedBox(height: 32),
            const Text(
              "Your Event",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            _buildCreateEventButton(context),
            const SizedBox(height: 24),
            if (_events.isEmpty)
              _buildEmptyEventsState()
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _events.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  return EventCard(
                    event: _events[index],
                    onDeleted: () => _removeEvent(_events[index].id.toString()),
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black87),
      title: const Text(
        "Dashboard",
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProfileSection(UserProfile user) {
    // MENGAMBIL NILAI VALID DARI MODEL
    final String username = user.username;
    final String? profilePicture = user.details?.profilePicture;

    // Mengambil data dari nested 'details' dengan fallback nilai default
    final int totalEvents = user.details?.totalEvents ?? 0;
    final double rating = user.details?.rating ?? 0.0;

    // Format baseLocation: kapital di awal dan setelah _, hilangkan _
    String formatLocation(String? location) {
      if (location == null || location.isEmpty) return "Location not set";
      return location
          .split('_')
          .map(
            (word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : '',
          )
          .join(' ');
    }

    final String baseLocation = formatLocation(user.details?.baseLocation);

    // gunakan tanggal hari ini atau placeholder tetap jika tidak ada dari API.
    final String joinedDate = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade100),
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: (profilePicture != null && profilePicture.isNotEmpty)
                      ? Image.network(
                          profilePicture,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.directions_run,
                                color: Colors.lightGreen,
                                size: 30,
                              ),
                        )
                      : const Icon(
                          Icons.directions_run,
                          color: Colors.lightGreen,
                          size: 30,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Organized By",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailRow(
            Icons.person_outline,
            "Total Events",
            "$totalEvents events",
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.calendar_today_outlined, "Joined", joinedDate),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.location_on_outlined,
            "Base Location",
            baseLocation,
          ),
          const SizedBox(height: 24),
          const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const Text(
                  "Rating & Review",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Color(0xFFA3E635), size: 28),
                    const SizedBox(width: 8),
                    Text(
                      rating.toStringAsFixed(1), // Nilai valid dari model
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "/5.0 rating",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.grey[400]),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreateEventButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EventFormPage()),
          );
          // Refresh data saat kembali dari form
          if (result == true || result == null) {
            _loadData();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D4ED8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Create new event",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyEventsState() {
    return const Center(child: Text("No events found"));
  }
}

class EventCard extends StatelessWidget {
  final EventEntry event;
  // Callback untuk menghapus event dari UI setelah delete berhasil
  final VoidCallback? onDeleted;
  // Callback untuk refresh data setelah edit
  final VoidCallback? onRefresh;

  const EventCard({
    Key? key,
    required this.event,
    this.onDeleted,
    this.onRefresh,
  }) : super(key: key);

  // 1. LOGIKA AUTO-UPDATE STATUS
  String _calculateDynamicStatus(DateTime eventDate) {
    final now = DateTime.now();
    // Normalisasi waktu ke jam 00:00:00 agar perbandingan akurat per hari
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);

    if (today.isBefore(eventDay)) {
      return 'comingsoon';
    } else if (today.isAtSameMomentAs(eventDay)) {
      return 'ongoing';
    } else {
      // Jika sudah lewat 1 hari atau lebih
      return 'finished';
    }
  }

  // 2. LOGIKA DELETE API
  Future<void> _deleteEvent(BuildContext context, String id) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(ApiConfig.deleteEventUrl(id), {});

      if (response['status'] == 'success') {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Event deleted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        if (onDeleted != null) onDeleted!(); 
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Failed to delete event."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status) {
      case 'ongoing':
        return {
          'chipColor': Colors.blue.shade100,
          'textColor': Colors.blue.shade700,
          'cardColor': const Color(0xFFF3F7FF),
          'borderColor': Colors.blue.shade200,
          'label': 'On Going',
        };
      case 'finished':
        return {
          'chipColor': Colors.green.shade100,
          'textColor': Colors.green.shade700,
          'cardColor': const Color(0xFFF0FDF4),
          'borderColor': Colors.green.shade200,
          'label': 'Finished',
        };
      case 'comingsoon':
        return {
          'chipColor': Colors.amber.shade100,
          'textColor': Colors.amber.shade900,
          'cardColor': const Color(0xFFFFFBEB),
          'borderColor': Colors.amber.shade200,
          'label': 'Coming Soon',
        };
      default:
        return {
          'chipColor': Colors.grey.shade200,
          'textColor': Colors.grey.shade700,
          'cardColor': Colors.grey.shade50,
          'borderColor': Colors.grey.shade300,
          'label': status,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final String dynamicStatus = _calculateDynamicStatus(event.eventDate);
    final statusStyle = _getStatusStyle(dynamicStatus);

    return InkWell(
      onTap: () async {
        // Navigasi ke halaman detail
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(eventId: event.id.toString()),
          ),
        );

        // Jika ada perubahan (edit/delete) di detail page, refresh dashboard
        if ((result == true) && onRefresh != null) {
          onRefresh!();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: statusStyle['cardColor'],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusStyle['borderColor'], width: 1.5),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusStyle['chipColor'],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusStyle['label'],
                style: TextStyle(
                  color: statusStyle['textColor'],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              event.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: statusStyle['borderColor'].withOpacity(0.5)),
            const SizedBox(height: 16),

            _buildInfoRow(
              Icons.calendar_today_outlined,
              "Date",
              DateFormat('dd MMM yyyy').format(event.eventDate),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on_outlined,
              "Location",
              event.location.replaceAll("_", " "),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.run_circle_outlined,
              "Type",
              event.eventCategories.isEmpty
                  ? "-"
                  : event.eventCategories.join(", ").replaceAll("_", " "),
            ),
            const SizedBox(height: 20),
            Text(
              "Participant ID",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              "EVT-${event.id.toString().substring(0, 4).toUpperCase()}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditEventFormPage(
                            event: {
                              "id": event.id,
                              "name": event.name,
                              "description": event.description,
                              "location": event.location,
                              "event_status": dynamicStatus,
                              "image": event.image,
                              "image2": event.image2,
                              "image3": event.image3,
                              "event_date": event.eventDate
                                  .toLocal()
                                  .toIso8601String(),
                              "regist_deadline": event.registDeadline
                                  .toLocal()
                                  .toIso8601String(),
                              "contact": event.contact,
                              "capacity": event.capacity,
                              "coin": event.coin,
                              "event_categories": event.eventCategories,
                            },
                          ),
                        ),
                      );
                      // Refresh data saat kembali dari edit
                      if (result == true && onRefresh != null) {
                        onRefresh!();
                      }
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text("Edit Detail"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.7),
                      foregroundColor: const Color(0xFF1D4ED8),
                      elevation: 0,
                      side: BorderSide(color: statusStyle['borderColor']),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    // LOGIKA DELETE DI SINI
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete this event?'),
                          content: Text(
                            'Are you sure you want to delete "${event.name}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await _deleteEvent(
                                  context,
                                  event.id.toString(),
                                );
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text("Delete"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      foregroundColor: const Color(0xFFDC2626),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
