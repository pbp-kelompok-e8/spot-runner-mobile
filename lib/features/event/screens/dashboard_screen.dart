import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spot_runner_mobile/core/models/event_entry.dart';
import 'package:spot_runner_mobile/core/models/user_entry.dart';
import 'package:spot_runner_mobile/core/widgets/left_drawer.dart';

class DashboardScreen extends StatelessWidget {
  final UserProfile? userProfile; // Ubah menjadi nullable
  final List<EventDetail> events;

  const DashboardScreen({
    Key? key,
    required this.userProfile, // Bisa null sekarang
    required this.events,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Buat safe user profile untuk menghindari null
    final safeUserProfile = userProfile ?? UserProfile(
      id: 0,
      username: 'Guest',
      email: '',
      role: 'guest',
      details: null,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      drawer: const LeftDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(safeUserProfile),
            const SizedBox(height: 24),
            const Text(
              "Your Events",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildCreateEventButton(),
            const SizedBox(height: 24),
            
            // Tampilkan events atau pesan kosong
            if (events.isEmpty)
              _buildEmptyEventsState()
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: events.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return EventCard(event: events[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyEventsState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.event_note, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No events yet",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Create your first event to get started",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.blueAccent, size: 30),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Spot",
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              fontSize: 24,
            ),
          ),
          Text(
            "Runner",
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.directions_run, color: Colors.blue[700]),
        ],
      ),
    );
  }

  Widget _buildProfileSection(UserProfile userProfile) {
    // Ekstrak data dengan null safety
    final String username = userProfile.username;
    final String? profilePicture = userProfile.details?.profilePicture;
    final int totalEvents = userProfile.details?.totalEvents ?? 0;
    final double rating = userProfile.details?.rating ?? 0.0;
    final String baseLocation = userProfile.details?.baseLocation ?? "-";
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Picture
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade100, width: 2),
                  image: profilePicture != null && profilePicture.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(profilePicture),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profilePicture == null || profilePicture.isEmpty
                    ? const Icon(Icons.person, color: Colors.grey, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userProfile.role == 'event_organizer' 
                        ? "Organized By" 
                        : "User Profile",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (userProfile.role.isNotEmpty)
                    Text(
                      userProfile.role == 'event_organizer' 
                          ? 'Event Organizer' 
                          : userProfile.role == 'runner' 
                              ? 'Runner' 
                              : 'Guest',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          
          // Details List
          _buildDetailRow(Icons.event_note, "Total Events", 
              "$totalEvents events"),
          const SizedBox(height: 12),
          
          // Joined date - menggunakan placeholder atau bisa dari API jika ada
          _buildDetailRow(Icons.calendar_today_outlined, "Joined", 
              _getJoinedDate(userProfile)),
          const SizedBox(height: 12),
          
          _buildDetailRow(Icons.location_on_outlined, "Base Location", 
              baseLocation),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(),
          ),
          
          // Rating Section (hanya untuk event organizer)
          if (userProfile.role == 'event_organizer')
            Column(
              children: [
                const Text(
                  "Rating & Review",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.lightGreen, size: 28),
                    const SizedBox(width: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(
                            text: "/5.0 rating",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "(Based on ${totalEvents > 0 ? totalEvents : 0} events)",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                const Text(
                  "Account Type",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    userProfile.role == 'runner' ? 'Runner Account' : 'Guest Account',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _getJoinedDate(UserProfile userProfile) {
    // Jika ingin dinamis, bisa dari API
    // Untuk sementara gunakan placeholder
    if (userProfile.id == 0) {
      return "N/A";
    }
    // Bisa juga menggunakan created_at dari user jika ada di model
    return "15 Dec 2024"; // Placeholder
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreateEventButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          // Action create event
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2B65EC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text(
          "Create new event +",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final EventDetail event;

  const EventCard({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine Color Scheme based on status
    Color statusBgColor;
    Color statusTextColor;
    Color borderColor;

    // Normalizing status string for checking
    String status = event.eventStatus.toLowerCase();

    if (status.contains("on going") || status.contains("ongoing")) {
      statusBgColor = Colors.blue.shade50;
      statusTextColor = Colors.blue.shade700;
      borderColor = Colors.blue.shade200;
    } else if (status.contains("finished")) {
      statusBgColor = Colors.green.shade50;
      statusTextColor = Colors.green.shade700;
      borderColor = Colors.green.shade200;
    } else if (status.contains("canceled") || status.contains("cancelled")) {
      statusBgColor = Colors.red.shade50;
      statusTextColor = Colors.red.shade700;
      borderColor = Colors.red.shade200;
    } else if (status.contains("coming soon") || status.contains("upcoming")) {
      statusBgColor = Colors.orange.shade50;
      statusTextColor = Colors.orange.shade700;
      borderColor = Colors.orange.shade200;
    } else {
      // Default
      statusBgColor = Colors.grey.shade100;
      statusTextColor = Colors.grey.shade700;
      borderColor = Colors.grey.shade300;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              event.eventStatus,
              style: TextStyle(
                color: statusTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (status.contains("finished") || status.contains("canceled") || status.contains("cancelled"))
                const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(Icons.calendar_today, "Date",
              DateFormat('dd MMM yyyy').format(event.eventDate)),
          const SizedBox(height: 8),
          
          _buildInfoRow(Icons.location_on_outlined, "Location", 
              event.location.isNotEmpty ? event.location : "Location not set"),
          const SizedBox(height: 8),
          
          _buildInfoRow(Icons.run_circle_outlined, "Type",
              event.eventCategories.isNotEmpty 
                  ? event.eventCategories.first 
                  : "Event"),
          
          const SizedBox(height: 16),
          
          const Text(
            "Event ID",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          
          Text(
            "ID: ${event.id}", 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              // Edit button hanya untuk status tertentu
              if (status.contains("on going") || status.contains("coming soon") || status.contains("upcoming")) 
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Edit action
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blue),
                    label: const Text("Edit Detail", style: TextStyle(color: Colors.blue)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ),
              
              if (status.contains("on going") || status.contains("coming soon") || status.contains("upcoming")) 
                const SizedBox(width: 12),
              
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Delete action
                  },
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text("Delete Event", style: TextStyle(color: Colors.red)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}