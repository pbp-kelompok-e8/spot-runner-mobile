//lib\features\event\screens\detailevent_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:spot_runner_mobile/features/event/screens/editevent_form.dart';
import 'package:spot_runner_mobile/features/event/screens/testpage.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart'; 
import 'package:spot_runner_mobile/features/review/screens/review_card.dart';
import 'package:spot_runner_mobile/features/review/screens/review_modal.dart';
import 'package:spot_runner_mobile/features/review/service/review_service.dart';
import 'package:spot_runner_mobile/core/models/review_entry.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class EventDetailPage extends StatefulWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late Future<Map<String, dynamic>> _eventFuture;
  String? _selectedCategory;
  Map<String, dynamic>? _eoData;
  bool _isEoLoading = true;
  List<Datum> _reviews = [];
  bool _isLoadingReviews = true;
  bool _isBookingLoading = false;

  @override
  void initState() {
    super.initState();
    _eventFuture = fetchEventDetail().then((eventData) {
      var eoId = eventData['user_eo'];
      if (eoId is Map) {
        eoId = eoId['pk'] ?? eoId['id'];
      }
      if (eoId != null) {
        fetchEODetail(eoId.toString());
      }

      return eventData;
    });
    _loadReviews();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadReviews() async {
    final request = context.read<CookieRequest>();
    try {
      final reviewEntry = await ReviewService.getAllReviews(
        request,
        eventId: widget.eventId,
      );
      
      if (mounted && reviewEntry != null) {
        setState(() {
          _reviews = reviewEntry.data;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print("Error loading reviews: $e");
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<Map<String, dynamic>> fetchEventDetail() async {
    final request = context.read<CookieRequest>();
    final response = await request.get(
      ApiConfig.eventDetail(widget.eventId),
    );

    if (response is List) {
      return response[0];
    }
    return response;
  }

  Future<void> fetchEODetail(String eoId) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get(
        ApiConfig.eventOrganizerJson(),
      );
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
      print("Gagal ambil data EO: $e");
      if (mounted) setState(() => _isEoLoading = false);
    }
  }
  Future<void> _handleBooking() async {
    if (_selectedCategory == null) return;

    setState(() {
      _isBookingLoading = true;
    });

    final request = context.read<CookieRequest>();
    // Ambil username dari session
    final username = request.jsonData['username'];
    
    if (username == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Silakan login terlebih dahulu.")),
        );
        setState(() => _isBookingLoading = false);
        return;
    }

    // URL: /api/participate/<username>/<event_id>/<category>/
    final url = ApiConfig.participateUrl(username, widget.eventId, _selectedCategory!);

    try {
      // Panggil API (POST)
      final response = await request.post(url, {});

      if (mounted) {
        if (response['status'] == 'success') {
          // BERHASIL: Tampilkan pesan & Refresh Data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh detail event agar kuota/status terupdate
          setState(() {
            _eventFuture = fetchEventDetail();
            _selectedCategory = null; // Reset pilihan
          });
          
        } else if (response['status'] == 'warning') {
          // WARNING: Sudah terdaftar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          // ERROR LAIN
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? "Booking failed"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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
    final Uri url = Uri.parse(
      ApiConfig.deleteEventUrl(id),
    );
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(url.toString(), {});
      if (response['status'] == 'success' || response['message'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Event deleted successfully!"),
              backgroundColor: Colors.green,
            ),
          );
            Navigator.pop(context, true
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to delete event."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleEditReview(Datum review) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReviewModal(
        eventName: review.eventName,
        eventId: review.eventId,
        reviewId: review.id,
        initialRating: review.rating,
        initialReview: review.reviewText,
        onSubmit: (rating, reviewText) async {
          await _submitEditReview(review.id, rating, reviewText);
        },
      ),
    );

    if (result == true) {
      _loadReviews();
    }
  }

  Future<void> _submitEditReview(String reviewId, int rating, String reviewText) async {
    final request = context.read<CookieRequest>();
    
    try {
      final response = await ReviewService.editReview(
        request,
        reviewId: reviewId,
        rating: rating,
        reviewText: reviewText,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );

        if (response['success']) {
          Navigator.pop(context, true);
          _loadReviews();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final request = context.read<CookieRequest>();
      final response = await ReviewService.deleteReview(request, reviewId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );

        if (response['success']) {
          _loadReviews();
        }
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Data event tidak ditemukan."));
          }

          final event = snapshot.data!;

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
            if (!isOwner &&
                sessionUsername.isNotEmpty &&
                eventOwnerName.isNotEmpty) {
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
                  title: Text(
                    title,
                    style: const TextStyle(color: Colors.black),
                  ),
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
                                    setState(() {
                                      _eventFuture = fetchEventDetail();
                                    });
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    categoryName.toUpperCase().replaceAll(
                                      "_",
                                      " ",
                                    ),
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
                          onPressed: (_selectedCategory == null || _isBookingLoading || !isRunner)
                              ? null
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Booking category: $_selectedCategory",
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
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
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // Align top
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
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else if (_eoData != null)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Rating & Reviews",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
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
        },
      ),
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
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String name, double rating) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const Text(
            "Participant",
            style: TextStyle(fontSize: 9, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            "Lorem ipsum dolor sit amet...",
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.greenAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                rating.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
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
        content: const Text(
          "Are you sure you want to delete this event? This action cannot be undone.",
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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

  const ImageSliderWidget({
    super.key,
    required this.imageUrls,
    required this.onBackPressed,
  });

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
          _pageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
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
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                widget.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  color: Colors.grey[200],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      Text(
                        "Failed to load image",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Positioned(
          top: 40,
          left: 10,
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.7),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: widget.onBackPressed,
            ),
          ),
        ),

        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.imageUrls.asMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        entry.key,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: _currentImageIndex == entry.key ? 24.0 : 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentImageIndex == entry.key
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
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

  const EventTimerWidget({
    super.key,
    required this.targetDate,
    required this.deadlineString,
  });

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
      if (mounted) {
        setState(() {
          _calculateDiff();
        });
      }
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String days = diff.inDays.toString();
    String hours = (diff.inHours % 24).toString();
    String minutes = (diff.inMinutes % 60).toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "Registration Closes In",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeBox(days, "Days"),
              const SizedBox(width: 8),
              _buildTimeBox(hours, "Hours"),
              const SizedBox(width: 8),
              _buildTimeBox(minutes, "Mins"),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Deadline: ${widget.deadlineString != null ? DateFormat('dd MMM, HH:mm').format(DateTime.parse(widget.deadlineString!)) : '-'}",
            style: TextStyle(fontSize: 12, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
