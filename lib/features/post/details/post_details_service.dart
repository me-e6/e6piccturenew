import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../engagement/repic_service.dart';

/// ============================================================================
/// POST DETAILS SERVICE
/// ============================================================================
/// Handles engagement actions for the Post Details screen.
/// 
/// FEATURES:
/// - ✅ Dual-write pattern for likes
/// - ✅ Dual-write pattern for saves
/// - ✅ Twitter-style Repic via RepicService
/// - ✅ Null-safe user ID handling
/// - ✅ Transaction-based operations
/// - ✅ Engagement state loading
/// ============================================================================
class PostDetailsService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final RepicService _repicService;

  PostDetailsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    RepicService? repicService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _repicService = repicService ?? RepicService();

  // --------------------------------------------------------------------------
  // HELPERS
  // --------------------------------------------------------------------------
  
  String? get _uid => _auth.currentUser?.uid;

  String get _requireUid {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in');
    return uid;
  }

  // --------------------------------------------------------------------------
  // TOGGLE LIKE (Dual-Write)
  // --------------------------------------------------------------------------
  Future<bool> toggleLike(String postId, bool currentlyLiked) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('❌ [PostDetailsService] Cannot toggle like: No user');
      return false;
    }

    final postRef = _firestore.collection('posts').doc(postId);
    final postLikeRef = postRef.collection('likes').doc(uid);
    final userLikeRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('liked_posts')
        .doc(postId);

    try {
      return await _firestore.runTransaction((tx) async {
        final now = FieldValue.serverTimestamp();

        if (currentlyLiked) {
          tx.delete(postLikeRef);
          tx.delete(userLikeRef);
          tx.update(postRef, {'likeCount': FieldValue.increment(-1)});
          debugPrint('👎 [PostDetailsService] Unliked: $postId');
        } else {
          tx.set(postLikeRef, {'uid': uid, 'likedAt': now});
          tx.set(userLikeRef, {'postId': postId, 'likedAt': now});
          tx.update(postRef, {'likeCount': FieldValue.increment(1)});
          debugPrint('👍 [PostDetailsService] Liked: $postId');
        }
        
        return true;
      });
    } catch (e) {
      debugPrint('❌ [PostDetailsService] Like error: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // TOGGLE SAVE (Dual-Write)
  // --------------------------------------------------------------------------
  Future<bool> toggleSave(String postId, bool currentlySaved) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('❌ [PostDetailsService] Cannot toggle save: No user');
      return false;
    }

    final postRef = _firestore.collection('posts').doc(postId);
    final postSaveRef = postRef.collection('saves').doc(uid);
    final userSaveRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('saved_posts')
        .doc(postId);

    try {
      return await _firestore.runTransaction((tx) async {
        final now = FieldValue.serverTimestamp();

        if (currentlySaved) {
          tx.delete(postSaveRef);
          tx.delete(userSaveRef);
          tx.update(postRef, {'saveCount': FieldValue.increment(-1)});
          debugPrint('🔖 [PostDetailsService] Unsaved: $postId');
        } else {
          tx.set(postSaveRef, {'uid': uid, 'savedAt': now});
          tx.set(userSaveRef, {'postId': postId, 'savedAt': now});
          tx.update(postRef, {'saveCount': FieldValue.increment(1)});
          debugPrint('📌 [PostDetailsService] Saved: $postId');
        }
        
        return true;
      });
    } catch (e) {
      debugPrint('❌ [PostDetailsService] Save error: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // REPIC (Twitter-Style)
  // --------------------------------------------------------------------------
  Future<String?> repic(String originalPostId) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('❌ [PostDetailsService] Cannot repic: No user');
      return null;
    }

    debugPrint('🔄 [PostDetailsService] Creating repic: $originalPostId');
    return await _repicService.createRepicPost(originalPostId);
  }

  Future<bool> undoRepic(String originalPostId) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('❌ [PostDetailsService] Cannot undo repic: No user');
      return false;
    }

    debugPrint('↩️ [PostDetailsService] Undoing repic: $originalPostId');
    return await _repicService.undoRepic(originalPostId);
  }

  // --------------------------------------------------------------------------
  // CHECK ENGAGEMENT STATE
  // --------------------------------------------------------------------------
  
  Future<bool> hasLiked(String postId) async {
    final uid = _uid;
    if (uid == null) return false;

    try {
      final doc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ [PostDetailsService] hasLiked error: $e');
      return false;
    }
  }

  Future<bool> hasSaved(String postId) async {
    final uid = _uid;
    if (uid == null) return false;

    try {
      final doc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('saves')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ [PostDetailsService] hasSaved error: $e');
      return false;
    }
  }

  Future<bool> hasRepicced(String postId) async {
    return await _repicService.hasRepicced(postId);
  }

  Future<Map<String, bool>> loadEngagementState(String postId) async {
    debugPrint('📊 [PostDetailsService] Loading engagement state: $postId');

    try {
      final results = await Future.wait([
        hasLiked(postId),
        hasSaved(postId),
        hasRepicced(postId),
      ]);

      return {
        'hasLiked': results[0],
        'hasSaved': results[1],
        'hasRepicced': results[2],
      };
    } catch (e) {
      debugPrint('❌ [PostDetailsService] Load state error: $e');
      return {
        'hasLiked': false,
        'hasSaved': false,
        'hasRepicced': false,
      };
    }
  }

  // --------------------------------------------------------------------------
  // LEGACY
  // --------------------------------------------------------------------------
  
  @Deprecated('Use repic() instead')
  Future<void> repost(
    String originalPostId,
    String imgUrl,
    String originalUid,
    String originalName,
  ) async {
    await repic(originalPostId);
  }
}
