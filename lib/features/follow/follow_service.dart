import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ------------------------------
  /// FOLLOW USER
  /// ------------------------------
  Future<void> followUser(String targetUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentUid = currentUser.uid;

    final batch = _db.batch();

    // Current user → Add target in followingList
    final currentUserRef = _db.collection("users").doc(currentUid);
    batch.update(currentUserRef, {
      "followingList": FieldValue.arrayUnion([targetUid]),
      "followingCount": FieldValue.increment(1),
    });

    // Target user → Add current in followersList
    final targetUserRef = _db.collection("users").doc(targetUid);
    batch.update(targetUserRef, {
      "followersList": FieldValue.arrayUnion([currentUid]),
      "followersCount": FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// ------------------------------
  /// UNFOLLOW USER
  /// ------------------------------
  Future<void> unfollowUser(String targetUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentUid = currentUser.uid;

    final batch = _db.batch();

    // Current user → Remove target from followingList
    final currentUserRef = _db.collection("users").doc(currentUid);
    batch.update(currentUserRef, {
      "followingList": FieldValue.arrayRemove([targetUid]),
      "followingCount": FieldValue.increment(-1),
    });

    // Target user → Remove current from followersList
    final targetUserRef = _db.collection("users").doc(targetUid);
    batch.update(targetUserRef, {
      "followersList": FieldValue.arrayRemove([currentUid]),
      "followersCount": FieldValue.increment(-1),
    });

    await batch.commit();
  }

  /// ------------------------------
  /// CHECK IF CURRENT USER FOLLOWS SOMEONE
  /// ------------------------------
  Future<bool> isFollowing(String targetUid) async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return false;

    final doc = await _db.collection("users").doc(current.uid).get();

    final data = doc.data();
    if (data == null) return false;

    final list = List<String>.from(data["followingList"] ?? []);
    return list.contains(targetUid);
  }
}
