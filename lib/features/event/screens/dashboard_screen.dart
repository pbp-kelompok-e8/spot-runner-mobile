import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spot_runner_mobile/core/models/event_entry.dart';
import 'package:spot_runner_mobile/core/models/user_entry.dart';
import 'package:spot_runner_mobile/core/widgets/left_drawer.dart';
import 'package:spot_runner_mobile/features/event/screens/event_form.dart';

class DashboardScreen extends StatelessWidget {
  final UserProfile? userProfile;
  final List<EventDetail> events;

  const DashboardScreen({
    Key? key,
    required this.userProfile,
    required this.events,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safe User Profile
    final safeUserProfile = userProfile ??
        UserProfile(
          id: 0,
          username: 'Guest',
          email: '',
          role: 'guest',
          details: null,
        );

    return Scaffold(
      backgroundColor: Colors.white, // Background bersih
      appBar: _buildAppBar(),
      drawer: const LeftDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Card Section
            _buildProfileSection(safeUserProfile),
            
            const SizedBox(height: 32),
            
            // 2. Header "Your Event"
            const Text(
              "Your Event",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            
            // 3. Create Button
            _buildCreateEventButton(context),
            
            const SizedBox(height: 24),

            // 4. Events List
            if (events.isEmpty)
              _buildEmptyEventsState()
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: events.length,
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  return EventCard(event: events[index]);
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

  Widget _buildProfileSection(UserProfile userProfile) {
    final String username = userProfile.username;
    // Gunakan logo default jika tidak ada gambar (sesuai gambar: ikon sepatu hijau)
    final String? profilePicture = userProfile.details?.profilePicture;
    final int totalEvents = userProfile.details?.totalEvents ?? 3; // Hardcode contoh agar sesuai gambar
    final double rating = userProfile.details?.rating ?? 4.95;
    final String baseLocation = userProfile.details?.baseLocation ?? "San Miguel de Cozumel, Mexico";
    final String joinedDate = "15 Dec 2024"; 

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Shadow halus
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
          // Header Profile: Logo & Name
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade100),
                  color: Colors.white,
                ),
                // Menggunakan icon sepatu lari sebagai placeholder mirip gambar
                child: profilePicture != null && profilePicture.isNotEmpty
                    ? CircleAvatar(backgroundImage: NetworkImage(profilePicture))
                    : const Icon(Icons.directions_run, color: Colors.lightGreen, size: 30),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Organized By",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    userProfile.role == 'event_organizer' ? "Max Community" : username, // Placeholder Name
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
          
          // Info List
          _buildDetailRow(Icons.person_outline, "Total Events", "$totalEvents events"),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.calendar_today_outlined, "Joined", joinedDate),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.location_on_outlined, "Base Location", baseLocation),
          
          const SizedBox(height: 24),
          const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),

          // Rating Section
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
                    const Icon(Icons.star, color: Color(0xFFA3E635), size: 28), // Lime Green Icon
                    const SizedBox(width: 8),
                    Text(
                      rating.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "/5.0 rating (12 responden)",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.grey[400]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateEventButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to EventFormPage
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EventFormPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D4ED8), // Royal Blue
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Create new event",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            SizedBox(width: 8),
            Icon(Icons.add, color: Colors.white),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyEventsState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text("No events yet", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final EventDetail event;

  const EventCard({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Determine Status Styling based on Django Logic
    // Colors based on image
    Color statusBgColor;
    Color statusTextColor;
    Color borderColor;
    String statusText = event.eventStatus;

    final String statusLower = event.eventStatus.toLowerCase().replaceAll("_", " ");
    
    // Default styling (Blue/Ongoing)
    if (statusLower.contains("finished")) {
      // Green Theme
      statusBgColor = const Color(0xFFDCFCE7); // Light Green
      statusTextColor = const Color(0xFF15803D); // Dark Green
      borderColor = const Color(0xFF86EFAC); // Green Border
    } else if (statusLower.contains("cancel")) {
      // Red Theme
      statusBgColor = const Color(0xFFFEE2E2); // Light Red
      statusTextColor = const Color(0xFFB91C1C); // Dark Red
      borderColor = const Color(0xFFFCA5A5); // Red Border
    } else if (statusLower.contains("coming soon")) {
       // Yellow/Orange Theme (Optional, but using blue logic for now as per image generic blue)
      statusBgColor = const Color(0xFFFEF9C3);
      statusTextColor = const Color(0xFFA16207);
      borderColor = const Color(0xFFFDE047);
    } else {
      // "On Going" - Blue Theme
      statusBgColor = const Color(0xFFDBEAFE); // Light Blue
      statusTextColor = const Color(0xFF1D4ED8); // Dark Blue
      borderColor = const Color(0xFF93C5FD); // Blue Border
    }

    // Capitalize Display Text
    String displayStatus = statusText.split('_').map((word) => 
        word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Chip + Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayStatus,
                      style: TextStyle(
                        color: statusTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    // Jika Finished, ada bintang di dalam chip seperti gambar ke-3
                    if (statusLower.contains("finished")) ...[
                       const SizedBox(width: 4),
                       Icon(Icons.star_border, size: 14, color: statusTextColor),
                       Text(" (4.5)", style: TextStyle(fontSize: 12, color: statusTextColor)),
                    ]
                  ],
                ),
              ),
              
              // Three dot menu only for Finished/Canceled usually
              if (!statusLower.contains("on going"))
                const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Event Title
          Text(
            event.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          
          // Details
          _buildInfoRow(Icons.calendar_today, "Date", DateFormat('dd MMM yyyy').format(event.eventDate)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, "Location", event.location.isNotEmpty ? event.location : "Location unset"),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.directions_run, "Type", event.eventCategories.isNotEmpty ? event.eventCategories.join(", ") : "Marathon"),
          
          const SizedBox(height: 16),
          
          // Participant ID Section (Sesuai Gambar)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Participant ID",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Text(
                "DFR-125-563-215", // Placeholder ID static sesuai gambar
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          _buildActionButtons(statusLower, context),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        SizedBox(
          width: 70, // Fixed width for label alignment
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF333333),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String status, BuildContext context) {
    // Style for Red Delete Button (Full Width)
    final ButtonStyle deleteFullStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFEE2E2), // Pinkish Red Bg
      foregroundColor: const Color(0xFFEF4444), // Red Text
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    // Style for Edit Button (Blue Outlined feel)
    final ButtonStyle editStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFEFF6FF), // Light Blue Bg
      foregroundColor: const Color(0xFF3B82F6), // Blue Text
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    // If Ongoing -> Show Edit AND Delete side by side
    if (status.contains("on going") || status.contains("coming soon")) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text("Edit Detail"),
              style: editStyle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text("Delete Event"),
              style: deleteFullStyle,
            ),
          ),
        ],
      );
    } 
    // If Finished or Canceled -> Show ONLY Delete (Full Width)
    else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text("Delete Event"),
          style: deleteFullStyle,
        ),
      );
    }
  }
}