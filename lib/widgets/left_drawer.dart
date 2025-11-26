import 'package:flutter/material.dart';
import 'package:spot_runner_mobile/screens/menu.dart';
// : Impor halaman NewsFormPage jika sudah dibuat
// import 'package:football_news/screens/newslist_form.dart';
// import 'package:football_news/screens/news_entry_list.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Bagian atas (scrollable)
          Expanded(
            child: ListView(
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
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

                // ListTile lain
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
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                ),
                ListTile(
                  leading: const Icon(Icons.account_box),
                  title: const Text('Profile'),
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag_rounded),
                  title: const Text('Merchandise'),
                ),
              ],
            ),
          ),

          // Bagian bawah (sticky)
          const Divider(),

          // Tombol Sign Out atau Sign In
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              "Sign Out",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              // TODO: Implementasi Logout
            },
          ),
          ListTile(
            leading: Icon(Icons.login, color: Colors.blue),
            title: Text(
              "Sign In",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              // TODO: Implementasi Logout
            },
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

}