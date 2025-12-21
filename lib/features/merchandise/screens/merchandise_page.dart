import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/features/merchandise/models/merchandise_model.dart';
import 'package:spot_runner_mobile/features/merchandise/widgets/product_card.dart'; // Import widget baru
import 'package:spot_runner_mobile/core/widgets/left_drawer.dart';
import 'package:spot_runner_mobile/features/merchandise/screens/add_product_page.dart';
import 'package:spot_runner_mobile/features/merchandise/screens/history_page.dart';
import 'dart:async';

class MerchandisePage extends StatefulWidget {
  const MerchandisePage({super.key});

  @override
  State<MerchandisePage> createState() => _MerchandisePageState();
}

class _MerchandisePageState extends State<MerchandisePage> {
  String selectedCategory = 'All';
  int userCoins = 0;
  String userType = 'guest';
  String username = 'Guest';
  bool isLoadingCoins = true;
  int _refreshKey = 0; // Key untuk force rebuild
  Timer? _refreshTimer; // Timer untuk auto refresh

  final List<Map<String, String>> categories = [
    {'value': 'All', 'label': 'All'},
    {'value': 'totebag', 'label': 'Tote Bag'},
    {'value': 'apparel', 'label': 'Apparel'},
    {'value': 'accessories', 'label': 'Accessories'},
    {'value': 'water_bottle', 'label': 'Water Bottle'},
  ];

  @override
  void initState() {
    super.initState();
    fetchUserCoins();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancel timer saat dispose
    super.dispose();
  }

  // Auto refresh setiap 30 detik untuk organizer
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && userType == 'organizer') {
        // debugPrint('Auto refreshing data for organizer...');
        fetchUserCoins();
        setState(() {
          _refreshKey++;
        });
      }
    });
  }

  Future<void> fetchUserCoins() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get(ApiConfig.userCoins);

      // debugPrint('User coins response: $response');

      if (mounted) {
        setState(() {
          userCoins = response['coins'] ?? 0;
          userType = response['user_type'] ?? 'guest';
          username =
              response['username'] ?? 'Guest'; // Ambil username dari response
          isLoadingCoins = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user coins: $e');
      if (mounted) {
        setState(() {
          isLoadingCoins = false;
          username = 'Guest';
        });
      }
    }
  }

  Future<List<Merchandise>> fetchMerchandise(CookieRequest request) async {
    String url = ApiConfig.merchandiseJson;
    if (selectedCategory != 'All') {
      url += '?category=$selectedCategory';
    }

    // Debug: Print URL
    // debugPrint('Fetching merchandise from: $url');

    try {
      final response = await request.get(url);

      // Debug: Print first item to see structure
      // if (response.isNotEmpty) {
      //   debugPrint('First item structure: ${response[0]}');
      // }

      // Debug: Print response
      // debugPrint('Merchandise response: $response');

      List<Merchandise> listMerchandise = [];
      for (var d in response) {
        if (d != null) {
          listMerchandise.add(Merchandise.fromJson(d));
        }
      }
      return listMerchandise;
    } catch (e) {
      debugPrint('Error fetching merchandise: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Merchandise',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: LeftDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchUserCoins();
          setState(() {
            _refreshKey++; // Force rebuild products
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coin Balance Card
                _buildCoinBalanceCard(),

                const SizedBox(height: 20),

                // Section Title
                const Text(
                  'Merchandise',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                // Category Filter
                _buildCategoryFilter(),

                const SizedBox(height: 20),

                // Add Product Button (Only for Organizers)
                if (userType == 'organizer') _buildAddProductButton(),

                const SizedBox(height: 16),

                // Products Grid
                FutureBuilder(
                  key: ValueKey(_refreshKey), // Force rebuild dengan key
                  future: fetchMerchandise(request),
                  builder: (context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      // Debug: Show error
                      debugPrint('Snapshot error: ${snapshot.error}');
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading merchandise',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.red[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 72,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No merchandise available',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.88,
                          ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        Merchandise merchandise = snapshot.data![index];
                        return ProductCard(
                          merchandise: merchandise,
                          onRefresh: () async {
                            debugPrint(
                              'ProductCard onRefresh called, calling setState',
                            );
                            await fetchUserCoins();
                            setState(() {
                              _refreshKey++;
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoinBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bagian Atas: Ikon Koin dan Info Saldo
          Row(
            children: [
              // Icon Koin
              Image.asset(
                'lib/assets/images/coin-icon.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.monetization_on,
                    color: Colors.amber.shade400,
                    size: 80,
                  );
                },
              ),
              const SizedBox(width: 20),
              // Teks Saldo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoadingCoins ? '...' : '$userCoins Coins',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1F26),
                      ),
                    ),
                    Text(
                      userType == 'organizer'
                          ? 'Total Earned'
                          : 'Sport Rewards',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tombol History
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 60),
              side: BorderSide(color: Colors.blueGrey.shade100, width: 1.2),
              shape: const StadiumBorder(),
              foregroundColor: Colors.blueGrey.shade600,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.history_rounded,
                  size: 24,
                  color: Colors.blueGrey.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    const Color primaryBlue = Color(0xFF1447E6);

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent, 
                highlightColor:
                    Colors.transparent, 
              ),
              child: FilterChip(
                selected: isSelected,
                label: Text(category['label']!),
                onSelected: (bool selected) {
                  setState(() {
                    selectedCategory = category['value']!;
                  });
                },
                showCheckmark: false,
                backgroundColor: Colors.white,
                selectedColor: primaryBlue,
                pressElevation: 0,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : primaryBlue,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
                shape: StadiumBorder(
                  side: BorderSide(color: primaryBlue, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddProductButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Navigate to add product page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          ).then((_) {
            setState(() {});
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Add New Product'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
