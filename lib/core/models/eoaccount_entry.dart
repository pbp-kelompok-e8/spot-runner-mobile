// To parse this JSON data, do
//
//     final eoAccount = eoAccountFromJson(jsonString);

import 'dart:convert';

EoAccount eoAccountFromJson(String str) => EoAccount.fromJson(json.decode(str));

String eoAccountToJson(EoAccount data) => json.encode(data.toJson());

class EoAccount {
    String status;
    Data data;

    EoAccount({
        required this.status,
        required this.data,
    });

    factory EoAccount.fromJson(Map<String, dynamic> json) => EoAccount(
        status: json["status"],
        data: Data.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "data": data.toJson(),
    };
}

class Data {
    int userId;
    String username;
    String email;
    String firstName;
    String lastName;
    String name;
    String profilePicture;
    String baseLocation;
    DateTime joined;
    DateTime lastLogin;
    int totalEvents;
    int rating;
    int reviewCount;
    int coin;
    DateTime createdAt;
    DateTime updatedAt;

    Data({
        required this.userId,
        required this.username,
        required this.email,
        required this.firstName,
        required this.lastName,
        required this.name,
        required this.profilePicture,
        required this.baseLocation,
        required this.joined,
        required this.lastLogin,
        required this.totalEvents,
        required this.rating,
        required this.reviewCount,
        required this.coin,
        required this.createdAt,
        required this.updatedAt,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        userId: json["user_id"],
        username: json["username"],
        email: json["email"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        name: json["name"],
        profilePicture: json["profile_picture"],
        baseLocation: json["base_location"],
        joined: DateTime.parse(json["joined"]),
        lastLogin: DateTime.parse(json["last_login"]),
        totalEvents: json["total_events"],
        rating: json["rating"],
        reviewCount: json["review_count"],
        coin: json["coin"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
    );

    Map<String, dynamic> toJson() => {
        "user_id": userId,
        "username": username,
        "email": email,
        "first_name": firstName,
        "last_name": lastName,
        "name": name,
        "profile_picture": profilePicture,
        "base_location": baseLocation,
        "joined": "${joined.year.toString().padLeft(4, '0')}-${joined.month.toString().padLeft(2, '0')}-${joined.day.toString().padLeft(2, '0')}",
        "last_login": lastLogin.toIso8601String(),
        "total_events": totalEvents,
        "rating": rating,
        "review_count": reviewCount,
        "coin": coin,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
    };
}
