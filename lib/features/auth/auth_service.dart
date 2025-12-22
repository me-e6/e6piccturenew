import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // ------------------------------------------------------------
  // LOGOUT (Firebase + Google)
  // ------------------------------------------------------------
  Future<void> logout() async {
    try {
      // 🔑 Google sign out (clears cached account)
      await _googleSignIn.signOut();

      // 🔥 Firebase sign out
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // HARD LOGOUT (FOR ACCOUNT SWITCH / DEBUG)
  // ------------------------------------------------------------
  Future<void> disconnectGoogle() async {
    try {
      await _googleSignIn.disconnect();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
