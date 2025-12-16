import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EngagementService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ------------------------------------------------------------
  // LIKE
  // ------------------------------------------------------------
  Future<void> likePost(String postId) async {
    final ref = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((tx) async {
      tx.update(ref, {'likeCount': FieldValue.increment(1)});

      tx.set(ref.collection('likes').doc(_uid), {
        'likedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ------------------------------------------------------------
  // UNLIKE
  // ------------------------------------------------------------
  Future<void> unlikePost(String postId) async {
    final ref = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((tx) async {
      tx.update(ref, {'likeCount': FieldValue.increment(-1)});

      tx.delete(ref.collection('likes').doc(_uid));
    });
  }

  // ------------------------------------------------------------
  // SAVE
  // ------------------------------------------------------------
  Future<void> savePost(String postId, bool save) async {
    final ref = _firestore
        .collection('users')
        .doc(_uid)
        .collection('savedPosts')
        .doc(postId);

    if (save) {
      await ref.set({'savedAt': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }

  // ------------------------------------------------------------
  // SHARE (ANALYTICS HOOK)
  // ------------------------------------------------------------
  Future<void> sharePost(String postId) async {
    await _firestore.collection('postShares').add({
      'postId': postId,
      'userId': _uid,
      'sharedAt': FieldValue.serverTimestamp(),
    });
  }
}
