import 'package:cloud_firestore/cloud_firestore.dart';

import '../profile/user_model.dart';
import '../post/create/post_model.dart';

class SearchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // FETCH USER BY ID
  // ---------------------------------------------------------------------------
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDocument(doc);
  }

  // ---------------------------------------------------------------------------
  // SEARCH USERS (BY USERNAME OR DISPLAY NAME)
  // ---------------------------------------------------------------------------
  Future<List<UserModel>> searchUsers(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    // Prefer username (indexed, lowercase, unique)
    final snap = await _db
        .collection("users")
        .where("username", isGreaterThanOrEqualTo: trimmed)
        .where("username", isLessThanOrEqualTo: "$trimmed\uf8ff")
        .limit(20)
        .get();

    return snap.docs.map(UserModel.fromDocument).toList();
  }

  // ---------------------------------------------------------------------------
  // SEARCH POSTS BY AUTHOR USERNAME
  // ---------------------------------------------------------------------------
  Future<List<PostModel>> searchPostsByUserName(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    // 1️⃣ Find matching users
    final userSnap = await _db
        .collection("users")
        .where("username", isGreaterThanOrEqualTo: trimmed)
        .where("username", isLessThanOrEqualTo: "$trimmed\uf8ff")
        .limit(20)
        .get();

    final userIds = userSnap.docs
        .map((d) => d.id)
        .where((id) => id.isNotEmpty)
        .toList();

    if (userIds.isEmpty) return [];

    // 2️⃣ Fetch posts by those users
    final postsSnap = await _db
        .collection("posts")
        .where("authorId", whereIn: userIds)
        .orderBy("createdAt", descending: true)
        .limit(50)
        .get();

    return postsSnap.docs.map(PostModel.fromDocument).toList();
  }
}
