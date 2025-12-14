/* //C:\flutter-projects\e6piccturenew\lib\features\auth\login\login_service.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// LoginService
/// --------------
/// This version uses the correct mobile OAuth2.0 flow.
/// WHY?
/// - signInWithProvider() is WEB-FIRST and fails on Android/iOS.
/// - google_sign_in is the industry-standard mobile login method.
/// - FirebaseAuth.signInWithCredential() safely converts Google tokens.
/// - Supports PKCE on mobile automatically.
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
      return "unknown";
    }
  }

  // ---------------------------------------------------------------------------
  // GOOGLE OAUTH2 LOGIN (ANDROID + iOS SAFE VERSION)
  // ---------------------------------------------------------------------------
  Future<String> googleSignIn() async {
    try {
      debugPrint(
        '>> googleSignIn: start; platform: '
        '${kIsWeb ? "web" : (Platform.isAndroid
                  ? "android"
                  : Platform.isIOS
                  ? "ios"
                  : "other")}',
      );

      final GoogleSignIn googleSignIn = GoogleSignIn(
        // optional: forceAccountName: '', // not usually required
      );

      // Step 1: Launch account chooser
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      debugPrint('>> googleSignIn: googleUser = $googleUser');

      if (googleUser == null) {
        debugPrint('>> googleSignIn: user cancelled the sign-in');
        return "cancelled-by-user";
      }

      // Step 2: Get tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      debugPrint(
        '>> googleSignIn: googleAuth: accessToken=${googleAuth.accessToken != null}, idToken=${googleAuth.idToken != null}',
      );

      // Step 3: Build credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Sign with Firebase
      final userCred = await _auth.signInWithCredential(credential);
      debugPrint(
        '>> googleSignIn: firebase sign in succeeded; uid=${userCred.user?.uid}',
      );

      // Optional: create user doc
      await _createUserIfNeeded(userCred.user!);

      return "success";
    } on FirebaseAuthException catch (e, st) {
      debugPrint('>> FirebaseAuthException.code=${e.code}');
      debugPrint('>> FirebaseAuthException.message=${e.message}');
      debugPrint('>> FirebaseAuthException.stack=${st.toString()}');
      return e.code;
    } catch (e, st) {
      debugPrint('>> googleSignIn: Unknown error: $e');
      debugPrint('>> Stack: $st');
      return "unknown-error";
    }
  }

  // ---------------------------------------------------------------------------
  // CREATE USER DOCUMENT (FIRESTORE USER PROFILE)
  // ---------------------------------------------------------------------------
  Future<void> _createUserIfNeeded(User user) async {
    final userRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        "uid": user.uid,
        "email": user.email,
        "displayName": user.displayName ?? "",
        "photoURL": user.photoURL ?? "",
        "providerId": user.providerData.first.providerId,
        "createdAt": FieldValue.serverTimestamp(),
        "lastLogin": FieldValue.serverTimestamp(),
        "role": "user",
      });
    } else {
      await userRef.update({"lastLogin": FieldValue.serverTimestamp()});
    }
  }
}
 */

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
  Future<String> googleSignIn() async {
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
        return "cancelled-by-user";
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
      if (user == null) return "unknown-error";

      // Step 5: Ensure Firestore user document exists
      await _createUserIfNeeded(user);

      return "success";
    } on FirebaseAuthException catch (e, st) {
      debugPrint('>> FirebaseAuthException.code=${e.code}');
      debugPrint('>> FirebaseAuthException.message=${e.message}');
      debugPrint('>> Stack: $st');
      return e.code;
    } catch (e, st) {
      debugPrint('>> googleSignIn: unknown error: $e');
      debugPrint('>> Stack: $st');
      return "unknown-error";
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
