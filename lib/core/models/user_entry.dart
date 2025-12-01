//Shared Model
class UserProfile {
  final int id;
  final String username;
  final String email;
  final String role;
  final RunnerDetails? runnerDetails;
  final OrganizerDetails? organizerDetails;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.runnerDetails,
    this.organizerDetails,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    RunnerDetails? runnerData;
    OrganizerDetails? organizerData;

    if (json['details'] != null) {
      if (json['role'] == 'runner') {
        runnerData = RunnerDetails.fromJson(json['details']);
      } else if (json['role'] == 'event_organizer') {
        organizerData = OrganizerDetails.fromJson(json['details']);
      }
    }

    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      runnerDetails: runnerData,
      organizerDetails: organizerData,
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

class OrganizerDetails {
  final String baseLocation;
  final String profilePicture;
  final int totalEvents;
  final double rating;
  final int coin;

  OrganizerDetails({
    required this.baseLocation,
    required this.profilePicture,
    required this.totalEvents,
    required this.rating,
    required this.coin,
  });

  factory OrganizerDetails.fromJson(Map<String, dynamic> json) {
    return OrganizerDetails(
      baseLocation: json['base_location'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      totalEvents: json['total_events'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      coin: json['coin'] ?? 0,
    );
  }
}
