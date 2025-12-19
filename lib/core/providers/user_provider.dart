import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String _username = "";

  String get username => _username;

  void setUsername(String value) {
    _username = value;
    notifyListeners(); // Memberitahu semua widget yang pakai data ini untuk update
  }
  
  void clearUser() {
    _username = "";
    notifyListeners();
  }
}