import 'package:flutter/material.dart';
import 'auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;

  bool isLoggingOut = false;

  AuthController({AuthService? authService})
    : _authService = authService ?? AuthService();

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------
  Future<void> logout(BuildContext context) async {
    if (isLoggingOut) return;

    try {
      isLoggingOut = true;
      notifyListeners();

      final authService = AuthService();
      await authService.logout();

      // 🔁 Reset app navigation completely
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logout failed')));
    } finally {
      isLoggingOut = false;
      notifyListeners();
    }
  }
}
