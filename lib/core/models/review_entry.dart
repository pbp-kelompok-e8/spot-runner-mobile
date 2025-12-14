// To parse this JSON data, do
//
//     final reviewEntry = reviewEntryFromJson(jsonString);

import 'dart:convert';

ReviewEntry reviewEntryFromJson(String str) => ReviewEntry.fromJson(json.decode(str));

String reviewEntryToJson(ReviewEntry data) => json.encode(data.toJson());

class ReviewEntry {
    String status;
    List<Datum> data;
    int count;

    ReviewEntry({
        required this.status,
        required this.data,
        required this.count,
    });

    factory ReviewEntry.fromJson(Map<String, dynamic> json) => ReviewEntry(
        status: json["status"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
        count: json["count"],
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "count": count,
    };
}

class Datum {
    String id;
    String runnerName;
    String eventId;
    String eventName;
    String reviewText;
    int rating;
    DateTime createdAt;
    bool isOwner;

    Datum({
        required this.id,
        required this.runnerName,
        required this.eventId,
        required this.eventName,
        required this.reviewText,
        required this.rating,
        required this.createdAt,
        required this.isOwner,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        id: json["id"],
        runnerName: json["runner_name"],
        eventId: json["event_id"],
        eventName: json["event_name"],
        reviewText: json["review_text"],
        rating: json["rating"],
        createdAt: DateTime.parse(json["created_at"]),
        isOwner: json["is_owner"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "runner_name": runnerName,
        "event_id": eventId,
        "event_name": eventName,
        "review_text": reviewText,
        "rating": rating,
        "created_at": createdAt.toIso8601String(),
        "is_owner": isOwner,
    };
}
