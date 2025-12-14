import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final _users = FirebaseFirestore.instance.collection('users');

  Future<UserModel?> getUser(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return UserModel.fromMap(snap.data()!);
  }

  Future<UserModel> createIfMissing(UserModel user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set(user.toMap());
      return user;
    }

    return UserModel.fromMap(snap.data()!);
  }
}
