//lib\core\widgets\card.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spot_runner_mobile/features/auth/screens/login.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/features/review/screens/review_modal.dart';
import 'package:spot_runner_mobile/features/review/service/review_service.dart';
import 'package:spot_runner_mobile/features/review/screens/review_list_screen.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';

class ItemHomepage {
  final String name;
  final IconData icon;

  ItemHomepage(this.name, this.icon);
}

class ItemCard extends StatelessWidget {
  final ItemHomepage item;

  const ItemCard(this.item, {super.key});

  // Method untuk handle submit review (CREATE)
  Future<void> _handleCreateReview(
    BuildContext context, {
    required CookieRequest request,
    required String eventId,
    required int rating,
    required String reviewText,
  }) async {
    try {
      final response = await ReviewService.createReview(
        request,
        eventId: eventId,
        rating: rating,
        reviewText: reviewText,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Material(
      color: Theme.of(context).colorScheme.secondary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text("Kamu telah menekan tombol ${item.name}!"),
              ),
            );

          // Handle Logout
          if (item.name == "Logout") {
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            }
          }
          
          // Handle Review Event - SHOW MODAL untuk CREATE REVIEW
          else if (item.name == "Review Event") {
            // TODO: Ganti dengan UUID event yang sebenarnya dari database
            // Untuk testing, buat dulu event di Django admin dan ambil UUID-nya
            const testEventId = 'PASTE-UUID-EVENT-DISINI'; // Contoh: '550e8400-e29b-41d4-a716-446655440000'
            const testEventName = 'Sample Event Name';
            
            showDialog(
              context: context,
              builder: (context) => ReviewModal(
                eventName: testEventName,
                eventId: testEventId,
                onSubmit: (rating, reviewText) async {
                  await _handleCreateReview(
                    context,
                    request: request,
                    eventId: testEventId,
                    rating: rating,
                    reviewText: reviewText,
                  );
                },
              ),
            );
          }
          
          // Handle See All Reviews - Navigate ke halaman list reviews
          else if (item.name == "See Reviews") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReviewListScreen(),
              ),
            );
          }
          
          // Handle See Football News
          else if (item.name == "See Football News") {
            // TODO: Navigate ke halaman news list
          } else if (item.name == "Add News") {
            // TODO: Navigate ke halaman add news
          }
          // Handle Home
          else if (item.name == "Home") {
            // TODO: Navigate ke home page atau pop to home
          }
          // Handle Dashboard
          else if (item.name == "Dashboard") {
            // TODO: Navigate ke dashboard
          }
          // Handle Profile
          else if (item.name == "Profile") {
            // TODO: Navigate ke profile page
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: Colors.white, size: 30.0),
                const Padding(padding: EdgeInsets.all(3)),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
