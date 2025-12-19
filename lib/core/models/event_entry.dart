import 'dart:convert';

EventEntry eventEntryFromJson(String str) => EventEntry.fromJson(json.decode(str));

String eventEntryToJson(EventEntry data) => json.encode(data.toJson());

class EventEntry {
    String id;
    String name;
    String description;
    String location;
    String eventStatus;
    String image;
    String image2;
    String image3;
    DateTime eventDate;
    DateTime registDeadline;
    String contact;
    int capacity;
    int totalParticipans;
    bool full;
    int coin;
    UserEo userEo;
    List<String> eventCategories;

    EventEntry({
        required this.id,
        required this.name,
        required this.description,
        required this.location,
        required this.eventStatus,
        required this.image,
        required this.image2,
        required this.image3,
        required this.eventDate,
        required this.registDeadline,
        required this.contact,
        required this.capacity,
        required this.totalParticipans,
        required this.full,
        required this.coin,
        required this.userEo,
        required this.eventCategories,
    });

    factory EventEntry.fromJson(Map<String, dynamic> json) => EventEntry(
        id: json["id"],
        name: json["name"],
        description: json["description"],
        location: json["location"],
        eventStatus: json["event_status"],
        image: json["image"],
        image2: json["image2"],
        image3: json["image3"],
        eventDate: DateTime.parse(json["event_date"]),
        registDeadline: DateTime.parse(json["regist_deadline"]),
        contact: json["contact"],
        capacity: json["capacity"],
        totalParticipans: json["total_participans"],
        full: json["full"],
        coin: json["coin"],
        userEo: UserEo.fromJson(json["user_eo"]),
        eventCategories: List<String>.from(json["event_categories"].map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "location": location,
        "event_status": eventStatus,
        "image": image,
        "image2": image2,
        "image3": image3,
        "event_date": eventDate.toIso8601String(),
        "regist_deadline": registDeadline.toIso8601String(),
        "contact": contact,
        "capacity": capacity,
        "total_participans": totalParticipans,
        "full": full,
        "coin": coin,
        "user_eo": userEo.toJson(),
        "event_categories": List<dynamic>.from(eventCategories.map((x) => x)),
    };
}

class UserEo {
    int id;
    String username;

    UserEo({
        required this.id,
        required this.username,
    });

    factory UserEo.fromJson(Map<String, dynamic> json) => UserEo(
        id: json["id"],
        username: json["username"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
    };
}
