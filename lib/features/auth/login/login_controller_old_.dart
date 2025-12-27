/* import 'package:flutter/material.dart';
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
      // ignore: use_build_context_synchronously
      _showMessage(context, "Login Successful!");

      // Slight delay for UX smoothness before navigating
      Future.delayed(const Duration(milliseconds: 400), () {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, "/home");
      });
    } else {
      // Convert Firebase errors into friendly messages
      final friendly = LoginErrorMapper.map(result);
      // ignore: use_build_context_synchronously
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

    try {
      final user = await _service.googleSignIn();

      _setLoading(false);

      // User cancelled Google account chooser
      if (user == null) {
        _showMessage(context, "Google login cancelled");
        return;
      }

      // Critical: email must exist
      if (user.email == null || user.email!.isEmpty) {
        await user.delete(); // clean up partial user
        _showMessage(context, "No email selected for Google account");
        return;
      }

      _showMessage(context, "Google Login Successful!");

      Future.delayed(const Duration(milliseconds: 400), () {
        Navigator.pushReplacementNamed(context, "/home");
      });
    } catch (e) {
      _setLoading(false);
      _showMessage(context, "Google login failed. Please try again.");
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
 */

import 'package:flutter/material.dart';
import 'login_service.dart';
import 'login_errors.dart';

/// LoginController - FIXED
/// ----------------
/// Handles:
/// - Email + Password Login
/// - OAuth2.0 Google Login
/// - UI Loading State
/// - Password Visibility Toggle
/// - Navigating to Home after successful login
///
/// ✅ FIX: Added _isDisposed check to prevent "used after disposed" errors
class LoginController extends ChangeNotifier {
  // Text field controllers bound to the UI
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // LoginService handles the actual Firebase authentication logic
  final LoginService _service;

  // UI state fields
  bool isLoading = false;
  bool isPasswordVisible = false;

  // ✅ FIX: Track disposal state
  bool _isDisposed = false;

  /// Constructor:
  /// Allows injecting a mock LoginService for testing.
  LoginController({LoginService? testService})
    : _service = testService ?? LoginService();

  /// ✅ FIX: Safe notifyListeners that checks disposal
  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Toggles the password visibility in the login form.
  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    _safeNotify();
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

    // ✅ FIX: Check if disposed after async operation
    if (_isDisposed) return;

    _setLoading(false);

    if (result == "success") {
      _showMessage(context, "Login Successful!");

      // Slight delay for UX smoothness before navigating
      Future.delayed(const Duration(milliseconds: 400), () {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, "/home");
        }
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

    try {
      final user = await _service.googleSignIn();

      // ✅ FIX: Check if disposed after async operation
      if (_isDisposed) return;

      _setLoading(false);

      // User cancelled Google account chooser
      if (user == null) {
        _showMessage(context, "Google login cancelled");
        return;
      }

      // Critical: email must exist
      if (user.email == null || user.email!.isEmpty) {
        await user.delete(); // clean up partial user
        _showMessage(context, "No email selected for Google account");
        return;
      }

      _showMessage(context, "Google Login Successful!");

      Future.delayed(const Duration(milliseconds: 400), () {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, "/home");
        }
      });
    } catch (e) {
      // ✅ FIX: Check if disposed after async operation
      if (_isDisposed) return;

      _setLoading(false);
      _showMessage(context, "Google login failed. Please try again.");
    }
  }

  // ---------------------------------------------------------------------------
  // INTERNAL HELPER METHODS
  // ---------------------------------------------------------------------------

  /// Updates the loading state and notifies listeners (UI updates)
  void _setLoading(bool val) {
    isLoading = val;
    _safeNotify(); // ✅ FIX: Use safe notify
  }

  /// Shows a Snackbar message on the screen
  void _showMessage(BuildContext context, String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ---------------------------------------------------------------------------
  // DISPOSAL
  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    _isDisposed = true; // ✅ FIX: Mark as disposed BEFORE calling super
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
