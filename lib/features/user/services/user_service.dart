import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final _users = FirebaseFirestore.instance.collection('users');

  // --------------------------------------------------
  // READ USER
  // --------------------------------------------------
  Future<UserModel?> getUser(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return UserModel.fromMap(snap.data()!);
  }

  // --------------------------------------------------
  // CREATE USER IF MISSING (AUTHORITATIVE)
  // --------------------------------------------------
  Future<UserModel> createIfMissing({
    required String uid,
    required String email,
    required String displayName,
    required String photoUrl,
  }) async {
    final ref = _users.doc(uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set(
        UserModel.newCitizenMap(
          uid: uid,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
        ),
      );

      final createdSnap = await ref.get();
      return UserModel.fromMap(createdSnap.data()!);
    }

    return UserModel.fromMap(snap.data()!);
  }
}
