import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../engagement/repic_service.dart';

/// ============================================================================
/// POST DETAILS SERVICE
/// ============================================================================
/// Handles engagement actions for the Post Details screen.
/// 
/// KEY IMPROVEMENTS:
/// - ✅ Dual-write pattern for likes (post + user subcollections)
/// - ✅ Dual-write pattern for saves (post + user subcollections)
/// - ✅ Twitter-style Repic via RepicService (creates new post)
/// - ✅ Null-safe user ID handling
/// - ✅ Transaction-based operations for consistency
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
  
  /// Current user ID (nullable for safety)
  String? get _uid => _auth.currentUser?.uid;

  /// Throws if user not logged in
  String get _requireUid {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in');
    return uid;
  }

  // --------------------------------------------------------------------------
  // LIKE / UNLIKE (Dual-Write with Transaction)
  // --------------------------------------------------------------------------
  /// Toggles like state for a post.
  /// 
  /// Writes to:
  /// - `posts/{postId}/likes/{uid}` → For counting who liked this post
  /// - `users/{uid}/liked_posts/{postId}` → For user's liked posts list
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> toggleLike(String postId, bool currentlyLiked) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('❌ [PostDetailsService] Cannot toggle like: No user logged in');
      return false;
    }

    // References
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
          // ─────────────────────────────────────────────────────────────────
          // UNLIKE
          // ─────────────────────────────────────────────────────────────────
          tx.delete(postLikeRef);
          tx.delete(userLikeRef);
          tx.update(postRef, {'likeCount': FieldValue.increment(-1)});
          
          debugPrint('👎 [PostDetailsService] Unliked post: $postId');
        } else {
          // ─────────────────────────────────────────────────────────────────
          // LIKE
          // ─────────────────────────────────────────────────────────────────
          tx.set(postLikeRef, {
            'uid': uid,
            'likedAt': now,
          });
          tx.set(userLikeRef, {
            'postId': postId,
            'likedAt': now,
          });
          tx.update(postRef, {'likeCount': FieldValue.increment(1)});
          
          debugPrint('👍 [PostDetailsService] Liked post: $postId');
        }
        
        return true;
      });
    } catch (e) {
      debugPrint('❌ [PostDetailsService] Error toggling like: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // SAVE / UNSAVE (Dual-Write with Transaction)
  // --------------------------------------------------------------------------
  /// Toggles save state for a post.
  /// 
  /// Writes to:
  /// - `posts/{postId}/saves/{uid}` → For counting who saved this post
  /// - `users/{uid}/saved_posts/{postId}` → For user's saved posts list
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> toggleSave(String postId, bool currentlySaved) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('❌ [PostDetailsService] Cannot toggle save: No user logged in');
      return false;
    }

    // References
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
          // ─────────────────────────────────────────────────────────────────
          // UNSAVE
          // ─────────────────────────────────────────────────────────────────
          tx.delete(postSaveRef);
          tx.delete(userSaveRef);
          tx.update(postRef, {'saveCount': FieldValue.increment(-1)});
          
          debugPrint('🔖 [PostDetailsService] Unsaved post: $postId');
        } else {
          // ─────────────────────────────────────────────────────────────────
          // SAVE
          // ─────────────────────────────────────────────────────────────────
          tx.set(postSaveRef, {
            'uid': uid,
            'savedAt': now,
          });
          tx.set(userSaveRef, {
            'postId': postId,
            'savedAt': now,
          });
          tx.update(postRef, {'saveCount': FieldValue.increment(1)});
          
          debugPrint('📌 [PostDetailsService] Saved post: $postId');
        }
        
        return true;
      });
    } catch (e) {
      debugPrint('❌ [PostDetailsService] Error toggling save: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // REPIC (Twitter-Style Repost)
  // --------------------------------------------------------------------------
  /// Creates a Twitter-style repic post.
  /// 
  /// This delegates to RepicService which:
  /// - Creates a new post document with `isRepic: true`
  /// - Stores denormalized original post content
  /// - Increments repicCount on original post
  /// - Writes to user's repics subcollection
  /// - Writes to post's repics subcollection
  /// 
  /// Returns the new repic post ID, or null if failed.
  Future<String?> repic(String originalPostId) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('❌ [PostDetailsService] Cannot repic: No user logged in');
      return null;
    }

    debugPrint('🔄 [PostDetailsService] Creating repic for post: $originalPostId');
    return await _repicService.createRepicPost(originalPostId);
  }

  /// Undoes a repic (removes the repic post).
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> undoRepic(String originalPostId) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('❌ [PostDetailsService] Cannot undo repic: No user logged in');
      return false;
    }

    debugPrint('↩️ [PostDetailsService] Undoing repic for post: $originalPostId');
    return await _repicService.undoRepic(originalPostId);
  }

  // --------------------------------------------------------------------------
  // CHECK ENGAGEMENT STATE
  // --------------------------------------------------------------------------
  
  /// Checks if current user has liked the post.
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
      debugPrint('❌ [PostDetailsService] Error checking like state: $e');
      return false;
    }
  }

  /// Checks if current user has saved the post.
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
      debugPrint('❌ [PostDetailsService] Error checking save state: $e');
      return false;
    }
  }

  /// Checks if current user has repicced the post.
  Future<bool> hasRepicced(String postId) async {
    return await _repicService.hasRepicced(postId);
  }

  /// Loads all engagement states at once (optimized with parallel calls).
  /// 
  /// Returns a map with keys: hasLiked, hasSaved, hasRepicced
  Future<Map<String, bool>> loadEngagementState(String postId) async {
    debugPrint('📊 [PostDetailsService] Loading engagement state for: $postId');

    try {
      // Parallel fetch for better performance
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
      debugPrint('❌ [PostDetailsService] Error loading engagement state: $e');
      return {
        'hasLiked': false,
        'hasSaved': false,
        'hasRepicced': false,
      };
    }
  }

  // --------------------------------------------------------------------------
  // LEGACY SUPPORT (Deprecated - use repic instead)
  // --------------------------------------------------------------------------
  
  /// @deprecated Use [repic] instead. This is kept for backward compatibility.
  @Deprecated('Use repic() instead for Twitter-style reposts')
  Future<void> repost(
    String originalPostId,
    String imgUrl,
    String originalUid,
    String originalName,
  ) async {
    // Redirect to new repic system
    await repic(originalPostId);
  }
}
