// lib/features/review/service/review_service.dart

import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:spot_runner_mobile/core/models/review_entry.dart';
import 'package:spot_runner_mobile/core/config/api_config.dart';

class ReviewService {
  // Get all reviews atau filter by event_id
  static Future<ReviewEntry?> getAllReviews(
    CookieRequest request, {
    String? eventId,
  }) async {
    try {
      String url;
      
      if (eventId != null) {
        // Get reviews untuk event tertentu
        url = '${ApiConfig.baseUrl}/api/reviews/?event_id=$eventId';
      } else {
        // Get SEMUA reviews (untuk cek user review status)
        url = '${ApiConfig.baseUrl}/api/reviews/';
      }
      
      print('📡 Fetching reviews from: $url');
      
      final response = await request.get(url);
      
      print('📦 Response: $response');
      
      if (response['status'] == 'success') {
        return ReviewEntry.fromJson(response);
      }
      
      return null;
    } catch (e) {
      print('❌ Error in getAllReviews: $e');
      return null;
    }
  }

  // Get reviews for specific event (dengan average rating)
  static Future<Map<String, dynamic>?> getEventReviews(
    CookieRequest request,
    String eventId,
  ) async {
    try {
      final response = await request.get(
        ApiConfig.eventReviews(eventId),
      );
      
      if (response['status'] == 'success') {
        return response;
      }
      return null;
    } catch (e) {
      print("❌ Error getting event reviews: $e");
      return null;
    }
  }

  // Create new review
  static Future<Map<String, dynamic>> createReview(
    CookieRequest request, {
    required String eventId,
    required int rating,
    required String reviewText,
  }) async {
    try {
      print('📤 Creating review for event: $eventId');
      
      final response = await request.postJson(
        ApiConfig.createReview,
        jsonEncode({
          'event_id': eventId,
          'rating': rating,
          'review_text': reviewText,
        }),
      );

      print('📦 Create review response: $response');

      return {
        'success': response['status'] == 'success',
        'message': response['message'] ?? 'Unknown error',
      };
    } catch (e) {
      print("❌ Error creating review: $e");
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Edit existing review - Web endpoint
  static Future<Map<String, dynamic>> editReview(
    CookieRequest request, {
    required String reviewId,
    required int rating,
    required String reviewText,
  }) async {
    try {
      print('📤 Editing review: $reviewId');
      
      final response = await request.postJson(
        ApiConfig.editReview(reviewId),
        jsonEncode({
          'rating': rating,
          'review_text': reviewText,
        }),
      );

      print('📦 Edit review response: $response');

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Unknown error',
      };
    } catch (e) {
      print("❌ Error editing review: $e");
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Edit existing review - Flutter endpoint (alternative)
  static Future<Map<String, dynamic>> editReviewFlutter(
    CookieRequest request, {
    required String reviewId,
    required int rating,
    required String reviewText,
  }) async {
    try {
      print('📤 Editing review (Flutter): $reviewId');
      
      final url = '${ApiConfig.baseUrl}/review/edit-flutter/$reviewId/';
      
      final response = await request.postJson(
        url,
        jsonEncode({
          'rating': rating,
          'review_text': reviewText,
        }),
      );

      print('📦 Edit review flutter response: $response');

      return {
        'success': response['status'] == 'success',
        'message': response['message'] ?? 'Unknown error',
      };
    } catch (e) {
      print("❌ Error editing review (Flutter): $e");
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Delete review - Web endpoint
  static Future<Map<String, dynamic>> deleteReview(
    CookieRequest request,
    String reviewId,
  ) async {
    try {
      print('📤 Deleting review: $reviewId');
      
      final response = await request.post(
        ApiConfig.deleteReview(reviewId),
        {},
      );

      print('📦 Delete review response: $response');

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Unknown error',
      };
    } catch (e) {
      print("❌ Error deleting review: $e");
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Delete review - Flutter endpoint (alternative)
  static Future<Map<String, dynamic>> deleteReviewFlutter(
    CookieRequest request,
    String reviewId,
  ) async {
    try {
      print('📤 Deleting review (Flutter): $reviewId');
      
      final url = '${ApiConfig.baseUrl}/review/delete-flutter/$reviewId/';
      
      final response = await request.post(url, {});

      print('📦 Delete review flutter response: $response');

      return {
        'success': response['status'] == 'success',
        'message': response['message'] ?? 'Unknown error',
      };
    } catch (e) {
      print("❌ Error deleting review (Flutter): $e");
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}