import 'dart:convert'; // Diperlukan untuk jsonEncode
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/core/screens/menu.dart';
import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:spot_runner_mobile/features/event/screens/dashboard_screen.dart';
import 'package:spot_runner_mobile/features/event/screens/profile_screen.dart' hide UserProfile;

// TODO: Sesuaikan import ini dengan lokasi file model Anda yang sebenarnya
import 'package:spot_runner_mobile/core/models/event_entry.dart'; 
import 'package:spot_runner_mobile/core/models/user_entry.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/features/auth/screens/profile.dart';
import 'package:spot_runner_mobile/features/merchandise/screens/merchandise_page.dart';

class LeftDrawer extends StatelessWidget {
  final String username;
  const LeftDrawer({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Drawer(
      child: Column(
        children: [
          // Bagian atas (scrollable)
          Expanded(
            child: ListView(
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Color(0xFF1D4ED8)),
                  child: Column(
                    children: [
                      Text(
                        'Spot Runner',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Padding(padding: EdgeInsets.all(10)),
                      Text(
                        "Step Into the global Marathon Spirit",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // ListTile Menu
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyHomePage(username: username),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  onTap: () async {
                    // Tampilkan loading snackbar agar user tahu proses sedang berjalan
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Loading Dashboard data..."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }

                    try {
                      // 1. Fetch Data User Profile
                      final userResponse = await request.get(
                          'http://127.0.0.1:8000/api/profile/'
                      );
                      
                      print('DEBUG - User Response: $userResponse');
                      print('DEBUG - User Response Type: ${userResponse.runtimeType}');

                      // Parse user profile - handle both single object and list
                      UserProfile userProfile;
                      if (userResponse is List && userResponse.isNotEmpty) {
                        // Response adalah list, ambil elemen pertama
                        userProfile = UserProfile.fromJson(
                          Map<String, dynamic>.from(userResponse[0] as Map)
                        );
                      } else if (userResponse is Map) {
                        // Response adalah single object
                        userProfile = UserProfile.fromJson(
                          Map<String, dynamic>.from(userResponse)
                        );
                      } else {
                        throw Exception("Invalid user profile response format: ${userResponse.runtimeType}");
                      }

                      // 2. Fetch Data Events
                      final eventResponse = await request.get(
                          'http://127.0.0.1:8000/api/events/'
                      );
                      
                      print('DEBUG - Event Response: $eventResponse');
                      print('DEBUG - Event Response Type: ${eventResponse.runtimeType}');

                      // Parse events
                      List<EventDetail> events = [];
                      if (eventResponse is List) {
                        events = eventResponse
                            .map((item) => EventDetail.fromJson(
                              Map<String, dynamic>.from(item as Map)
                            ))
                            .toList();
                      } else {
                        throw Exception("Invalid events response format: ${eventResponse.runtimeType}");
                      }

                      // 3. Navigasi ke DashboardScreen dengan membawa data
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DashboardScreen(
                              userProfile: userProfile,
                              events: events,
                            ),
                          ),
                        );
                      }
                    } catch (e, stackTrace) {
                      // Error handling jika fetch gagal
                      print('ERROR: $e');
                      print('STACK TRACE: $stackTrace');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Gagal memuat data: ${e.toString()}"),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_box),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag_rounded),
                  title: const Text('Merchandise'),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MerchandisePage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bagian bawah (sticky)
          const Divider(),

          // Tombol Sign Out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Sign Out",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              final response = await request.logout(ApiConfig.logout);
              String message = response["message"];
              if (context.mounted) {
                if (response['status']) {
                  String uname = response["username"];
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("$message Sampai jumpa, $uname.")),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}