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

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  Future<List<dynamic>> fetchEvents() async {
    var url = Uri.parse('http://localhost:8000/event/json/'); 
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
        onSubmit: (rating, reviewText) async {
          // Submit review
          final response = await ReviewService.createReview(
            request,
            eventId: event['id'].toString(),
            rating: rating,
            reviewText: reviewText,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['message']),
                backgroundColor: response['success'] ? Colors.green : Colors.red,
              ),
            );
          }
        },
      ),
    );

    // Refresh list if review was added
    if (result == true && mounted) {
      setState(() {});
    }
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
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailPage(eventId: event['id'].toString()),
                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      event['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(event['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(
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
                            Text(event['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
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
                      
                      // Add Review Button (only for runners on finished events)
                      if (isRunner && isFinished && !isOwner)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
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
    final Uri url = Uri.parse('http://localhost:8000/event/delete-flutter/$id/');
    
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