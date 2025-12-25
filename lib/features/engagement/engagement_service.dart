import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'engagement_snapshot.dart';
import 'repic_service.dart';

/// ============================================================
/// ENGAGEMENT SERVICE V3 - WITH TWITTER-STYLE REPICS
/// ============================================================
/// FEATURES:
/// - Counter-first architecture
/// - Transactional dual-writes
/// - Idempotent operations
/// - Twitter-style repics (creates new post)
/// - User-side engagement index
/// ============================================================
class EngagementService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final RepicService _repicService;

  EngagementService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    RepicService? repicService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _repicService = repicService ?? RepicService();

  String? get _uid => _auth.currentUser?.uid;

  // ============================================================
  // LIKE
  // ============================================================
  Future<bool> likePost(String postId) async {
    final uid = _uid;
    if (uid == null) return false;

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
        return true; // ✅ Idempotent - already liked
      }

      final now = FieldValue.serverTimestamp();

      // ✅ DUAL-WRITE: Post-side + User-side
      tx.set(likeRef, {
        'uid': uid,
        'likedAt': now,
      });

      tx.set(userLikeRef, {
        'postId': postId,
        'likedAt': now,
      });

      // ✅ COUNTER UPDATE
      tx.update(postRef, {'likeCount': FieldValue.increment(1)});

      return true;
    });
  }

  Future<bool> unlikePost(String postId) async {
    final uid = _uid;
    if (uid == null) return false;

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
        return true; // ✅ Idempotent - already unliked
      }

      tx.delete(likeRef);
      tx.delete(userLikeRef);

      // ✅ COUNTER DECREMENT
      tx.update(postRef, {'likeCount': FieldValue.increment(-1)});

      return true;
    });
  }

  // ============================================================
  // SAVE
  // ============================================================
  Future<bool> savePost(String postId) async {
    final uid = _uid;
    if (uid == null) return false;

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
        return true; // ✅ Idempotent - already saved
      }

      final now = FieldValue.serverTimestamp();

      // ✅ DUAL-WRITE: Post-side + User-side
      tx.set(saveRef, {
        'uid': uid,
        'savedAt': now,
      });

      tx.set(userSaveRef, {
        'postId': postId,
        'savedAt': now,
      });

      // ✅ COUNTER UPDATE
      tx.update(postRef, {'saveCount': FieldValue.increment(1)});

      return true;
    });
  }

  Future<bool> unsavePost(String postId) async {
    final uid = _uid;
    if (uid == null) return false;

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
        return true; // ✅ Idempotent - already unsaved
      }

      tx.delete(saveRef);
      tx.delete(userSaveRef);

      // ✅ COUNTER DECREMENT
      tx.update(postRef, {'saveCount': FieldValue.increment(-1)});

      return true;
    });
  }

  // ============================================================
  // REPIC - TWITTER STYLE (Creates new post)
  // ============================================================
  /// Creates a Twitter-style repic that appears in feeds.
  /// Returns true if successful.
  Future<bool> repicPost(String postId) async {
    final result = await _repicService.createRepicPost(postId);
    return result != null;
  }

  /// Removes the repic post.
  /// Returns true if successful.
  Future<bool> undoRepic(String postId) async {
    return await _repicService.undoRepic(postId);
  }

  // ============================================================
  // QUOTE REPLY COUNTER
  // ============================================================
  Future<bool> incrementQuoteReplyCount(String postId) async {
    final postRef = _firestore.collection('posts').doc(postId);

    return _firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);

      if (!postSnap.exists) {
        return false;
      }

      tx.update(postRef, {'quoteReplyCount': FieldValue.increment(1)});

      return true;
    });
  }

  // ============================================================
  // REPLY COUNTER
  // ============================================================
  Future<bool> incrementReplyCount(String postId) async {
    final postRef = _firestore.collection('posts').doc(postId);

    return _firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);

      if (!postSnap.exists) {
        return false;
      }

      tx.update(postRef, {'replyCount': FieldValue.increment(1)});

      return true;
    });
  }

  // ============================================================
  // LOAD ENGAGEMENT STATE (PER-USER FLAGS)
  // ============================================================
  Future<EngagementSnapshot> loadEngagementState(String postId) async {
    final uid = _uid;
    if (uid == null) {
      return const EngagementSnapshot(
        hasLiked: false,
        hasSaved: false,
        hasRepicced: false,
      );
    }

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

  // ============================================================
  // INDIVIDUAL CHECKS
  // ============================================================
  Future<bool> hasLiked(String postId) async {
    final uid = _uid;
    if (uid == null) return false;

    final doc = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .get();

    return doc.exists;
  }

  Future<bool> hasSaved(String postId) async {
    final uid = _uid;
    if (uid == null) return false;

    final doc = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('saves')
        .doc(uid)
        .get();

    return doc.exists;
  }

  Future<bool> hasRepicced(String postId) async {
    return await _repicService.hasRepicced(postId);
  }

  // ============================================================
  // GET ENGAGEMENT LISTS
  // ============================================================
  
  /// Get users who repicced this post
  Future<List<Map<String, dynamic>>> getRepicUsers(String postId) {
    return _repicService.getRepicUsers(postId);
  }

  /// Get quote posts for this post
  Future<List<Map<String, dynamic>>> getQuotePosts(String postId) {
    return _repicService.getQuotePosts(postId);
  }

  /// Get users who liked this post
  Future<List<Map<String, dynamic>>> getLikeUsers(String postId) async {
    final snap = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .orderBy('likedAt', descending: true)
        .limit(50)
        .get();

    final List<Map<String, dynamic>> users = [];

    for (final doc in snap.docs) {
      final uid = doc.id;
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        users.add({
          'uid': uid,
          'displayName': userData['displayName'] ?? 'User',
          'handle': userData['handle'] ?? userData['username'],
          'avatarUrl': userData['profileImageUrl'] ?? userData['photoUrl'],
          'isVerified': userData['isVerified'] ?? false,
          'likedAt': doc.data()['likedAt'],
        });
      }
    }

    return users;
  }
}
