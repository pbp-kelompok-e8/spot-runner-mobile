import 'package:flutter/material.dart';
import 'package:spot_runner_mobile/core/models/user_entry.dart'; 
class UserProvider extends ChangeNotifier {
  UserProfile? _currentUser;

  UserProfile? get currentUser => _currentUser;

  bool get hasUser => _currentUser != null;

  void setUser(UserProfile user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}
