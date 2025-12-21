//lib\features\event_organizer\screens\eo_profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:intl/intl.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';

class EOProfilePage extends StatefulWidget {
  final String? eoId; // null = current user, ada value = view other EO
  
  const EOProfilePage({super.key, this.eoId});

  @override
  State<EOProfilePage> createState() => _EOProfilePageState();
}

class _EOProfilePageState extends State<EOProfilePage> {
  Map<String, dynamic>? _eoData;
  List<dynamic> _events = [];
  bool _isLoading = true;
  double _averageRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadEOProfile();
  }

  Future<void> _loadEOProfile() async {
    final request = context.read<CookieRequest>();
    
    try {
      // Get EO data
      String eoIdToFetch = widget.eoId ?? request.jsonData['user_id'].toString();
      
      final eoResponse = await request.get(ApiConfig.eventOrganizerJson());
      if (eoResponse['status'] == 'success') {
        List<dynamic> organizers = eoResponse['data'];
        var foundEO = organizers.firstWhere(
          (eo) => eo['user_id'].toString() == eoIdToFetch,
          orElse: () => null,
        );
        
        if (foundEO != null) {
          setState(() {
            _eoData = foundEO;
          });
          
          // Get events by this EO
          await _loadEOEvents(eoIdToFetch);
          
          // Calculate average rating from events
          _calculateAverageRating();
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading EO profile: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEOEvents(String eoId) async {
    final request = context.read<CookieRequest>();
    
    try {
      final response = await request.get(ApiConfig.eventJson);
      
      if (response is List) {
        setState(() {
          _events = response.where((event) {
            var eventOwnerId = event['user_eo'];
            if (eventOwnerId is Map) {
              eventOwnerId = eventOwnerId['pk'] ?? eventOwnerId['id'];
            }
            return eventOwnerId.toString() == eoId;
          }).toList();
        });
      }
    } catch (e) {
      print("Error loading events: $e");
    }
  }

  void _calculateAverageRating() async {
    final request = context.read<CookieRequest>();
    double totalRating = 0;
    int reviewCount = 0;
    
    for (var event in _events) {
      try {
        final reviewResponse = await request.get(
          ApiConfig.reviewsByEvent(event['id'].toString()),
        );
        
        if (reviewResponse['status'] == 'success' && reviewResponse['data'] != null) {
          List reviews = reviewResponse['data'];
          for (var review in reviews) {
            totalRating += review['rating'];
            reviewCount++;
          }
        }
      } catch (e) {
        print("Error getting reviews: $e");
      }
    }
    
    setState(() {
      _totalReviews = reviewCount;
      _averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_eoData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text("Event Organizer not found")),
      );
    }

    final String organizerName = _eoData!['organization_name'] ?? 'Unknown';
    final String baseLocation = _eoData!['base_location'] ?? 'Unknown';
    final int totalEvents = _events.length;
    final String profilePicture = _eoData!['profile_picture'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Organizer Profile',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section - Organized By
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Organized By',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFA3E635),
                        backgroundImage: profilePicture.isNotEmpty
                            ? NetworkImage(profilePicture)
                            : null,
                        child: profilePicture.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 30)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Organizer Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              organizerName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Community',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats
                  _buildStatRow(Icons.event_available, 'Total Events', '$totalEvents events'),
                  const SizedBox(height: 12),
                  _buildStatRow(Icons.calendar_today_outlined, 'Joined', 
                      _eoData!['created_at'] != null 
                          ? DateFormat('dd MMM yyyy').format(DateTime.parse(_eoData!['created_at']))
                          : '-'),
                  const SizedBox(height: 12),
                  _buildStatRow(Icons.location_on_outlined, 'Base Location', 
                      baseLocation.replaceAll('_', ' ')),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 8, color: Color(0xFFF3F4F6)),

            // Rating & Review Section
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rating & Review',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFA3E635),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _averageRating > 0 
                            ? _averageRating.toStringAsFixed(2)
                            : '0.00',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        '/5.0 rating ($_totalReviews reviews)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 8, color: Color(0xFFF3F4F6)),

            // Events Section
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All Event',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        '$totalEvents events',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Event List
                  if (_events.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No events yet',
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        return _buildEventCard(event);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final String image = event['image'] ?? '';
    final String name = event['name'] ?? 'Untitled Event';
    final String description = event['description'] ?? '';
    final String location = event['location'] ?? '';
    final int participants = event['total_participans'] ?? 0;
    final int capacity = event['capacity'] ?? 0;
    final String eventDate = event['event_date'] ?? '';
    final List categories = event['event_categories'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          if (image.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                image,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(Icons.broken_image, size: 40, color: Color(0xFF9CA3AF)),
                ),
              ),
            ),
          
          // Event Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Event Details
                _buildEventDetail(Icons.people_outline, '$participants/$capacity participants'),
                const SizedBox(height: 6),
                _buildEventDetail(Icons.calendar_today_outlined, 
                    eventDate.isNotEmpty 
                        ? DateFormat('dd MMM yyyy').format(DateTime.parse(eventDate))
                        : '-'),
                const SizedBox(height: 6),
                _buildEventDetail(Icons.location_on_outlined, location.replaceAll('_', ' ')),
                const SizedBox(height: 6),
                _buildEventDetail(Icons.run_circle_outlined, categories.join(', ').replaceAll('_', ' ')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}