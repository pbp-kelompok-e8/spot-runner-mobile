import 'dart:convert';

List<Merchandise> merchandiseFromJson(String str) =>
    List<Merchandise>.from(json.decode(str).map((x) => Merchandise.fromJson(x)));

String merchandiseToJson(List<Merchandise> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Merchandise {
  final String id;
  final String name;
  final int priceCoins;
  final String description;
  final String imageUrl;
  final String category;
  final String categoryDisplay;
  final int stock;
  final bool available;
  final String organizerId;
  final String organizerName;
  final DateTime createdAt;

  Merchandise({
    required this.id,
    required this.name,
    required this.priceCoins,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.categoryDisplay,
    required this.stock,
    required this.available,
    required this.organizerId,
    required this.organizerName,
    required this.createdAt,
  });

  factory Merchandise.fromJson(Map<String, dynamic> json) => Merchandise(
        id: json["id"],
        name: json["name"],
        priceCoins: json["price_coins"],
        description: json["description"],
        imageUrl: json["image_url"],
        category: json["category"],
        categoryDisplay: json["category_display"],
        stock: json["stock"],
        available: json["available"],
        // FIX: Akses nested object organizer
        organizerId: json["organizer"]["id"].toString(),
        organizerName: json["organizer"]["username"],
        createdAt: DateTime.parse(json["created_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "price_coins": priceCoins,
        "description": description,
        "image_url": imageUrl,
        "category": category,
        "category_display": categoryDisplay,
        "stock": stock,
        "available": available,
        "organizer": {
          "id": organizerId,
          "username": organizerName,
        },
        "created_at": createdAt.toIso8601String(),
      };
}