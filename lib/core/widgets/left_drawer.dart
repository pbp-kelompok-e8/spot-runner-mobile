import 'dart:convert'; // Diperlukan untuk jsonEncode
import 'package:flutter/material.dart';
import 'package:spot_runner_mobile/core/screens/menu.dart';
import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:spot_runner_mobile/features/auth/screens/profile.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
// import 'package:spot_runner_mobile/features/event/screens/testpage.dart';
import 'package:spot_runner_mobile/core/providers/user_provider.dart';
import 'package:spot_runner_mobile/features/event/screens/dashboard_screen.dart';
import 'package:spot_runner_mobile/features/event/screens/testpage.dart';
import 'package:spot_runner_mobile/features/event/screens/profile_screen.dart';
import 'package:spot_runner_mobile/features/merchandise/screens/merchandise_page.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/core/models/event_entry.dart';
import 'package:spot_runner_mobile/core/models/user_entry.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final String userRole = request.jsonData['role'] ?? '';
    bool isRunner = userRole.toLowerCase() == 'runner';

    String username = "";
    try {
      username = context.watch<UserProvider>().username;
    } catch (e) {
      // Fallback jika provider error/belum ada
      username = "Guest";
    }

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
                      SizedBox(height: 16),
                      Text(
                        "SpotRunner",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          letterSpacing: -0.03,
                          color: Colors.white,
                        ),
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
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  },
                ),
                if (!isRunner)
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Dashboard'),
                    onTap: () async {
                      // Event Organizer dashboard: fetch profile and events first
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loading dashboard...')));
                      }

                      UserProfile? userProfile;
                      List<EventEntry> events = [];

                      try {
                        final profileResp = await request.get(ApiConfig.profile);
                        if (profileResp is Map<String, dynamic>) {
                          userProfile = UserProfile.fromJson(profileResp);
                        } else if (profileResp is List && profileResp.isNotEmpty) {
                          final first = profileResp.first;
                          if (first is Map<String, dynamic>) userProfile = UserProfile.fromJson(first);
                        }
                      } catch (e) {
                        // ignore and continue with null profile
                        userProfile = null;
                      }

                      try {
                        final eventsResp = await request.get(ApiConfig.events);
                        if (eventsResp is List) {
                          events = eventsResp.map((e) => EventEntry.fromJson(Map<String, dynamic>.from(e))).toList();
                        } else if (eventsResp is Map && eventsResp['results'] is List) {
                          events = List<EventEntry>.from((eventsResp['results'] as List).map(
                              (e) => EventEntry.fromJson(Map<String, dynamic>.from(e as Map<String, dynamic>))));
                        }
                      } catch (e) {
                        events = [];
                      }

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DashboardScreen(userProfile: userProfile, events: events)),
                        );
                      }
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.account_box),
                  title: const Text('Profile'),
                  onTap: () {
                    // Navigate to role-specific profile page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            isRunner ? RunnerProfilePage(username: username) : const ProfileScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag_rounded),
                  title: const Text('Merchandise'),
                  onTap: () {
                    // TODO: Navigate ke Merchandise
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MerchandisePage(),
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
              final response = await request.logout(
                ApiConfig.logout,
              );
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
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
