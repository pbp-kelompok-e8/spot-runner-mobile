class ImageHelper {
  static String getProxiedImageUrl(String originalUrl) {
    if (originalUrl.isEmpty) return '';
    
    // Encode URL untuk query parameter
    final encodedUrl = Uri.encodeComponent(originalUrl);
    
    // Return proxied URL
    return 'http://localhost:8000/merchandise/proxy-image/?url=$encodedUrl';
  }
}