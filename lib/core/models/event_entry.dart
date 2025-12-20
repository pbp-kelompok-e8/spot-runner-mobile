// event_entry.dart - PERBAIKAN
class EventDetail {
    String id;
    String name;
    String description;
    String location;
    String eventStatus;
    String image;
    dynamic image2;
    dynamic image3;
    DateTime eventDate;
    DateTime registDeadline;
    String contact;
    int capacity;
    int totalParticipans;
    bool full;
    int coin;
    UserEo userEo;
    List<String> eventCategories;

    EventDetail({
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

    factory EventDetail.fromJson(Map<String, dynamic> json) {
      // Helper function untuk parse datetime
      DateTime parseDateTime(dynamic dateStr) {
        if (dateStr == null) return DateTime.now();
        try {
          if (dateStr is String) {
            return DateTime.parse(dateStr);
          }
          return DateTime.now();
        } catch (e) {
          return DateTime.now();
        }
      }
      
      // Helper function untuk parse int
      int parseInt(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? 0;
        if (value is double) return value.toInt();
        return 0;
      }
      
      // Helper function untuk parse bool
      bool parseBool(dynamic value) {
        if (value == null) return false;
        if (value is bool) return value;
        if (value is String) return value.toLowerCase() == 'true';
        if (value is int) return value != 0;
        return false;
      }
      
      // Parse user_eo dengan default values
      Map<String, dynamic> userEoJson = json["user_eo"] is Map ? Map<String, dynamic>.from(json["user_eo"]) : {};
      
      return EventDetail(
        id: json["id"]?.toString() ?? '0',
        name: json["name"]?.toString() ?? '',
        description: json["description"]?.toString() ?? '',
        location: json["location"]?.toString() ?? '',
        eventStatus: json["event_status"]?.toString() ?? 'On Going',
        image: json["image"]?.toString() ?? '',
        image2: json["image2"],
        image3: json["image3"],
        eventDate: parseDateTime(json["event_date"]),
        registDeadline: parseDateTime(json["regist_deadline"]),
        contact: json["contact"]?.toString() ?? '',
        capacity: parseInt(json["capacity"]),
        totalParticipans: parseInt(json["total_participans"]),
        full: parseBool(json["full"]),
        coin: parseInt(json["coin"]),
        userEo: UserEo.fromJson(userEoJson),
        eventCategories: json["event_categories"] is List 
            ? List<String>.from(json["event_categories"].map((x) => x?.toString() ?? ''))
            : <String>[],
      );
    }

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

    factory UserEo.fromJson(Map<String, dynamic> json) {
      dynamic idValue = json["id"];
      int parsedId;
      
      if (idValue is int) {
        parsedId = idValue;
      } else if (idValue is String) {
        parsedId = int.tryParse(idValue) ?? 0;
      } else {
        parsedId = 0;
      }
      
      return UserEo(
        id: parsedId,
        username: json["username"]?.toString() ?? '',
      );
    }

    Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
    };
}