import 'package:cloud_firestore/cloud_firestore.dart';

class HomeService {
  final _db = FirebaseFirestore.instance;

  /// ---------------------------------------------------------
  /// Fetch list of UIDs that current user follows
  /// Path: users/{uid}/following/{otherUid}
  /// ---------------------------------------------------------
  Future<List<String>> getFollowing(String uid) async {
    final snap = await _db
        .collection("users")
        .doc(uid)
        .collection("following")
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  /// ---------------------------------------------------------
  /// Fetch list of followers
  /// Path: users/{uid}/followers/{otherUid}
  /// ---------------------------------------------------------
  Future<List<String>> getFollowers(String uid) async {
    final snap = await _db
        .collection("users")
        .doc(uid)
        .collection("followers")
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  /// ---------------------------------------------------------
  /// MUTUALS = users whom I follow AND they follow me.
  /// ---------------------------------------------------------
  Future<List<String>> getMutuals(String uid) async {
    final following = await getFollowing(uid);
    final followers = await getFollowers(uid);

    // intersection
    final mutuals = following.toSet().intersection(followers.toSet()).toList();
    return mutuals;
  }

  /// ---------------------------------------------------------
  /// Fetch Officer UIDs
  /// officers are users where "type" == "officer"
  /// ---------------------------------------------------------
  Future<List<String>> getOfficerUids() async {
    final q = await _db
        .collection("users")
        .where("type", isEqualTo: "officer")
        .get();
    return q.docs.map((d) => d.id).toList();
  }
}
