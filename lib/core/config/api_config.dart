import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// Runtime-aware base URL (localhost for web, 10.0.2.2 for Android emulator)
  static String get baseUrl => kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';

  /// Auth
  static String get logout => '$baseUrl/auth/logout/';
  static String get login => '$baseUrl/auth/login/';
  static String get register => '$baseUrl/auth/register/';

  /// User endpoints
  static String userProfile(String username) => '$baseUrl/$username/json';

  /// Review & Rating endpoints
  static String get reviewsJson => '$baseUrl/review/api/reviews/';
  static String get createReview => '$baseUrl/review/create-flutter/';

  static String reviewsByEvent(String eventId) => '$baseUrl/review/api/reviews/?event_id=$eventId';
  static String eventReviews(String eventId) => '$baseUrl/review/api/reviews/event/$eventId/';
  static String editReview(String reviewId) => '$baseUrl/review/$reviewId/edit/';
  static String deleteReview(String reviewId) => '$baseUrl/review/$reviewId/delete/';

  /// Merchandise endpoints
  static String get merchandiseJson => '$baseUrl/merchandise/json/';
  static String get userCoins => '$baseUrl/merchandise/user-coins/';
  static String get redeemMerchandise => '$baseUrl/merchandise/redemption/json/';
  static String get merchandiseHistory => '$baseUrl/merchandise/history-json/';
  static String get createMerchandise => '$baseUrl/merchandise/create-flutter/';
  static String get editMerchandise => '$baseUrl/merchandise/edit-flutter/';
  static String get deleteMerchandise => '$baseUrl/merchandise/delete-flutter/';

  static String merchandiseDetail(String id) => '$baseUrl/merchandise/json/$id/';
  static String editMerchandiseUrl(String id) => '$baseUrl/merchandise/edit-flutter/$id/';
  static String deleteMerchandiseUrl(String id) => '$baseUrl/merchandise/delete-flutter/$id/';
  static String redeemMerchandiseUrl(String id) => '$baseUrl/merchandise/$id/redeem/';
  static String proxyImage(String encodedUrl) => '$baseUrl/merchandise/proxy-image/?url=$encodedUrl';

  /// Event endpoints
  static String get eventJson => '$baseUrl/event/json/';
  static String get createEvent => '$baseUrl/event/create-flutter/';
  static String get editEvent => '$baseUrl/event/edit-flutter/';
  static String get deleteEvent => '$baseUrl/event/delete-flutter/';

  static String eventDetail(String id) => '$baseUrl/event/json/$id/';
  static String editEventUrl(String id) => '$baseUrl/event/edit-flutter/$id/';
  static String deleteEventUrl(String id) => '$baseUrl/event/delete-flutter/$id/';
  static String eventList() => '$baseUrl/event/json/';

  /// Event Organizer specific
  static String eventOrganizerProfile() => '$baseUrl/event-organizer/profile/json/';
  static String eventOrganizerJson() => '$baseUrl/event-organizer/json/';
  static String deleteAccountUrl() => '$baseUrl/event-organizer/delete-account-flutter/';

  /// API helpers
  static String changePassword() => '$baseUrl/api/change-password/';
  static String editProfile() => '$baseUrl/api/edit-profile/';
  static String deleteAccount() => '$baseUrl/api/delete-account/';
  static String cancelParticipation(String username, String eventId) => '$baseUrl/api/cancel/$username/$eventId/';
  static String participateUrl(String username, String eventId, String category) => '$baseUrl/api/participate/$username/$eventId/$category/';
}
