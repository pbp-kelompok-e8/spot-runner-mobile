// To parse this JSON data, do
//
//     final user = userFromJson(jsonString);

import 'dart:convert';

List<UserProfile> userFromJson(String str) => List<UserProfile>.from(json.decode(str).map((x) => UserProfile.fromJson(x)));

String userToJson(List<UserProfile> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

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
        required this.details,
    });

    factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json["id"],
        username: json["username"],
        email: json["email"],
        role: json["role"],
        details: json["details"] == null ? null : Details.fromJson(json["details"]),
    );

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
    int? totalEvents;
    int? rating;

    Details({
        required this.baseLocation,
        required this.coin,
        this.profilePicture,
        this.totalEvents,
        this.rating,
    });

    factory Details.fromJson(Map<String, dynamic> json) => Details(
        baseLocation: json["base_location"],
        coin: json["coin"],
        profilePicture: json["profile_picture"],
        totalEvents: json["total_events"],
        rating: json["rating"],
    );

    Map<String, dynamic> toJson() => {
        "base_location": baseLocation,
        "coin": coin,
        "profile_picture": profilePicture,
        "total_events": totalEvents,
        "rating": rating,
    };
}
