import 'package:flutter/material.dart';
class ConnectivityProvider extends ChangeNotifier {
  bool _hasError = false;
  String _errorMessage = "";
  VoidCallback? _onRetry;

  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  void setError(String message, VoidCallback onRetry) {
    _hasError = true;
    _errorMessage = message;
    _onRetry = onRetry;
    notifyListeners();
  }
  
  void retry() {
    _hasError = false;
    notifyListeners();
    _onRetry?.call();
  }
}