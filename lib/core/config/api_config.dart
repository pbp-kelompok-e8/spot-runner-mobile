class ApiConfig {
  // static const String baseUrl = 'https://william-jonnatan-spotrunner.pbp.cs.ui.ac.id';
  static const String baseUrl = 'http://localhost:8000';

  static const String logout = '$baseUrl/auth/logout/';
  static const String login = '$baseUrl/auth/login/';
  static const String register = '$baseUrl/auth/register/';

  // User endpoints
  static String userProfile(String username) => '$baseUrl/$username/json';

  // Merchandise endpoints
  // Review & Rating endpoints
  static const String reviewsJson = '$baseUrl/review/api/reviews/';
  static const String createReview = '$baseUrl/review/create-flutter/';

  static String reviewsByEvent(String eventId) => '$baseUrl/review/api/reviews/?event_id=$eventId';
  static String eventReviews(String eventId) => '$baseUrl/review/api/reviews/event/$eventId/';
  static String editReview(String reviewId) => '$baseUrl/review/$reviewId/edit/';
  static String deleteReview(String reviewId) => '$baseUrl/review/$reviewId/delete/';

}