// lib/features/review/service/review_service.dart

import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:spot_runner_mobile/core/models/review_entry.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';

class ReviewService {
  // Get all reviews
  static Future<ReviewEntry?> getAllReviews(
    CookieRequest request, {
    String? eventId,
  }) async {
    try {
      String url;
      if (eventId != null) {
        url = '${ApiConfig.baseUrl}/api/reviews/?event_id=$eventId';
      } else {
        url = '${ApiConfig.baseUrl}/api/reviews/';
      }
      
      final response = await request.get(url);
      
      if (response['status'] == 'success') {
        return ReviewEntry.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create Review
  static Future<Map<String, dynamic>> createReview(
    CookieRequest request, {
    required String eventId,
    required int rating,
    required String reviewText,
  }) async {
    try {
      final response = await request.postJson(
        ApiConfig.createReview,
        jsonEncode({
          'event_id': eventId,
          'rating': rating,
          'review_text': reviewText,
        }),
      );

      // [PERBAIKAN] Mapping respons backend (status) ke format service (success)
      return {
        'status': response['status'], // Teruskan status asli ("success"/"error")
        'success': response['status'] == 'success', // Helper boolean
        'message': response['message'] ?? 'Unknown error',
      };
    } catch (e) {
      return {
        'status': 'error',
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Edit Review
  static Future<Map<String, dynamic>> editReview(
    CookieRequest request, {
    required String reviewId,
    required int rating,
    required String reviewText,
  }) async {
    try {
      // Use editReviewFlutter endpoint which returns 'status': 'success'
      final url = ApiConfig.editReviewFlutter(reviewId);
      print('🔄 Edit review URL: $url');
      print('🔄 Data: rating=$rating, reviewText=$reviewText');
      
      final response = await request.postJson(
        url,
        jsonEncode({
          'rating': rating,
          'review_text': reviewText,
        }),
      );
      
      print('📦 Edit review response: $response');

      // editReviewFlutter returns 'status': 'success'/'error'
      final bool isSuccess = response['status'] == 'success';
      return {
        'status': response['status'] ?? 'error',
        'success': isSuccess,
        'message': response['message'] ?? 'Unknown error',
      };
    } catch (e) {
      print('❌ Edit review error: $e');
      return {
        'status': 'error',
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Delete Review
  static Future<Map<String, dynamic>> deleteReview(
    CookieRequest request,
    String reviewId,
  ) async {
    try {
      final response = await request.post(
        ApiConfig.deleteReview(reviewId),
        {},
      );

      // Backend returns 'success': true/false, not 'status'
      final bool isSuccess = response['success'] == true;
      return {
        'status': isSuccess ? 'success' : 'error',
        'success': isSuccess,
        'message': response['message'] ?? 'Unknown error',
      };
    } catch (e) {
      return {
        'status': 'error',
        'success': false,
        'message': e.toString(),
      };
    }
  }
}