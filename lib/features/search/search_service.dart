import 'package:cloud_firestore/cloud_firestore.dart';
import '.././profile/user_model.dart';
import '.././post/create/post_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------- FETCH CURRENT USER --------------------
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // -------------------- SEARCH USERS BY NAME --------------------
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final snap = await _db
        .collection("users")
        .where("name", isGreaterThanOrEqualTo: query)
        .where("name", isLessThanOrEqualTo: "$query\uf8ff")
        .limit(20)
        .get();

    return snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
  }

  // -------------------------
  // GET MUTUAL FOLLOW LIST
  // -------------------------
  Future<List<String>> getMutualUserIds() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await _db.collection("users").doc(uid).get();

    if (!userDoc.exists) return [];

    final data = userDoc.data()!;
    final List followers = data["followers"] ?? [];
    final List following = data["following"] ?? [];

    // Mutual = intersection of both lists
    final mutuals = followers
        .where((id) => following.contains(id))
        .map((id) => id.toString())
        .toList();

    // Always include yourself
    if (!mutuals.contains(uid)) mutuals.add(uid);

    return mutuals;
  }

  // -------------------- SEARCH POSTS BY USER NAME --------------------
  Future<List<PostModel>> searchPostsByUserName(String query) async {
    if (query.trim().isEmpty) return [];

    // 1) Find users whose name matches the query
    final userSnap = await _db
        .collection("users")
        .where("name", isGreaterThanOrEqualTo: query)
        .where("name", isLessThanOrEqualTo: "$query\uf8ff")
        .limit(20)
        .get();

    final userIds = userSnap.docs
        .map((d) => d.data()["uid"] as String? ?? "")
        .where((id) => id.isNotEmpty)
        .toList();

    if (userIds.isEmpty) return [];

    // 2) Fetch posts from those users
    final postsSnap = await _db
        .collection("posts")
        .where("uid", whereIn: userIds)
        .orderBy("createdAt", descending: true)
        .limit(50)
        .get();

    return postsSnap.docs.map((d) => PostModel.fromDocument(d)).toList();
  }
}
