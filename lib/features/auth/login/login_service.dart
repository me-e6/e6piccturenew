import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// LoginService
/// ------------
/// Handles:
/// - Email/password login
/// - Google OAuth login (mobile-safe)
/// - User bootstrap into Firestore
///
/// IMPORTANT:
/// - No role selection
/// - No role overwrite on re-login
/// - Canonical user schema enforced
class LoginService {
  final FirebaseAuth _auth;

  LoginService({FirebaseAuth? testAuth})
    : _auth = testAuth ?? FirebaseAuth.instance;

  // ---------------------------------------------------------------------------
  // EMAIL + PASSWORD LOGIN
  // ---------------------------------------------------------------------------
  Future<String> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (_) {
      return "unknown-error";
    }
  }

  // ---------------------------------------------------------------------------
  // GOOGLE OAUTH2 LOGIN (ANDROID + iOS)
  // ---------------------------------------------------------------------------
  Future<User?> googleSignIn() async {
    try {
      debugPrint(
        '>> googleSignIn: start; platform: '
        '${kIsWeb ? "web" : (Platform.isAndroid
                  ? "android"
                  : Platform.isIOS
                  ? "ios"
                  : "other")}',
      );

      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Step 1: Launch account chooser
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null; // cancelled by user
      }

      // Step 2: Fetch OAuth tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Step 3: Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Firebase Auth sign-in
      final UserCredential userCred = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCred.user;
      if (user == null) return null;

      // Step 5: Ensure Firestore user document exists
      try {
        await _createUserIfNeeded(user);
      } catch (e) {
        debugPrint('>> Firestore bootstrap failed, continuing login: $e');
      }

      return user;
    } on FirebaseAuthException catch (e, st) {
      debugPrint('>> FirebaseAuthException.code=${e.code}');
      debugPrint('>> FirebaseAuthException.message=${e.message}');
      debugPrint('>> Stack: $st');
      rethrow;
    } catch (e, st) {
      debugPrint('>> googleSignIn: unknown error: $e');
      debugPrint('>> Stack: $st');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // FIRESTORE USER BOOTSTRAP (STEP 1 CORE)
  // ---------------------------------------------------------------------------
  Future<void> _createUserIfNeeded(User user) async {
    final DocumentReference userRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid);

    final DocumentSnapshot doc = await userRef.get();
    final FieldValue now = FieldValue.serverTimestamp();

    if (!doc.exists) {
      // First-time login → create canonical user
      await userRef.set({
        // Identity
        "uid": user.uid,
        "email": user.email ?? "",
        "displayName": user.displayName ?? "",
        "photoUrl": user.photoURL ?? "",

        // RBAC + STATE (STEP 1)
        "role": "citizen",
        "state": "active",
        "isVerified": false,
        "jurisdictionId": null,

        // Social counters
        "followersCount": 0,
        "followingCount": 0,

        // Audit
        "createdAt": now,
        "updatedAt": now,
      });
    } else {
      // Returning user → audit update only
      await userRef.update({"updatedAt": now});
    }
  }
}
