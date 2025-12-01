import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/features/merchandise/models/merchandise_model.dart';
import 'package:spot_runner_mobile/features/merchandise/widgets/product_card.dart'; // Import widget baru
import 'package:spot_runner_mobile/core/widgets/left_drawer.dart';

class MerchandisePage extends StatefulWidget {
  const MerchandisePage({super.key});

  @override
  State<MerchandisePage> createState() => _MerchandisePageState();
}

class _MerchandisePageState extends State<MerchandisePage> {
  String selectedCategory = 'All';
  int userCoins = 0;
  String userType = 'guest';
  bool isLoadingCoins = true;

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
  }

  Future<void> fetchUserCoins() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get(
        'http://localhost:8000/merchandise/user-coins/',
      );
      
      // Debug: Print response
      debugPrint('User coins response: $response');
      
      if (mounted) {
        setState(() {
          userCoins = response['coins'] ?? 0;
          userType = response['user_type'] ?? 'guest';
          isLoadingCoins = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user coins: $e');
      if (mounted) {
        setState(() {
          isLoadingCoins = false;
        });
      }
    }
  }

  Future<List<Merchandise>> fetchMerchandise(CookieRequest request) async {
    String url = 'http://localhost:8000/merchandise/json/';
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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const LeftDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchUserCoins();
          setState(() {});
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
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
                                size: 64,
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
                        childAspectRatio: 0.65,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        Merchandise merchandise = snapshot.data![index];
                        return ProductCard(
                          merchandise: merchandise,
                          onTap: () {
                            // TODO: Navigate to detail page
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Viewing: ${merchandise.name}'),
                              ),
                            );
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monetization_on,
                  color: Colors.amber.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoadingCoins ? 'Loading...' : '$userCoins Coins',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userType == 'organizer' ? 'Total Earned' : 'Sport Rewards',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to history page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History feature coming soon!')),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('History'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category['value']!;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // TODO: Navigate to add product page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add product feature coming soon!'),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add New Product'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}