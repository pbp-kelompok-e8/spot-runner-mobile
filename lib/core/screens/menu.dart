//lib\core\screens\menu.dart
import 'package:flutter/material.dart';
// Import drawer widget
import 'package:spot_runner_mobile/core/widgets/left_drawer.dart';
// Import the moved ItemCard and ItemHomepage
import 'package:spot_runner_mobile/core/widgets/card.dart';
// Import review form (sesuaikan dengan path Anda)
// import 'package:spot_runner_mobile/review/screens/review_form.dart';

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  final String nama = "SpotRunner";
  final String npm = "1111";
  final String kelas = "E";

  // Gabungan semua item dari kedua versi + Review
  final List<ItemHomepage> items = [
    ItemHomepage("See Football News", Icons.newspaper),
    ItemHomepage("Add News", Icons.add),
    ItemHomepage("Review Event", Icons.rate_review), // Item baru untuk Review
    ItemHomepage("See Review", Icons.list),
    ItemHomepage("Logout", Icons.logout),
    ItemHomepage("Home", Icons.home),
    ItemHomepage("Dashboard", Icons.dashboard),
    ItemHomepage("Profile", Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Judul aplikasi dengan teks putih dan tebal
        title: const Text(
          'Football News',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      // Tambahkan drawer dari versi kedua
      drawer: LeftDrawer(),
      body: SingleChildScrollView(
        // Tambahkan SingleChildScrollView di sini
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // InfoCard dari versi pertama
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InfoCard(title: 'NPM', content: npm),
                  InfoCard(title: 'Name', content: nama),
                  InfoCard(title: 'Class', content: kelas),
                ],
              ),

              const SizedBox(height: 16.0),

              // Menempatkan widget berikutnya di tengah halaman
              Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text(
                      'Selamat datang di Football News',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                  ),

                  // Grid untuk menampilkan semua ItemCard
                  GridView.count(
                    primary: false,
                    padding: const EdgeInsets.all(20),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),

                    children: items.map((ItemHomepage item) {
                      return ItemCard(item);
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String content;

  const InfoCard({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: Container(
        width: MediaQuery.of(context).size.width / 3.5,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Text(content),
          ],
        ),
      ),
    );
  }
}