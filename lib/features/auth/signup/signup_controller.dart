// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'signup_service.dart';
import 'signup_errors.dart';

class SignupController extends ChangeNotifier {
  // Text controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Service
  final SignupService _service;

  // States
  bool isLoading = false;
  bool isPasswordVisible = false;
  String userType = "citizen"; // default

  // Constructor for testing + normal use
  SignupController({SignupService? testService})
    : _service = testService ?? SignupService();

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  // Set user type
  void setUserType(String type) {
    userType = type;
    notifyListeners();
  }

  // Main Signup logic
  Future<void> signup(BuildContext context) async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Basic validation
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage(context, "Please fill all fields");
      return;
    }

    if (password.length < 6) {
      _showMessage(context, "Password must be at least 6 characters");
      return;
    }

    _setLoading(true);

    final result = await _service.signupUser(
      name: name,
      email: email,
      password: password,
      // userType: userType,
    );

    _setLoading(false);

    if (result == "success") {
      _showMessage(context, "Account created successfully!");

      // Smooth navigation experience
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacementNamed(context, "/home");
      });
    } else {
      final friendly = SignupErrorMapper.map(result);
      // ignore: use_build_context_synchronously
      _showMessage(context, friendly);
    }
  }

  // Loading helper
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // Message helper
  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
