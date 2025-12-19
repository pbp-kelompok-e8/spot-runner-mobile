import 'package:flutter/material.dart';
import 'package:spot_runner_mobile/core/screens/menu.dart';
import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:spot_runner_mobile/features/auth/screens/profile.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/features/event/screens/testpage.dart';

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
                      MaterialPageRoute(builder: (context) => MyHomePage(username: username)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  onTap: () {
                    // TODO: Navigate ke Dashboard
                    Navigator.push(context, MaterialPageRoute(builder: (context) => EventListPage() ));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_box),
                  title: const Text('Profile'),
                  onTap: () {
                    // TODO: Navigate ke Profile
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => RunnerProfilePage(username: username)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag_rounded),
                  title: const Text('Merchandise'),
                  onTap: () {
                    // TODO: Navigate ke Merchandise
                    Navigator.pop(context);
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
                "http://localhost:8000/auth/logout/",
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
