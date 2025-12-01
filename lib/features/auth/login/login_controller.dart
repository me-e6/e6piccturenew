import 'package:flutter/material.dart';
import 'login_service.dart';
import 'login_errors.dart';

class LoginController extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final LoginService _service;

  bool isLoading = false;
  bool isPasswordVisible = false;

  LoginController({LoginService? testService})
    : _service = testService ?? LoginService();

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  Future<void> login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage(context, "Please enter email & password");
      return;
    }

    _setLoading(true);
    final result = await _service.loginUser(email, password);
    _setLoading(false);

    if (result == "success") {
      _showMessage(context, "Login Successful!");
      Future.delayed(const Duration(milliseconds: 400), () {
        Navigator.pushReplacementNamed(context, "/home");
      });
    } else {
      final friendly = LoginErrorMapper.map(result);
      _showMessage(context, friendly);
    }
  }

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
