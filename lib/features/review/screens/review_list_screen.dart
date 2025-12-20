// lib/features/review/screens/review_list_screen.dart

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:spot_runner_mobile/core/models/review_entry.dart';
import 'package:spot_runner_mobile/features/review/service/review_service.dart';
import 'package:spot_runner_mobile/features/review/screens/review_card.dart';
import 'package:spot_runner_mobile/features/review/screens/review_modal.dart';

class ReviewListScreen extends StatefulWidget {
  final String? eventId; // Optional: filter by event
  final String? eventName;

  const ReviewListScreen({
    Key? key,
    this.eventId,
    this.eventName,
  }) : super(key: key);

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  late Future<ReviewEntry?> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    final request = context.read<CookieRequest>();
    setState(() {
      _reviewsFuture = ReviewService.getAllReviews(
        request,
        eventId: widget.eventId,
      );
    });
  }

  Future<void> _handleEdit(Datum review) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReviewModal(
        eventName: review.eventName,
        eventId: review.eventId,
        reviewId: review.id,
        initialRating: review.rating,
        initialReview: review.reviewText,
        onSubmit: (rating, reviewText) async {
          await _submitEdit(review.id, rating, reviewText);
        },
      ),
    );

    if (result == true) {
      _loadReviews();
    }
  }

  Future<void> _submitEdit(String reviewId, int rating, String reviewText) async {
    final request = context.read<CookieRequest>();
    
    try {
      final response = await ReviewService.editReview(
        request,
        reviewId: reviewId,
        rating: rating,
        reviewText: reviewText,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );

        if (response['success']) {
          Navigator.pop(context, true);
          _loadReviews();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final request = context.read<CookieRequest>();
      final response = await ReviewService.deleteReview(request, reviewId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );

        if (response['success']) {
          _loadReviews();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventName != null 
          ? 'Reviews for ${widget.eventName}' 
          : 'All Reviews'),
        backgroundColor: const Color(0xFFA3E635),
      ),
      body: FutureBuilder<ReviewEntry?>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Failed to load reviews'),
            );
          }

          final reviews = snapshot.data!.data;

          if (reviews.isEmpty) {
            return const Center(
              child: Text('No reviews yet'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadReviews();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ReviewCard(
                    reviewId: review.id,
                    runnerName: review.runnerName,
                    eventName: review.eventName,
                    reviewText: review.reviewText,
                    rating: review.rating.toDouble(),
                    isOwner: review.isOwner,
                    onEdit: () => _handleEdit(review),
                    onDelete: () => _handleDelete(review.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}