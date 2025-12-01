import 'package:firebase_auth/firebase_auth.dart';

class LoginService {
  final FirebaseAuth _auth;

  LoginService({FirebaseAuth? testAuth})
    : _auth = testAuth ?? FirebaseAuth.instance;

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
}
