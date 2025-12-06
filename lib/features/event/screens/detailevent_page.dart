import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:spot_runner_mobile/features/event/screens/editevent_form.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late Future<Map<String, dynamic>> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventFuture = fetchEventDetail();
  }

  Future<Map<String, dynamic>> fetchEventDetail() async {
    final request = context.read<CookieRequest>();
    final response = await request.get(
      'http://localhost:8000/event/json/${widget.eventId}/',
    );

    if (response is List) {
      return response[0];
    }
    return response;
  }

  Future<void> _deleteEvent(String id) async {
    final Uri url = Uri.parse(
      'http://localhost:8000/event/delete-flutter/$id/',
    );
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(
        url.toString(),
        {},
      );
      if (response['status'] == 'success' || response['message'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Event deleted successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); 
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

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

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
          String? rawImage = event['image'];
          bool hasImage =
              rawImage != null && rawImage.isNotEmpty && rawImage != "null";
          final String imageUrl = hasImage ? rawImage! : '';

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
              SliverAppBar(
                expandedHeight: hasImage ? 200.0 : null,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: hasImage
                    ? 0
                    : 2, 
                flexibleSpace: hasImage
                    ? FlexibleSpaceBar(
                        background: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      )
                    : null,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasImage
                        ? Colors.white
                        : Colors
                              .transparent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: hasImage ? Colors.black : Colors.black,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                title: !hasImage
                    ? Text(title, style: const TextStyle(color: Colors.black))
                    : null,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isOwner)
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.edit, size: 14),
                                  label: const Text(
                                    "Edit",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue[700],
                                    side: BorderSide(color: Colors.blue[700]!),
                                    padding: EdgeInsets.zero,
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
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.delete, size: 14),
                                  label: const Text(
                                    "Delete",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red[700],
                                    side: BorderSide(color: Colors.red[700]!),
                                    backgroundColor: Colors.red[50],
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () => _showDeleteDialog(context),
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (isOwner) const SizedBox(height: 20),
                      const Text(
                        "About This Event",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
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

                      const SizedBox(height: 20),

                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Registration Open until",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTimeBox("99", "Days"),
                                const SizedBox(width: 8),
                                _buildTimeBox("23", "Hours"),
                                const SizedBox(width: 8),
                                _buildTimeBox("59", "Mins"),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Deadline: ${event['regist_deadline'] != null ? DateFormat('dd MMM, HH:mm').format(DateTime.parse(event['regist_deadline'])) : '-'}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Races offered",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...categories
                          .map(
                            (cat) => Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SizedBox(
                                height: 45,
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  title: Text(
                                    cat.toString().toUpperCase().replaceAll(
                                      "_",
                                      " ",
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  trailing: Radio(
                                    value: false,
                                    groupValue: true,
                                    onChanged: (val) {},
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {},
                          child: const Text(
                            "Book Now",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.green[100],
                            child: const Icon(
                              Icons.person,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
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
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // --- REVIEWS ---
                      const Text(
                        "Rating & Review",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildReviewCard("Leticia Kutch", 4.75),
                            _buildReviewCard("John Doe", 5.0),
                            _buildReviewCard("Jane Smith", 4.0),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
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
