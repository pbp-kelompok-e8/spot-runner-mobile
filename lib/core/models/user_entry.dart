// user_entry.dart - PERBAIKAN
class UserProfile {
    int id;
    String username;
    String email;
    String role;  
    Details? details;

    UserProfile({
        required this.id,
        required this.username,
        required this.email,
        required this.role,
        this.details, // Changed from required to optional
    });

    factory UserProfile.fromJson(Map<String, dynamic> json) {
      // Handle id yang mungkin string atau null
      dynamic idValue = json["id"];
      int parsedId;
      
      if (idValue is int) {
        parsedId = idValue;
      } else if (idValue is String) {
        parsedId = int.tryParse(idValue) ?? 0;
      } else {
        parsedId = 0;
      }

      return UserProfile(
        id: parsedId,
        username: json["username"]?.toString() ?? '',
        email: json["email"]?.toString() ?? '',
        role: json["role"]?.toString() ?? '',
        details: json["details"] != null ? Details.fromJson(json["details"]) : null,
      );
    }

    Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "email": email,
        "role": role,
        "details": details?.toJson(),
    };
}

class Details {
    String baseLocation;
    int coin;
    String? profilePicture;
    int totalEvents; // Changed from int? to int with default
    double rating;   // Changed from int? to double with default

    Details({
        required this.baseLocation,
        required this.coin,
        this.profilePicture,
        required this.totalEvents, // Now required
        required this.rating,      // Now required
    });

    factory Details.fromJson(Map<String, dynamic> json) {
      // Handle semua field dengan default value
      String baseLocation = json["base_location"]?.toString() ?? "";
      
      // Handle coin
      dynamic coinValue = json["coin"];
      int parsedCoin;
      if (coinValue is int) {
        parsedCoin = coinValue;
      } else if (coinValue is String) {
        parsedCoin = int.tryParse(coinValue) ?? 0;
      } else {
        parsedCoin = 0;
      }
      
      // Handle total_events
      dynamic totalEventsValue = json["total_events"];
      int parsedTotalEvents;
      if (totalEventsValue is int) {
        parsedTotalEvents = totalEventsValue;
      } else if (totalEventsValue is String) {
        parsedTotalEvents = int.tryParse(totalEventsValue) ?? 0;
      } else {
        parsedTotalEvents = 0;
      }
      
      // Handle rating (bisa int atau double)
      dynamic ratingValue = json["rating"];
      double parsedRating;
      if (ratingValue is double) {
        parsedRating = ratingValue;
      } else if (ratingValue is int) {
        parsedRating = ratingValue.toDouble();
      } else if (ratingValue is String) {
        parsedRating = double.tryParse(ratingValue) ?? 0.0;
      } else {
        parsedRating = 0.0;
      }
      
      return Details(
        baseLocation: baseLocation,
        coin: parsedCoin,
        profilePicture: json["profile_picture"]?.toString(),
        totalEvents: parsedTotalEvents,
        rating: parsedRating,
      );
    }

    Map<String, dynamic> toJson() => {
        "base_location": baseLocation,
        "coin": coin,
        "profile_picture": profilePicture,
        "total_events": totalEvents,
        "rating": rating,
    };
}
