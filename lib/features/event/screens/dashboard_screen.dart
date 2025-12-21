import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spot_runner_mobile/core/models/event_entry.dart';
import 'package:spot_runner_mobile/core/models/user_entry.dart';
import 'package:spot_runner_mobile/core/widgets/left_drawer.dart';
import 'package:spot_runner_mobile/features/event/screens/event_form.dart';

class DashboardScreen extends StatelessWidget {
  final UserProfile? userProfile;
  final List<EventEntry> events;

  const DashboardScreen({
    Key? key,
    required this.userProfile,
    required this.events,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Memastikan tidak error jika userProfile null
    final safeUserProfile = userProfile ??
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

  Widget _buildProfileSection(UserProfile user) {
    // MENGAMBIL NILAI VALID DARI MODEL
    final String username = user.username;
    final String? profilePicture = user.details?.profilePicture;
    
    // Mengambil data dari nested 'details' dengan fallback nilai default
    final int totalEvents = user.details?.totalEvents ?? 0;
    final double rating = user.details?.rating ?? 0.0;
    final String baseLocation = (user.details?.baseLocation == null || user.details!.baseLocation.isEmpty) 
                                ? "Location not set" 
                                : user.details!.baseLocation;
     
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
                      ? Image.network(profilePicture, fit: BoxFit.cover, 
                          errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.directions_run, color: Colors.lightGreen, size: 30))
                      : const Icon(Icons.directions_run, color: Colors.lightGreen, size: 30),
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
          _buildDetailRow(Icons.person_outline, "Total Events", "$totalEvents events"),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.calendar_today_outlined, "Joined", joinedDate),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.location_on_outlined, "Base Location", baseLocation),
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
          )
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
            Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EventFormPage())),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D4ED8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("Create new event", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyEventsState() {
    return const Center(child: Text("No events found"));
  }
}

class EventCard extends StatelessWidget {
  final EventEntry event;
  const EventCard({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String statusLower = event.eventStatus.toLowerCase().replaceAll("_", " ");
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Status: ${event.eventStatus}"),
          const SizedBox(height: 12),
          // Menggunakan DateFormat valid
          Text("Date: ${DateFormat('dd MMM yyyy').format(event.eventDate)}"),
          Text("Location: ${event.location}"),
        ],
      ),
    );
  }
}