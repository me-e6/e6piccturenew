import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'engagement_snapshot.dart';

class EngagementService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  EngagementService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  // ------------------------------------------------------------
  // LIKE
  // ------------------------------------------------------------
  Future<bool> likePost(String postId) async {
    final uid = _auth.currentUser!.uid;

    final postRef = _firestore.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(uid);
    final userLikeRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('liked_posts')
        .doc(postId);

    return _firestore.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);

      if (likeSnap.exists) {
        return true; // idempotent
      }

      tx.set(likeRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});

      tx.set(userLikeRef, {
        'postId': postId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(postRef, {'likeCount': FieldValue.increment(1)});

      return true;
    });
  }

  Future<bool> unlikePost(String postId) async {
    final uid = _auth.currentUser!.uid;

    final postRef = _firestore.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(uid);
    final userLikeRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('liked_posts')
        .doc(postId);

    return _firestore.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);

      if (!likeSnap.exists) {
        return true; // idempotent
      }

      tx.delete(likeRef);
      tx.delete(userLikeRef);

      tx.update(postRef, {'likeCount': FieldValue.increment(-1)});

      return true;
    });
  }

  // ------------------------------------------------------------
  // SAVE
  // ------------------------------------------------------------
  Future<bool> savePost(String postId) async {
    final uid = _auth.currentUser!.uid;

    final postRef = _firestore.collection('posts').doc(postId);
    final saveRef = postRef.collection('saves').doc(uid);
    final userSaveRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('saved_posts')
        .doc(postId);

    return _firestore.runTransaction((tx) async {
      final saveSnap = await tx.get(saveRef);

      if (saveSnap.exists) {
        return true;
      }

      tx.set(saveRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});

      tx.set(userSaveRef, {
        'postId': postId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(postRef, {'saveCount': FieldValue.increment(1)});

      return true;
    });
  }

  Future<bool> unsavePost(String postId) async {
    final uid = _auth.currentUser!.uid;

    final postRef = _firestore.collection('posts').doc(postId);
    final saveRef = postRef.collection('saves').doc(uid);
    final userSaveRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('saved_posts')
        .doc(postId);

    return _firestore.runTransaction((tx) async {
      final saveSnap = await tx.get(saveRef);

      if (!saveSnap.exists) {
        return true;
      }

      tx.delete(saveRef);
      tx.delete(userSaveRef);

      tx.update(postRef, {'saveCount': FieldValue.increment(-1)});

      return true;
    });
  }

  // ------------------------------------------------------------
  // REPIC (REPOST WITHOUT TEXT)
  // ------------------------------------------------------------
  Future<bool> repicPost(String postId) async {
    final uid = _auth.currentUser!.uid;

    final postRef = _firestore.collection('posts').doc(postId);
    final repicRef = postRef.collection('repics').doc(uid);
    final userRepicRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('repic_posts')
        .doc(postId);

    return _firestore.runTransaction((tx) async {
      final repicSnap = await tx.get(repicRef);

      if (repicSnap.exists) {
        return true;
      }

      tx.set(repicRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});

      tx.set(userRepicRef, {
        'postId': postId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(postRef, {'repicCount': FieldValue.increment(1)});

      return true;
    });
  }

  Future<bool> undoRepic(String postId) async {
    final uid = _auth.currentUser!.uid;

    final postRef = _firestore.collection('posts').doc(postId);
    final repicRef = postRef.collection('repics').doc(uid);
    final userRepicRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('repic_posts')
        .doc(postId);

    return _firestore.runTransaction((tx) async {
      final repicSnap = await tx.get(repicRef);

      if (!repicSnap.exists) {
        return true;
      }

      tx.delete(repicRef);
      tx.delete(userRepicRef);

      tx.update(postRef, {'repicCount': FieldValue.increment(-1)});

      return true;
    });
  }

  // ------------------------------------------------------------
  // QUOTE REPLY (COUNTER ONLY — POST CREATION HANDLED ELSEWHERE)
  // ------------------------------------------------------------
  Future<void> incrementQuoteReplyCount(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'quoteReplyCount': FieldValue.increment(1),
    });
  }

  // ------------------------------------------------------------
  // REPLY (LIGHTWEIGHT, FUTURE-SAFE)
  // ------------------------------------------------------------
  Future<void> incrementReplyCount(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'replyCount': FieldValue.increment(1),
    });
  }

  // ---------------------------- Enagatement Snapshot ----------------------------
  Future<EngagementSnapshot> loadEngagementState(String postId) async {
    final uid = _auth.currentUser!.uid;
    final postRef = _firestore.collection('posts').doc(postId);

    final likeRef = postRef.collection('likes').doc(uid);
    final saveRef = postRef.collection('saves').doc(uid);
    final repicRef = postRef.collection('repics').doc(uid);

    final results = await Future.wait([
      likeRef.get(),
      saveRef.get(),
      repicRef.get(),
    ]);

    return EngagementSnapshot(
      hasLiked: results[0].exists,
      hasSaved: results[1].exists,
      hasRepicced: results[2].exists,
    );
  }
}
