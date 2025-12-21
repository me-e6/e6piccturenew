/* import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// EMAIL + PASSWORD SIGNUP
  /// ----------------------
  /// Identity rules enforced here:
  /// - All users start as `citizen`
  /// - No role selection by user
  /// - Account state starts as `active`
  Future<String> signupUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create Firebase Auth user
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = cred.user;
      if (user == null) return "unknown-error";

      final DocumentReference userRef = _firestore
          .collection("users")
          .doc(user.uid);

      final FieldValue now = FieldValue.serverTimestamp();

      // 2. Create canonical Firestore user document
      await userRef.set({
        // Identity
        "uid": user.uid,
        "email": email,
        "displayName": name,
        "photoUrl": user.photoURL ?? "",

        // RBAC + STATE (STEP 1)
        "role": "citizen",
        "state": "active",
        "isVerified": false,
        "jurisdictionId": null,

        // Social counters (scalable)
        "followersCount": 0,
        "followingCount": 0,

        // Audit
        "createdAt": now,
        "updatedAt": now,
      });

      return "success";
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") return "email-already-in-use";
      if (e.code == "invalid-email") return "invalid-email";
      if (e.code == "weak-password") return "weak-password";
      return "auth-error";
    } catch (_) {
      return "unknown-error";
    }
  }
}
 */

import 'package:firebase_auth/firebase_auth.dart';
import '../../user/services/user_service.dart';

class SignupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  Future<String> signupUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) return 'unknown-error';

      await _userService.upsertUser(
        uid: user.uid,
        email: email,
        displayName: name,
        profileImageUrl: user.photoURL,
      );

      return 'success';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'email-already-in-use';
        case 'invalid-email':
          return 'invalid-email';
        case 'weak-password':
          return 'weak-password';
        default:
          return 'auth-error';
      }
    } catch (_) {
      return 'unknown-error';
    }
  }
}
