import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:spot_runner_mobile/core/widgets/left_drawer.dart';
import 'package:spot_runner_mobile/core/models/event_entry.dart';
import 'package:spot_runner_mobile/features/event/screens/detailevent_page.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/core/widgets/custom_app_bar.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // [TAMBAHAN 1] Controller untuk mengatur scroll
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = 'All';

  final List<Map<String, String>> _categories = [
    {'label': 'All', 'value': 'All'},
    {'label': 'Fun Run (3K)', 'value': 'fun_run'},
    {'label': '5K Race', 'value': '5k'},
    {'label': '10K Race', 'value': '10k'},
    {'label': 'Half Marathon (21K)', 'value': 'half_marathon'},
    {'label': 'Full Marathon (42K)', 'value': 'full_marathon'},
  ];

  final Color _primaryBlue = const Color(0xFF1447E6);
  final Color _textDark = const Color(0xFF111928);
  final Color _textGrey = const Color(0xFF6B7280);
  final Color _borderColor = const Color(0xFFE4E4E4);
  final Color _badgeBg = const Color(0xFFFEF9C2);
  final Color _badgeText = const Color(0xFF894B00);

  // Helper title case
  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}";
        })
        .join(' ');
  }

  String getBaseUrl() {
    return ApiConfig.baseUrl;
  }

  Future<List<EventEntry>> fetchEvents(CookieRequest request) async {
    final response = await request.get(ApiConfig.eventJson);

    List<EventEntry> listEvents = [];
    for (var d in response) {
      if (d != null) {
        listEvents.add(EventEntry.fromJson(d));
      }
    }
    return listEvents;
  }

  // [TAMBAHAN 2] Dispose controller saat widget dihancurkan untuk mencegah memory leak
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(),
      drawer: const LeftDrawer(),
      body: SingleChildScrollView(
        // [TAMBAHAN 3] Pasang controller ke SingleChildScrollView
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            Padding(
              padding: const EdgeInsets.only(
                top: 32,
                left: 20,
                right: 20,
                bottom: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Discover Marathon Events",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      height: 1.5,
                      color: const Color(0xFF1E2939),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        bool isSelected =
                            _selectedCategory == category['value'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: InkWell(
                            onTap: () => setState(
                              () => _selectedCategory = category['value']!,
                            ),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? _primaryBlue : Colors.white,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: _primaryBlue,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                category['label']!,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : _primaryBlue,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FutureBuilder(
                    future: fetchEvents(request),
                    builder:
                        (context, AsyncSnapshot<List<EventEntry>> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Error: ${snapshot.error}",
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return _buildEmptyState();
                          } else {
                            var events = snapshot.data!;

                            if (_selectedCategory != 'All') {
                              events = events.where((e) {
                                String filterKeyword = _selectedCategory
                                    .toLowerCase()
                                    .replaceAll('_', ' ');
                                return e.eventCategories.any(
                                  (cat) => cat
                                      .toLowerCase()
                                      .replaceAll('_', ' ')
                                      .contains(filterKeyword),
                                );
                              }).toList();
                            }

                            if (events.isEmpty) return _buildEmptyState();

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: events.length,
                              separatorBuilder: (ctx, index) =>
                                  const SizedBox(height: 20),
                              itemBuilder: (context, index) {
                                return _buildEventCard(events[index]);
                              },
                            );
                          }
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

  Widget _buildHeroSection() {
    return SizedBox(
      width: double.infinity,
      height: 340, // Tinggi Hero Section yang kita gunakan sebagai offset
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'lib/assets/images/banner-hero.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0.6, 0),
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.grey[300]),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Run beyond your limits",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Step Into the Global\nMarathon Spirit",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  // [TAMBAHAN 4] Fungsi Scroll saat tombol ditekan
                  onPressed: () {
                    _scrollController.animateTo(
                      340, // Scroll ke offset 340 (tepat di bawah Hero Section)
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA0E228),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    "Explore Now",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventEntry event) {
    String imageUrl = event.image;
    if (!imageUrl.startsWith('http')) {
      imageUrl = "${getBaseUrl()}/media/$imageUrl";
    }

    String dateStr = DateFormat('dd MMM yyyy (E)').format(event.eventDate);
    String typesStr = event.eventCategories
        .map((e) => _toTitleCase(e))
        .join(", ");
    if (typesStr.isEmpty) typesStr = "Marathon";

    bool isTopRun = event.totalParticipans > 50;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 183,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (isTopRun)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Top Run",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: _badgeText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    height: 1.6,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    height: 1.5,
                    color: _textGrey,
                  ),
                ),
                const SizedBox(height: 20),

                _buildInfoRow(
                  Icons.group_outlined,
                  "${event.totalParticipans}/${event.capacity} Participants",
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today_outlined, dateStr),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on_outlined, event.location),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.run_circle_outlined, typesStr),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EventDetailPage(eventId: event.id),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFDFE4EA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "See Details",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: const Color(0xFF637381),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: Color(0xFF637381),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF212121)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Color(0xFF212121),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Image.asset(
            'lib/assets/images/no-event-found.png',
            height: 100,
            errorBuilder: (ctx, err, stack) =>
                const Icon(Icons.search_off, size: 60, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text("No events found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
