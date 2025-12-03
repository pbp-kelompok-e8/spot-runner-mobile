//Shared Model
class UserProfile {
  final int id;
  final String username;
  final String email;
  final String role;
  final RunnerDetails? runnerDetails;
  final EventOrganizerDetails? eventOrganizerDetails;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.runnerDetails,
    this.eventOrganizerDetails,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    RunnerDetails? runnerData;
    EventOrganizerDetails? eventOrganizerData;

    if (json['details'] != null) {
      if (json['role'] == 'runner') {
        runnerData = RunnerDetails.fromJson(json['details']);
      } else if (json['role'] == 'event_organizer') {
        eventOrganizerData = EventOrganizerDetails.fromJson(json['details']);
      }
    }

    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      runnerDetails: runnerData,
      eventOrganizerDetails: eventOrganizerData,
    );
  }
}

class RunnerDetails {
  final String baseLocation;
  final int coin;

  RunnerDetails({required this.baseLocation, required this.coin});

  factory RunnerDetails.fromJson(Map<String, dynamic> json) {
    return RunnerDetails(
      baseLocation: json['base_location'] ?? '',
      coin: json['coin'] ?? 0,
    );
  }
}

class EventOrganizerDetails {
  final String baseLocation;
  final String profilePicture;

  EventOrganizerDetails({
    required this.baseLocation,
    required this.profilePicture,
  });

  factory EventOrganizerDetails.fromJson(Map<String, dynamic> json) {
    return EventOrganizerDetails(
      baseLocation: json['base_location'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
    );
  }
}
