import 'package:cloud_firestore/cloud_firestore.dart';
import '.././profile/user_model.dart';

class FollowListService {
  final FirebaseFirestore _firestore;

  FollowListService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<UserModel>> getFollowers(String uid) async {
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('followers')
        .get();

    if (snap.docs.isEmpty) return [];

    final futures = snap.docs.map((d) async {
      final userDoc = await _firestore.collection('users').doc(d.id).get();
      return userDoc.exists ? UserModel.fromDocument(userDoc) : null;
    });

    final users = await Future.wait(futures);
    return users.whereType<UserModel>().toList();
  }

  Future<List<UserModel>> getFollowing(String uid) async {
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('following')
        .get();

    if (snap.docs.isEmpty) return [];

    final futures = snap.docs.map((d) async {
      final userDoc = await _firestore.collection('users').doc(d.id).get();
      return userDoc.exists ? UserModel.fromDocument(userDoc) : null;
    });

    final users = await Future.wait(futures);
    return users.whereType<UserModel>().toList();
  }
}
