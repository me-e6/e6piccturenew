import 'package:cloud_firestore/cloud_firestore.dart';
import '../post/create/post_model.dart';
import 'user_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileService {
  final _db = FirebaseFirestore.instance;

  // ---------------- GET USER ----------------
  Future<UserModel> getUser(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();

    if (!doc.exists) {
      return UserModel(
        uid: uid,
        email: "",
        name: "",
        type: "citizen",
        photoUrl: "",
        followersList: [],
        followingList: [],
        followersCount: 0,
        followingCount: 0,
      );
    }

    return UserModel.fromMap(doc.data()!);
  }

  // ---------------- GET USER POSTS ----------------
  Future<List<PostModel>> getUserPosts(String uid) async {
    try {
      final q = await _db
          .collection("posts")
          .where("uid", isEqualTo: uid)
          .orderBy("createdAt", descending: true)
          .get();

      return q.docs.map((d) => PostModel.fromDocument(d)).toList();
    } catch (e) {
      print("🔥 Error loading user posts: $e");
      return [];
    }
  }

  // ---------------- GET USER REPOSTS ----------------
  Future<List<PostModel>> getUserReposts(String uid) async {
    try {
      final q = await _db
          .collection("posts")
          .where("uid", isEqualTo: uid)
          .where("isRepost", isEqualTo: true)
          .orderBy("createdAt", descending: true)
          .get();

      return q.docs.map((d) => PostModel.fromDocument(d)).toList();
    } catch (e) {
      print("🔥 Error loading reposts: $e");
      return [];
    }
  }

  Future<List<PostModel>> getSavedPosts(String uid) async {
    return [];
  }

  // ---------------- UPLOAD PHOTO ----------------
  Future<String?> updateProfilePhoto(String uid, File file) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("users")
          .child(uid)
          .child("profile_${DateTime.now().millisecondsSinceEpoch}.jpg");

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await _db.collection("users").doc(uid).update({"photoUrl": url});

      return url;
    } catch (e) {
      print("🔥 Profile photo update error: $e");
      return null;
    }
  }
}
