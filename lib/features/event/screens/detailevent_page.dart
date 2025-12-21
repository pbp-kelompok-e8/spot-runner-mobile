import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:spot_runner_mobile/core/widgets/error_handler.dart';
import 'package:spot_runner_mobile/core/widgets/error_retry.dart';
import 'package:spot_runner_mobile/features/event/screens/dashboard_screen.dart';
import 'package:spot_runner_mobile/features/event/screens/editevent_form.dart';
import 'package:spot_runner_mobile/features/event/screens/testpage.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/features/review/screens/review_card.dart';
import 'package:spot_runner_mobile/features/review/screens/review_modal.dart';
import 'package:spot_runner_mobile/features/review/service/review_service.dart';
import 'package:spot_runner_mobile/core/models/review_entry.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  Map<String, dynamic>? _eventData;
  bool _isEventLoading = true;
  String? _selectedCategory;
  Map<String, dynamic>? _eoData;
  bool _isEoLoading = true;
  List<Datum> _reviews = [];
  bool _isLoadingReviews = true;
  bool _isBookingLoading = false;

  // Map untuk konversi Display Name -> Value (Sesuai models.py Django)
  final Map<String, String> _categoryMap = {
    'Fun Run (3K)': 'fun_run',
    '5K Race': '5k',
    '10K Race': '10k',
    'Half Marathon (21K)': 'half_marathon',
    'Full Marathon (42K)': 'full_marathon',
  };

  // Helper untuk mendapatkan value kategori yang benar
  String _getCategoryValue(String displayName) {
    // Coba cari di map, jika tidak ada, ubah spasi jadi underscore & lowercase
    return _categoryMap[displayName] ?? displayName.toLowerCase().replaceAll(' ', '_');
  }

  @override
  void initState() {
    super.initState();
    _loadEventDetail();
    _loadReviews();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadReviews() async {
    print("🔄 Loading reviews...");

    if (!mounted) return;

    final request = context.read<CookieRequest>();

    try {
      final reviewEntry = await ReviewService.getAllReviews(
        request,
        eventId: widget.eventId,
      );

      print("📦 Received ${reviewEntry?.data.length ?? 0} reviews");

      if (mounted) {
        setState(() {
          _reviews = reviewEntry?.data ?? [];
          _isLoadingReviews = false;
        });
        print("✅ Reviews updated in UI");
      }
    } catch (e) {
      print("❌ Error loading reviews: $e");
      if (mounted) {
        setState(() {
          _reviews = [];
          _isLoadingReviews = false;
        });
        context.read<ConnectivityProvider>().setError(
          "Failed to load reviews. Please check your connection.",
          () => _loadReviews(),
        );
      }
    }
  }

  Future<void> _loadEventDetail() async {
    setState(() => _isEventLoading = true);

    final request = context.read<CookieRequest>();
    try {
      final response = await request.get(ApiConfig.eventDetail(widget.eventId));

      Map<String, dynamic> eventData;
      if (response is List) {
        eventData = response[0];
      } else {
        eventData = response;
      }

      if (mounted) {
        setState(() {
          _eventData = eventData;
          _isEventLoading = false;
        });

        // Load EO detail after event loaded
        var eoId = eventData['user_eo'];
        if (eoId is Map) {
          eoId = eoId['pk'] ?? eoId['id'];
        }
        if (eoId != null) {
          fetchEODetail(eoId.toString());
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEventLoading = false);
        context.read<ConnectivityProvider>().setError(
          "Gagal memuat detail event. Periksa koneksi internet Anda.",
          () => _loadEventDetail(),
        );
      }
    }
  }

  Future<void> fetchEODetail(String eoId) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get(ApiConfig.eventOrganizerJson());
      if (response['status'] == 'success') {
        List<dynamic> organizers = response['data'];
        var foundEO = organizers.firstWhere(
          (eo) => eo['user_id'].toString() == eoId,
          orElse: () => null,
        );

        if (mounted && foundEO != null) {
          setState(() {
            _eoData = foundEO;
            _isEoLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEoLoading = false);
        context.read<ConnectivityProvider>().setError(
          "Failed to load organizer data. Please check your connection.",
          () => fetchEODetail(eoId),
        );
      }
    }
  }

  Future<void> _handleBooking() async {
    if (_selectedCategory == null) return;

    setState(() {
      _isBookingLoading = true;
    });

    final request = context.read<CookieRequest>();
    final username = request.jsonData['username'];

    if (username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login terlebih dahulu.")),
      );
      setState(() => _isBookingLoading = false);
      return;
    }

    // URL: /api/participate/<username>/<event_id>/<category>/
    final String categoryValue = _getCategoryValue(_selectedCategory!);

    final url = ApiConfig.participateUrl(username, widget.eventId, categoryValue);

    try {
      final response = await request.post(url, {});

      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message']), backgroundColor: Colors.green),
          );

          // Refresh detail event agar kuota/status terupdate
          setState(() {
            _selectedCategory = null; // Reset pilihan
          });
          _loadEventDetail();
        } else if (response['status'] == 'warning') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message']), backgroundColor: Colors.orange),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? "Booking failed"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorRetryDialog(
          context: context,
          title: "Connection Error",
          message: "Failed to make a booking. Please check your connection.",
          onRetry: () => _handleBooking(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBookingLoading = false;
        });
      }
    }
  }

  Future<void> _deleteEvent(String id) async {
    final Uri url = Uri.parse(ApiConfig.deleteEventUrl(id));
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(url.toString(), {});
      if (response['status'] == 'success' || response['message'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Event deleted successfully!"), backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to delete event."), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        context.read<ConnectivityProvider>().setError(
          "Failed to delete event. Please check your connection.",
          () => _deleteEvent(id),
        );
      }
    }
  }

  // --- REVIEW FUNCTIONS ---
  Future<void> _handleEditReview(Datum review) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ReviewModal(
        eventName: review.eventName,
        eventId: review.eventId,
        reviewId: review.id,
        initialRating: review.rating,
        initialReview: review.reviewText,
        onSubmit: (rating, reviewText) async {
          final request = context.read<CookieRequest>();
          try {
            final response = await ReviewService.editReview(
              request,
              reviewId: review.id,
              rating: rating,
              reviewText: reviewText,
            );

            if (!response['success']) {
              throw Exception(response['message']);
            }
          } catch (e) {
            // Re-throw to be caught by ReviewModal
            rethrow;
          }
        },
      ),
    );

    if (!mounted || result != true) return;

    await _loadReviews();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleDeleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      final request = context.read<CookieRequest>();
      final response = await ReviewService.deleteReview(request, reviewId);

      if (!mounted) return;

      if (response['success']) {
        await _loadReviews();

        if (!mounted) return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: response['success'] ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (mounted) {
        showErrorRetryDialog(
          context: context,
          title: "Connection Error",
          message: "Failed to delete review. Please check your connection.",
          onRetry: () => _handleDeleteReview(reviewId),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final String userRole = request.jsonData['role'] ?? '';
    bool isRunner = userRole.toLowerCase() == 'runner';
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(request, isRunner),
    );
  }

  Widget _buildBody(CookieRequest request, bool isRunner) {
    if (_isEventLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_eventData == null) {
      return const Center(child: Text("Data event tidak ditemukan."));
    }

    final event = _eventData!;

    // --- LOGIKA GAMBAR ---
    List<String> imageUrls = [];
    void addImageIfValid(dynamic img) {
      if (img != null &&
          img.toString().isNotEmpty &&
          img.toString() != "null") {
        imageUrls.add(img.toString());
      }
    }

    addImageIfValid(event['image']);
    addImageIfValid(event['image_2'] ?? event['image2']);
    addImageIfValid(event['image_3'] ?? event['image3']);

    bool hasImage = imageUrls.isNotEmpty;

    final String title = event['name'] ?? 'No Title';
    final String dateStr =
        event['event_date'] ?? DateTime.now().toIso8601String();
    final DateTime eventDate = DateTime.parse(dateStr);
    final String location = event['location'] ?? 'Unknown';
    final int capacity = event['capacity'] ?? 0;
    final int totalParticipants = event['total_participans'] ?? 0;
    final String description = event['description'] ?? '-';
    final List<dynamic> categories = event['event_categories'] ?? [];
    final dynamic sessionUserId = request.jsonData['user_id'];
    final String sessionUsername = request.jsonData['username'] ?? '';

    dynamic eventOwnerId;
    String eventOwnerName = '';
    if (event['user_eo'] is Map) {
      final Map<String, dynamic> ownerMap = event['user_eo'];
      eventOwnerId = ownerMap['pk'] ?? ownerMap['id'];
      eventOwnerName = ownerMap['username'] ?? '';
    } else {
      eventOwnerId = event['user_eo'];
    }

    bool isOwner = false;
    if (request.loggedIn) {
      if (sessionUserId != null && eventOwnerId != null) {
        isOwner = sessionUserId.toString() == eventOwnerId.toString();
      }
      if (!isOwner && sessionUsername.isNotEmpty && eventOwnerName.isNotEmpty) {
        isOwner = sessionUsername == eventOwnerName;
      }
    }

    final organizerData = event['user_eo'] ?? {};
    final String organizerName = organizerData['username'] ?? 'Organizer';

    return CustomScrollView(
      slivers: [
        // --- 1. SLIDER GAMBAR ---
        if (hasImage)
          SliverToBoxAdapter(
            child: ImageSliderWidget(
              imageUrls: imageUrls,
              onBackPressed: () => Navigator.pop(context),
            ),
          ),

        // --- 2. APPBAR (Jika tidak ada gambar) ---
        if (!hasImage)
          SliverAppBar(
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(title, style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 1,
          ),

        // --- 3. KONTEN DETAIL ---
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage) ...[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (isOwner)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Color(0xFF1D4ED8),
                          ),
                          label: const Text(
                            "Edit",
                            style: TextStyle(color: Color(0xFF1D4ED8)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF1D4ED8),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () async {
                            bool? result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditEventFormPage(event: event),
                              ),
                            );
                            if (result == true) {
                              _loadEventDetail();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.delete,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => _showDeleteDialog(context),
                        ),
                      ),
                    ],
                  ),
                if (isOwner) const SizedBox(height: 24),

                const Text(
                  "About This Event",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.people_outline,
                  "Participants",
                  "$totalParticipants/$capacity",
                ),
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  "Date",
                  DateFormat('dd MMM yyyy').format(eventDate),
                ),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  "Location",
                  location.replaceAll("_", " "),
                ),
                _buildInfoRow(
                  Icons.run_circle_outlined,
                  "Type",
                  categories.join(", ").replaceAll("_", " "),
                ),

                const SizedBox(height: 24),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),
                EventTimerWidget(
                  targetDate: DateTime.parse(event['regist_deadline']),
                  deadlineString: event['regist_deadline'],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Select Category",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...categories.map((cat) {
                  String categoryName = cat.toString();
                  bool isSelected = _selectedCategory == categoryName;
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? Color(0xFF1D4ED8)
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected)
                            _selectedCategory = null;
                          else
                            _selectedCategory = categoryName;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              categoryName.toUpperCase().replaceAll("_", " "),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Color(0xFF1D4ED8)
                                    : Colors.black,
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF1D4ED8),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedCategory != null
                          ? Color(0xFF1D4ED8)
                          : Colors.grey[300],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Disable tombol jika kategori belum dipilih ATAU sedang loading
                    onPressed:
                        (_selectedCategory == null ||
                            _isBookingLoading ||
                            !isRunner)
                        ? null
                        : _handleBooking,
                    child: const Text(
                      "Book Now",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align top
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.green[100],
                      backgroundImage:
                          (_eoData != null &&
                              _eoData!['profile_picture'] != null)
                          ? NetworkImage(_eoData!['profile_picture'])
                          : null,
                      child:
                          (_eoData == null ||
                              _eoData!['profile_picture'] == null)
                          ? const Icon(
                              Icons.person,
                              color: Colors.green,
                              size: 20,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Organized By",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            organizerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 4),
                          if (_isEoLoading)
                            const SizedBox(
                              height: 10,
                              width: 10,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_eoData != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_city,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _eoData!['base_location'][0]
                                                  .toString()[0]
                                                  .toUpperCase() +
                                              _eoData!['base_location']
                                                  .toString()
                                                  .substring(1)
                                                  .replaceAll("_", " ") ??
                                          '-',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.event_available,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${_eoData!['total_events']} Events hosted",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            const Text(
                              "Detail EO tidak ditemukan",
                              style: TextStyle(fontSize: 10, color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Rating & Reviews",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                if (_isLoadingReviews)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_reviews.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No reviews yet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        return Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 12),
                          child: ReviewCard(
                            reviewId: review.id,
                            runnerName: review.runnerName,
                            eventName: review.eventName,
                            reviewText: review.reviewText,
                            rating: review.rating.toDouble(),
                            isOwner: review.isOwner,
                            onEdit: () => _handleEditReview(review),
                            onDelete: () => _handleDeleteReview(review.id),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete this Event?", style: TextStyle(fontSize: 16)),
        content: const Text("Are you sure you want to delete this event? This action cannot be undone.", style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteEvent(widget.eventId);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

class ImageSliderWidget extends StatefulWidget {
  final List<String> imageUrls;
  final VoidCallback onBackPressed;

  const ImageSliderWidget({super.key, required this.imageUrls, required this.onBackPressed});

  @override
  State<ImageSliderWidget> createState() => _ImageSliderWidgetState();
}

class _ImageSliderWidgetState extends State<ImageSliderWidget> {
  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    if (widget.imageUrls.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (mounted && _pageController.hasClients) {
          int nextIndex = (_currentImageIndex + 1) % widget.imageUrls.length;
          _pageController.animateToPage(nextIndex, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              return Image.network(
                widget.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 40, left: 10,
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.7),
            child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: widget.onBackPressed),
          ),
        ),
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.7), Colors.transparent])),
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.imageUrls.asMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () => _pageController.animateToPage(entry.key, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    child: Container(
                      width: _currentImageIndex == entry.key ? 24.0 : 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: _currentImageIndex == entry.key ? Colors.white : Colors.white.withOpacity(0.5)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class EventTimerWidget extends StatefulWidget {
  final DateTime targetDate;
  final String? deadlineString;

  const EventTimerWidget({super.key, required this.targetDate, required this.deadlineString});

  @override
  State<EventTimerWidget> createState() => _EventTimerWidgetState();
}

class _EventTimerWidgetState extends State<EventTimerWidget> {
  Timer? _timer;
  late Duration diff;

  @override
  void initState() {
    super.initState();
    _calculateDiff();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _calculateDiff());
    });
  }

  void _calculateDiff() {
    diff = widget.targetDate.difference(DateTime.now());
    if (diff.isNegative) diff = Duration.zero;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildTimeBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey[300]!)),
      child: Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Text("Registration Closes In", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeBox(diff.inDays.toString(), "Days"),
              const SizedBox(width: 8),
              _buildTimeBox((diff.inHours % 24).toString(), "Hours"),
              const SizedBox(width: 8),
              _buildTimeBox((diff.inMinutes % 60).toString(), "Mins"),
            ],
          ),
          const SizedBox(height: 8),
          Text("Deadline: ${widget.deadlineString != null ? DateFormat('dd MMM, HH:mm').format(DateTime.parse(widget.deadlineString!)) : '-'}", style: const TextStyle(fontSize: 12, color: Colors.black)),
        ],
      ),
    );
  }
}