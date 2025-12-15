///C:\flutter-projects\e6piccturenew\lib\features\settingsbreadcrumb\settings_services.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingsService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<String> getUserName() async {
    return "Your Name"; // Later: fetch from Firestore
  }

  Future<void> logout() async {
    // Logout from Firebase
    await _auth.signOut();

    // Logout from Google (VERY IMPORTANT)
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (_) {
      // Google may not be connected; ignore safely
    }
  }
}
