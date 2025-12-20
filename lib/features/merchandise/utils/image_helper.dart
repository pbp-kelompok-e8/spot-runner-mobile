import 'package:spot_runner_mobile/core/config/api_config.dart';

class ImageHelper {
  static String getProxiedImageUrl(String originalUrl) {
    if (originalUrl.isEmpty) return '';

    // Encode URL untuk query parameter
    final encodedUrl = Uri.encodeComponent(originalUrl);

    // Return proxied URL
    // return 'http://localhost:8000/merchandise/proxy-image/?url=$encodedUrl';
    return ApiConfig.proxyImage(encodedUrl);
  }

  // Check if image URL is valid
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  // If original URL is invalid, return placeholder
  static String getImageUrlWithFallback(
    String? originalUrl, {
    String? placeholder,
  }) {
    if (originalUrl == null || originalUrl.isEmpty) {
      return placeholder ?? '';
    }

    return getProxiedImageUrl(originalUrl);
  }
}
