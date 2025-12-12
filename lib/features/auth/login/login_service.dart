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
