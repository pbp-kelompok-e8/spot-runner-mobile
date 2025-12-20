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
  static const String merchandiseJson = '$baseUrl/merchandise/json/';
  static const String userCoins = '$baseUrl/merchandise/user-coins/';
  static const String redeemMerchandise = '$baseUrl/merchandise/redemption/json/';
  static const String merchandiseHistory = '$baseUrl/merchandise/history-json/';
  static const String createMerchandise = '$baseUrl/merchandise/create-flutter/';
  static const String editMerchandise = '$baseUrl/merchandise/edit-flutter/';
  static const String deleteMerchandise = '$baseUrl/merchandise/delete-flutter/';

  static String merchandiseDetail(String id) => '$baseUrl/merchandise/json/$id/';
  static String editMerchandiseUrl(String id) => '$baseUrl/merchandise/edit-flutter/$id/';
  static String deleteMerchandiseUrl(String id) => '$baseUrl/merchandise/delete-flutter/$id/';
  static String redeemMerchandiseUrl(String id) => '$baseUrl/merchandise/$id/redeem/';
  static String proxyImage(String encodedUrl) => '$baseUrl/merchandise/proxy-image/?url=$encodedUrl';

}
