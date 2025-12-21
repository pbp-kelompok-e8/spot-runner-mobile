import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';
import 'package:spot_runner_mobile/features/merchandise/models/redemption_model.dart';
import 'package:spot_runner_mobile/features/merchandise/utils/image_helper.dart';
import 'package:spot_runner_mobile/core/widgets/error_handler.dart';
import 'package:spot_runner_mobile/core/widgets/error_retry.dart';
import 'dart:async';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool isLoading = true;
  String userType = 'guest';
  List<Redemption> redemptions = [];
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    fetchRedemptions();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        fetchRedemptions();
      }
    });
  }

  Future<void> fetchRedemptions() async {
    if (!mounted) return;
    
    setState(() => isLoading = true);

    final request = context.read<CookieRequest>();

    try {
      final response = await request.get(ApiConfig.redeemMerchandise);

      if (mounted) {
        final redemptionResponse = RedemptionResponse.fromJson(response);
        setState(() {
          userType = redemptionResponse.userType;
          redemptions = redemptionResponse.redemptions;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching redemptions: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        // Set error ke ConnectivityProvider
        context.read<ConnectivityProvider>().setError(
          "Failed to load redemption history. Please check your connection.",
          () => fetchRedemptions(),
        );
      }
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final connectivityProvider = context.watch<ConnectivityProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1D4ED8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: connectivityProvider.hasError
          ? ErrorRetryWidget(
              message: connectivityProvider.errorMessage,
              onRetry: () => connectivityProvider.retry(),
            )
          : isLoading
              ? const Center(child: CircularProgressIndicator())
              : redemptions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No redemption history yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchRedemptions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: redemptions.length,
                        itemBuilder: (context, index) {
                          final redemption = redemptions[index];
                          return _buildRedemptionCard(redemption);
                        },
                      ),
                    ),
    );
  }

  Widget _buildRedemptionCard(Redemption redemption) {
    final isIncome = userType == 'organizer';
    final coinColor = isIncome ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    redemption.merchandise?.name ?? '[Deleted Product]',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: coinColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${isIncome ? '+' : '-'}${redemption.totalCoins}',
                        style: TextStyle(
                          color: coinColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.monetization_on, size: 16, color: coinColor),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Date
            Row(
              children: [
                Text(
                  'Date',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                Text(
                  formatDate(redemption.redeemedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (userType == 'organizer' && redemption.user != null) ...[
              const SizedBox(height: 8),

              // User info for organizer
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Name',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        redemption.user!.username,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 8),
                ],
              ),
            ],

            // Product details
            if (redemption.merchandise != null) ...[
              // Show product image and details
              Row(
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ImageHelper.getProxiedImageUrl(
                        redemption.merchandise!.imageUrl,
                      ),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${redemption.quantity}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                redemption.merchandise!.categoryDisplay,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Deleted product info
              Row(
                children: [
                  Text(
                    'Quantity',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${redemption.quantity}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
