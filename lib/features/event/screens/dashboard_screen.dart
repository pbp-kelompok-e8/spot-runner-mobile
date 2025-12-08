import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pastikan add dependency intl di pubspec.yaml
import 'package:spot_runner_mobile/core/models/event_entry.dart';
import 'package:spot_runner_mobile/core/models/user_entry.dart';
import 'package:spot_runner_mobile/core/widgets/left_drawer.dart';

class DashboardScreen extends StatelessWidget {
  final UserProfile userProfile;
  final List<EventDetail> events;

  const DashboardScreen({
    Key? key,
    required this.userProfile,
    required this.events,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Background agak abu terang
      appBar: _buildAppBar(),
      drawer: const LeftDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            const SizedBox(height: 24),
            const Text(
              "Your Event",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildCreateEventButton(),
            const SizedBox(height: 24),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(), // Scroll via SingleChild
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

  // Widget _buildDrawer() {
  //   );
  // }

  Widget _buildProfileSection() {
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
              // Profile Picture Placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade100, width: 2),
                  image: userProfile.details?.profilePicture != null
                      ? DecorationImage(
                          image: NetworkImage(userProfile.details!.profilePicture!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: userProfile.details?.profilePicture == null
                    ? const Icon(Icons.person, color: Colors.grey, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Organized By",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userProfile.username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          // Details List
          _buildDetailRow(Icons.event_note, "Total Events",
              "${userProfile.details?.totalEvents ?? 0} events"),
          const SizedBox(height: 12),
          // Joined date is not in UserProfile model, using a hardcoded placeholder logic or generic
          _buildDetailRow(Icons.calendar_today_outlined, "Joined", "15 Dec 2024"), 
          const SizedBox(height: 12),
          _buildDetailRow(Icons.location_on_outlined, "Base Location",
              userProfile.details?.baseLocation ?? "-"),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(),
          ),
          
          // Rating Section
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
                          text: "${userProfile.details?.rating ?? 0}",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(
                          text: "/5.0 rating (12 responden)",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
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
          backgroundColor: const Color(0xFF2B65EC), // Royal Blue
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

    if (status.contains("on going")) {
      statusBgColor = Colors.blue.shade50;
      statusTextColor = Colors.blue.shade700;
      borderColor = Colors.blue.shade200;
    } else if (status.contains("finished")) {
      statusBgColor = Colors.green.shade50;
      statusTextColor = Colors.green.shade700;
      borderColor = Colors.green.shade200;
    } else if (status.contains("canceled")) {
      statusBgColor = Colors.red.shade50;
      statusTextColor = Colors.red.shade700;
      borderColor = Colors.red.shade200;
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
              event.eventStatus, // e.g. "On Going"
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
              if (status.contains("finished") || status.contains("canceled"))
                const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today, "Date",
              DateFormat('dd MMM yyyy').format(event.eventDate)),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on_outlined, "Location", event.location),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.run_circle_outlined, "Type",
              event.eventCategories.isNotEmpty ? event.eventCategories.first : "Event"),
          
          const SizedBox(height: 16),
          const Text(
            "Participant ID",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          // Using ID or creating a format similar to image "DFR-..."
          Text(
            "ID: ${event.id}", 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              // Edit button only for On Going events usually, but strictly following image:
              // Image 2 (On Going) has Edit & Delete.
              // Image 3 (Finished) has Delete only.
              if (status.contains("on going")) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blue),
                    label: const Text("Edit Detail", style: TextStyle(color: Colors.blue)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
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