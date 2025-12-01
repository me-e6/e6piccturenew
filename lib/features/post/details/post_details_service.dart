import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  // LIKE / UNLIKE
  Future<void> toggleLike(String postId, bool currentlyLiked) async {
    final postRef = _firestore.collection("posts").doc(postId);

    if (currentlyLiked) {
      // unlike
      await postRef.collection("likes").doc(uid).delete();
      await postRef.update({"likeCount": FieldValue.increment(-1)});
    } else {
      // like
      await postRef.collection("likes").doc(uid).set({"liked": true});
      await postRef.update({"likeCount": FieldValue.increment(1)});
    }
  }

  // SAVE / UNSAVE
  Future<void> toggleSave(String postId, bool currentlySaved) async {
    final saveRef = _firestore
        .collection("users")
        .doc(uid)
        .collection("saved")
        .doc(postId);

    if (currentlySaved) {
      await saveRef.delete();
    } else {
      await saveRef.set({"saved": true});
    }
  }

  // REPOST (RE-PIC)
  Future<void> repost(
    String originalPostId,
    String imgUrl,
    String originalUid,
    String originalName,
  ) async {
    final newRef = _firestore.collection("posts").doc();

    await newRef.set({
      "postId": newRef.id,
      "uid": uid,
      "imageUrl": imgUrl,
      "isRepost": true,
      "originalOwnerUid": originalUid,
      "originalOwnerName": originalName,
      "repostedByUid": uid,
      "repostedByName": _auth.currentUser!.email,
      "likeCount": 0,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
}
