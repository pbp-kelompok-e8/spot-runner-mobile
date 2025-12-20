import 'dart:convert';

class RedemptionResponse {
  final String userType;
  final List<Redemption> redemptions;

  RedemptionResponse({
    required this.userType,
    required this.redemptions,
  });

  factory RedemptionResponse.fromJson(Map<String, dynamic> json) =>
      RedemptionResponse(
        userType: json["user_type"],
        redemptions: List<Redemption>.from(
          json["redemptions"].map((x) => Redemption.fromJson(x)),
        ),
      );
}

class Redemption {
  final String id;
  final int quantity;
  final int pricePerItem;
  final int totalCoins;
  final DateTime redeemedAt;
  final MerchandiseInfo? merchandise;
  final UserInfo? user; // Only for organizer view

  Redemption({
    required this.id,
    required this.quantity,
    required this.pricePerItem,
    required this.totalCoins,
    required this.redeemedAt,
    this.merchandise,
    this.user,
  });

  factory Redemption.fromJson(Map<String, dynamic> json) => Redemption(
        id: json["id"],
        quantity: json["quantity"],
        pricePerItem: json["price_per_item"],
        totalCoins: json["total_coins"],
        redeemedAt: DateTime.parse(json["redeemed_at"]),
        merchandise: json["merchandise"] != null
            ? MerchandiseInfo.fromJson(json["merchandise"])
            : null,
        user: json["user"] != null ? UserInfo.fromJson(json["user"]) : null,
      );
}

class MerchandiseInfo {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final String categoryDisplay;

  MerchandiseInfo({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.categoryDisplay,
  });

  factory MerchandiseInfo.fromJson(Map<String, dynamic> json) =>
      MerchandiseInfo(
        id: json["id"],
        name: json["name"],
        imageUrl: json["image_url"],
        category: json["category"],
        categoryDisplay: json["category_display"],
      );
}

class UserInfo {
  final String username;

  UserInfo({required this.username});

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        username: json["username"],
      );
}