import 'package:flutter/material.dart';

// --- DATA MODELS ---
// Model data untuk mensimulasikan Event Organizer (User Login)
class EOUser {
  final String name;
  final String organizationName;
  final int totalEvents;
  final String joinDate;
  final String baseLocation;
  final double rating;
  final int totalReviews;

  EOUser({
    required this.name,
    required this.organizationName,
    required this.totalEvents,
    required this.joinDate,
    required this.baseLocation,
    required this.rating,
    required this.totalReviews,
  });
}

// Enum untuk status event agar styling otomatis menyesuaikan
enum EventStatus { onGoing, finished, canceled }

// Model data untuk setiap Event
class EventData {
  final String title;
  final String date;
  final String location;
  final String type;
  final String participantId;
  final EventStatus status;
  final double? rating; // Nullable, hanya ada jika selesai

  EventData({
    required this.title,
    required this.date,
    required this.location,
    required this.type,
    required this.participantId,
    required this.status,
    this.rating,
  });
}

// --- MAIN SCREEN ---
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. DATA DUMMY (Sesuaikan dengan data pengguna yang login di sini)
    final currentUser = EOUser(
      name: "Max Community",
      organizationName: "Max Community",
      totalEvents: 3,
      joinDate: "15 Dec 2024",
      baseLocation: "San Miguel de Cozumel, Mexico",
      rating: 4.95,
      totalReviews: 12,
    );

    // 2. DATA LIST EVENT
    final List<EventData> myEvents = [
      EventData(
        title: "RunThrough Running Grand Prix New Jersey Motorsports Park",
        date: "04 Dec 2022",
        location: "San Miguel de Cozumel, Mexico",
        type: "Half Marathon",
        participantId: "DFR- 125-563-215",
        status: EventStatus.onGoing,
      ),
      EventData(
        title: "RunThrough Running Grand Prix New Jersey Motorsports Park",
        date: "04 Dec 2022",
        location: "San Miguel de Cozumel, Mexico",
        type: "Half Marathon",
        participantId: "DFR- 125-563-215",
        status: EventStatus.finished,
        rating: 4.5,
      ),
      EventData(
        title: "RunThrough Running Grand Prix New Jersey Motorsports Park",
        date: "04 Dec 2022",
        location: "San Miguel de Cozumel, Mexico",
        type: "Half Marathon",
        participantId: "DFR- 125-563-215",
        status: EventStatus.finished,
        rating: 4.5,
      ),
      EventData(
        title: "RunThrough Running Grand Prix New Jersey Motorsports Park",
        date: "04 Dec 2022",
        location: "San Miguel de Cozumel, Mexico",
        type: "Half Marathon",
        participantId: "DFR- 125-563-215",
        status: EventStatus.canceled,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Dashboard EO", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Profil EO
            OrganizerProfileCard(user: currentUser),
            
            const SizedBox(height: 24),
            
            // Judul Section
            const Text(
              "Your Event",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tombol Create New Event
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Create new event",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8), // Biru tua
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // List Event Cards
            ListView.builder(
              shrinkWrap: true, // Agar bisa di dalam SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(),
              itemCount: myEvents.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: EventCard(event: myEvents[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET KOMPONEN ---

// 1. Widget Kartu Profil Organizer (Paling Atas)
class OrganizerProfileCard extends StatelessWidget {
  final EOUser user;

  const OrganizerProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Logo & Nama
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 1.5),
                ),
                child: const Icon(Icons.directions_run, color: Colors.green, size: 30),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Organized By", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    user.organizationName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          
          // Detail Info
          _buildDetailRow(Icons.person_outline, "Total Events", "${user.totalEvents} events"),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.calendar_today_outlined, "Joined", user.joinDate),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.location_on_outlined, "Base Location", user.baseLocation),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(),
          ),

          // Rating
          Column(
            children: [
              const Text(
                "Rating & Review",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Color(0xFFA3E635), size: 28), // Lime Green
                  const SizedBox(width: 8),
                  Text(
                    "${user.rating}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    "/5.0 rating (${user.totalReviews} responden)",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

// 2. Widget Kartu Event (Reusable untuk status Ongoing, Finished, Canceled)
class EventCard extends StatelessWidget {
  final EventData event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Tentukan warna tema berdasarkan status
    Color themeColor;
    Color bgColor;
    String statusText;

    switch (event.status) {
      case EventStatus.onGoing:
        themeColor = const Color(0xFF3B82F6); // Biru
        bgColor = const Color(0xFFDBEAFE); // Biru muda
        statusText = "On Going";
        break;
      case EventStatus.finished:
        themeColor = const Color(0xFF10B981); // Hijau
        bgColor = const Color(0xFFD1FAE5); // Hijau muda
        statusText = "Finished";
        break;
      case EventStatus.canceled:
        themeColor = const Color(0xFFEF4444); // Merah
        bgColor = const Color(0xFFFEE2E2); // Merah muda
        statusText = "Canceled";
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: themeColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Status Pill
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: themeColor == const Color(0xFFEF4444) ? const Color(0xFF991B1B) : const Color(0xFF1E40AF), // Adjust text contrast
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Jika status Finished, tampilkan Rating pill
                if (event.status == EventStatus.finished && event.rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_border, size: 16, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          "(${event.rating})",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                // Titik tiga menu (opsional)
                 if (event.status != EventStatus.onGoing)
                    const Icon(Icons.more_vert, color: Colors.grey),
              ],
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              event.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Divider(),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildEventInfoRow(Icons.calendar_today_outlined, "Date", event.date),
                const SizedBox(height: 8),
                _buildEventInfoRow(Icons.location_on_outlined, "Location", event.location),
                const SizedBox(height: 8),
                _buildEventInfoRow(Icons.directions_run, "Type", event.type),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Participant ID
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Participant ID", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  event.participantId,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildActionButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (event.status == EventStatus.onGoing) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
              label: const Text("Edit Detail", style: TextStyle(color: Color(0xFF2563EB))),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFF6FF),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
              label: const Text("Delete Event", style: TextStyle(color: Color(0xFFEF4444))),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      );
    } else {
      // Finished or Canceled -> Full Width Delete Button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
          label: const Text("Delete Event", style: TextStyle(color: Color(0xFFEF4444))),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFEF2F2),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }
  }
}