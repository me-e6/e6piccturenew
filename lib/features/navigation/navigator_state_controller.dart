import 'package:flutter/material.dart';

class NavigationStateController extends ChangeNotifier {
  bool _isProfileActive = false;

  bool get isProfileActive => _isProfileActive;

  void enterProfile() {
    if (_isProfileActive) return;
    _isProfileActive = true;
    notifyListeners();
  }

  void exitProfile() {
    if (!_isProfileActive) return;
    _isProfileActive = false;
    notifyListeners();
  }
}
