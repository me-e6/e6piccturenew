import 'package:cloud_firestore/cloud_firestore.dart';

class FollowService {
  FollowService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // --------------------------------------------------
  // FOLLOW
  // --------------------------------------------------
  Future<void> follow({
    required String currentUid,
    required String targetUid,
  }) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    final currentUserRef = _firestore.collection('users').doc(currentUid);
    final targetUserRef = _firestore.collection('users').doc(targetUid);

    batch.set(currentUserRef.collection('following').doc(targetUid), {
      'createdAt': now,
    });

    batch.set(targetUserRef.collection('followers').doc(currentUid), {
      'createdAt': now,
    });

    batch.update(currentUserRef, {'followingCount': FieldValue.increment(1)});

    batch.update(targetUserRef, {'followersCount': FieldValue.increment(1)});

    await batch.commit();
  }

  // --------------------------------------------------
  // UNFOLLOW
  // --------------------------------------------------
  Future<void> unfollow({
    required String currentUid,
    required String targetUid,
  }) async {
    final batch = _firestore.batch();

    final currentUserRef = _firestore.collection('users').doc(currentUid);
    final targetUserRef = _firestore.collection('users').doc(targetUid);

    batch.delete(currentUserRef.collection('following').doc(targetUid));

    batch.delete(targetUserRef.collection('followers').doc(currentUid));

    batch.update(currentUserRef, {'followingCount': FieldValue.increment(-1)});

    batch.update(targetUserRef, {'followersCount': FieldValue.increment(-1)});

    await batch.commit();
  }

  // --------------------------------------------------
  // CHECK FOLLOWING
  // --------------------------------------------------
  Future<bool> isFollowing({
    required String currentUid,
    required String targetUid,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('following')
        .doc(targetUid)
        .get();

    return doc.exists;
  }

  // --------------------------------------------------
  // FETCH FOLLOWING IDS (FEED CRITICAL)
  // --------------------------------------------------
  Future<List<String>> getFollowingUids(String uid) async {
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('following')
        .get();

    return snap.docs.map((d) => d.id).toList();
  }

  Future<int> getFollowersCount(String uid) async {
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('followers')
        .get();

    return snap.size;
  }

  Future<int> getFollowingCount(String uid) async {
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('following')
        .get();

    return snap.size;
  }
}
