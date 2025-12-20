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
      String url = eventId != null 
          ? ApiConfig.reviewsByEvent(eventId)
          : ApiConfig.reviewsJson;

      final response = await request.get(url);
      
      if (response['status'] == 'success') {
        return ReviewEntry.fromJson(response);
      }
      return null;
    } catch (e) {
      print("Error getting reviews: $e");
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
      print("Error getting event reviews: $e");
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
      final response = await request.postJson(
        ApiConfig.createReview,
        jsonEncode({
          'event_id': eventId,
          'rating': rating,
          'review_text': reviewText,
        }),
      );

      return {
        'success': response['status'] == 'success',
        'message': response['message'] ?? 'Unknown error',
      };
    } catch (e) {
      print("Error creating review: $e");
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Edit existing review
  static Future<Map<String, dynamic>> editReview(
    CookieRequest request, {
    required String reviewId,
    required int rating,
    required String reviewText,
  }) async {
    try {
      final response = await request.postJson(
        ApiConfig.editReview(reviewId),
        jsonEncode({
          'rating': rating,
          'review_text': reviewText,
        }),
      );

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Unknown error',
      };
    } catch (e) {
      print("Error editing review: $e");
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Delete review
  static Future<Map<String, dynamic>> deleteReview(
    CookieRequest request,
    String reviewId,
  ) async {
    try {
      final response = await request.post(
        ApiConfig.deleteReview(reviewId),
        {},
      );

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Unknown error',
      };
    } catch (e) {
      print("Error deleting review: $e");
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}