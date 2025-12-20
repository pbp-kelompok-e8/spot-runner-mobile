import 'package:flutter/material.dart';
import 'package:spot_runner_mobile/core/models/user_entry.dart';

class UserProvider extends ChangeNotifier {
  // 1. Tambahkan variabel username string (untuk login basic)
  String _username = "Guest"; 
  UserProfile? _currentUser;

  // 2. Getter
  String get username => _username;
  UserProfile? get currentUser => _currentUser;
  bool get hasUser => _currentUser != null;

  // 3. Setter untuk Username (Dipakai di Login)
  void setUsername(String value) {
    _username = value;
    notifyListeners();
  }

  // 4. Setter untuk Full Profile (Dipakai di Dashboard/Profile)
  void setUser(UserProfile user) {
    _currentUser = user;
    // Jika profil punya username, sinkronkan juga
    if (user.username.isNotEmpty) {
      _username = user.username;
    }
    notifyListeners();
  }

  void clearUser() {
    _username = "Guest";
    _currentUser = null;
    notifyListeners();
  }
}