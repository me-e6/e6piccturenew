import 'package:flutter/material.dart';
import 'login_service.dart';
import 'login_errors.dart';

/// LoginController
/// ----------------
/// Handles:
/// - Email + Password Login
/// - OAuth2.0 Google Login
/// - UI Loading State
/// - Password Visibility Toggle
/// - Navigating to Home after successful login
///
/// This controller connects the LoginScreen (UI) with the LoginService (Firebase logic).
class LoginController extends ChangeNotifier {
  // Text field controllers bound to the UI
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // LoginService handles the actual Firebase authentication logic
  final LoginService _service;

  // UI state fields
  bool isLoading = false;
  bool isPasswordVisible = false;

  /// Constructor:
  /// Allows injecting a mock LoginService for testing.
  LoginController({LoginService? testService})
    : _service = testService ?? LoginService();

  /// Toggles the password visibility in the login form.
  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // EMAIL + PASSWORD LOGIN
  // ---------------------------------------------------------------------------
  Future<void> login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Validate empty fields
    if (email.isEmpty || password.isEmpty) {
      _showMessage(context, "Please enter email & password");
      return;
    }

    _setLoading(true);

    // Call service (returns "success" or an error code string)
    final result = await _service.loginUser(email, password);

    _setLoading(false);

    if (result == "success") {
      _showMessage(context, "Login Successful!");

      // Slight delay for UX smoothness before navigating
      Future.delayed(const Duration(milliseconds: 400), () {
        Navigator.pushReplacementNamed(context, "/home");
      });
    } else {
      // Convert Firebase errors into friendly messages
      final friendly = LoginErrorMapper.map(result);
      _showMessage(context, friendly);
    }
  }

  // ---------------------------------------------------------------------------
  // GOOGLE OAUTH2.0 LOGIN
  // ---------------------------------------------------------------------------
  ///
  /// Initiates Google Sign-In using OAuth2.0 (handled internally by Firebase SDK)
  /// Secure flow:
  ///   1. User selects Google account
  ///   2. Google issues OAuth tokens
  ///   3. Firebase converts tokens → Firebase credential
  ///   4. User is signed in securely
  ///
  Future<void> loginWithGoogle(BuildContext context) async {
    _setLoading(true);

    // Returns: "success" or a Firebase error code or "cancelled-by-user"
    final result = await _service.googleSignIn();

    _setLoading(false);

    if (result == "success") {
      _showMessage(context, "Google Login Successful!");

      Future.delayed(const Duration(milliseconds: 400), () {
        Navigator.pushReplacementNamed(context, "/home");
      });
    } else {
      final friendly = LoginErrorMapper.map(result);
      _showMessage(context, friendly);
    }
  }

  // ---------------------------------------------------------------------------
  // INTERNAL HELPER METHODS
  // ---------------------------------------------------------------------------

  /// Updates the loading state and notifies listeners (UI updates)
  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  /// Shows a Snackbar message on the screen
  void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
