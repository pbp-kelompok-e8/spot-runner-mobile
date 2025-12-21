//lib\features\event\screens\testpage.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:spot_runner_mobile/features/event/screens/editevent_form.dart'; 
import 'package:spot_runner_mobile/features/event/screens/event_form.dart'; 
import 'package:spot_runner_mobile/features/event/screens/detailevent_page.dart';
import 'package:spot_runner_mobile/features/review/screens/review_modal.dart';
import 'package:spot_runner_mobile/features/review/service/review_service.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  // State untuk menyimpan review status
  Map<String, bool> _userReviewStatus = {};
  bool _isLoadingReviews = false;

  @override
  void initState() {
    super.initState();
    _checkUserReviews();
  }

  Future<List<dynamic>> fetchEvents() async {
    var url = Uri.parse(ApiConfig.eventJson); 
    var response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(utf8.decode(response.bodyBytes));
      return data;
    } else {
      throw Exception('Failed to fetch events');
    }
  }

  // Method untuk cek review status user
  Future<void> _checkUserReviews() async {
    final request = context.read<CookieRequest>();
    
    if (!request.loggedIn) {
      print('❌ User not logged in');
      return;
    }
    
    setState(() {
      _isLoadingReviews = true;
    });

    try {
      print('🔄 Fetching user reviews...');
      
      // Get all reviews dari user ini
      final reviewEntry = await ReviewService.getAllReviews(request);
      
      print('📦 Got ${reviewEntry?.data.length ?? 0} reviews');
      
      // Build map: eventId -> hasReviewed
      final Map<String, bool> statusMap = {};
      for (var review in reviewEntry?.data ?? []) {
        print('✅ Review found for event: ${review.eventId}');
        statusMap[review.eventId] = true;
      }
      
      print('📊 Review status map: $statusMap');
      
      if (mounted) {
        setState(() {
          _userReviewStatus = statusMap;
          _isLoadingReviews = false;
        });
        print('✅ Review status updated in UI');
      }
    } catch (e) {
      print('❌ Error checking reviews: $e');
      if (mounted) {
        setState(() {
          _userReviewStatus = {}; // Reset ke empty map
          _isLoadingReviews = false;
        });
      }
    }
  }

  // Method untuk cek apakah user sudah review event tertentu
  bool _hasUserReviewedEvent(String eventId) {
    return _userReviewStatus[eventId] == true;
  }

  Future<void> _handleAddReview(BuildContext context, Map<String, dynamic> event) async {
    final request = context.read<CookieRequest>();
    
    // Check if user is logged in
    if (!request.loggedIn) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first to add a review'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show review modal
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReviewModal(
        eventName: event['name'],
        eventId: event['id'].toString(),
        reviewId: null, // null = mode create
        initialRating: 5,
        initialReview: '',
        onSubmit: (rating, reviewText) async {
          final response = await ReviewService.createReview(
            request,
            eventId: event['id'].toString(),
            rating: rating,
            reviewText: reviewText,
          );

          if (!response['success']) {
            throw Exception(response['message']);
          }
        },
      ),
    );

    if (!mounted || result != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review submitted successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // Refresh review status
    await _checkUserReviews();
    
    // Refresh list
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final dynamic sessionUserId = request.jsonData['user_id'];
    final String userRole = request.jsonData['role'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event List'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No events available."));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final event = snapshot.data![index];
                
                // Check if user is the event owner
                dynamic eventOwnerId;
                if (event['user_eo'] is Map) {
                  eventOwnerId = event['user_eo']['pk'] ?? event['user_eo']['id'];
                } else {
                  eventOwnerId = event['user_eo'];
                }
                
                bool isOwner = false;
                if (sessionUserId != null && eventOwnerId != null) {
                  isOwner = sessionUserId.toString() == eventOwnerId.toString();
                }

                // Check event status
                String eventStatus = event['event_status'] ?? '';
                bool isFinished = eventStatus == 'finished';
                bool isRunner = userRole.toLowerCase() == 'runner';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailPage(eventId: event['id'].toString()),
                            ),
                          );
                          // Refresh review status setelah kembali dari detail page
                          if (result == true || result == null) {
                            await _checkUserReviews();
                            setState(() {});
                          }
                        },
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                event['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            if (isFinished)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Finished',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              event['description'], 
                              maxLines: 2, 
                              overflow: TextOverflow.ellipsis
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(event['location']?.toString().replaceAll('_', ' ') ?? '-'),
                              ],
                            ),
                          ],
                        ),
                        trailing: isOwner
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF1D4ED8)),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditEventFormPage(event: event),
                                        ),
                                      );
                                      if (result == true) {
                                        setState(() {});
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete this event?'),
                                          content: Text('Are you sure you want to delete "${event['name']}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                await _deleteEvent(event['id'].toString());
                                              },
                                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              )
                            : null,
                      ),
                      // Tombol Review
                      if (isRunner && isFinished && !isOwner)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: _hasUserReviewedEvent(event['id'].toString())
                                ? Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.grey[600], size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Already Reviewed',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () => _handleAddReview(context, event),
                                    icon: const Icon(Icons.rate_review, size: 18),
                                    label: const Text('Add Review'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFA3E635),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: userRole.toLowerCase() == 'event_organizer'
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EventFormPage(),
                  ),
                );
                if (result == true) {
                  setState(() {});
                }
              },
              backgroundColor: const Color(0xFF1D4ED8),
              tooltip: 'Add Event',
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Future<void> _deleteEvent(String id) async {
    final Uri url = Uri.parse(ApiConfig.deleteEventUrl(id));
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Event deleted successfully!"), backgroundColor: Colors.green),
          );
          setState(() {});
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete: ${response.statusCode}"), backgroundColor: Colors.red),
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
}