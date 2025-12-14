import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImmersivePostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // --------------------------------------------------
  // TOGGLE LIKE (USED BY IMMERSIVE VIEWER)
  // --------------------------------------------------
  Future<void> toggleLike(String postId, bool currentlyLiked) async {
    final postRef = _firestore.collection("posts").doc(postId);
    final likeRef = postRef.collection("likes").doc(_uid);

    if (currentlyLiked) {
      // UNLIKE
      await likeRef.delete();
      await postRef.update({"likeCount": FieldValue.increment(-1)});
    } else {
      // LIKE
      await likeRef.set({"liked": true});
      await postRef.update({"likeCount": FieldValue.increment(1)});
    }
  }
}
