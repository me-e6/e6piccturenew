import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Main function to sign up user
  Future<String> signupUser({
    required String name,
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      // 1. Firebase Auth - Create user
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user?.uid;
      if (uid == null) return "unknown-error";

      // 2. Save user profile in Firestore
      await _firestore.collection("users").doc(uid).set({
        "uid": uid,
        "name": name,
        "email": email,
        "userType": userType,
        "createdAt": FieldValue.serverTimestamp(),
        "profileImage": null, // future extension
        "followers": [],
        "following": [],
      });

      return "success";
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth errors cleanly
      if (e.code == "email-already-in-use") return "email-already-in-use";
      if (e.code == "invalid-email") return "invalid-email";
      if (e.code == "weak-password") return "weak-password";
      return "auth-error";
    } catch (e) {
      // Anything else
      return "unknown-error";
    }
  }
}
