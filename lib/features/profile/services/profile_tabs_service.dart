import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../post/create/post_model.dart';

/// ============================================================================
/// PROFILE TABS SERVICE
/// ============================================================================
/// Handles Firestore queries for Profile Tab content:
/// - Repics (posts user has repicced)
/// - Quotes (quote posts authored by user)
/// - Saved (posts user has bookmarked) - delegates to existing method
///
/// Architecture:
/// - Uses subcollections for Repics/Saved (dual-write from EngagementService)
/// - Uses posts collection with filters for Quotes
/// ============================================================================
class ProfileTabsService {
  final FirebaseFirestore _firestore;

  ProfileTabsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // --------------------------------------------------------------------------
  // REPICS TAB
  // --------------------------------------------------------------------------
  /// Fetches posts that user has repicced
  /// 
  /// Data source: `users/{uid}/repics` subcollection (dual-write from engagement)
  /// Each doc contains: { postId, repickedAt }
  /// Then fetches actual posts from `posts` collection
  Future<List<PostModel>> getUserRepics(String uid) async {
    try {
      // Step 1: Get repic references from user's subcollection
      // Try 'repics' first, fall back to 'repic_posts' for backward compatibility
      var repicsSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('repics')
          .orderBy('repickedAt', descending: true)
          .get();

      // Fallback: Check old collection name if new one is empty
      if (repicsSnap.docs.isEmpty) {
        try {
          repicsSnap = await _firestore
              .collection('users')
              .doc(uid)
              .collection('repic_posts')
              .orderBy('createdAt', descending: true)
              .get();
        } catch (_) {
          // Index might not exist for old collection, ignore
        }
      }

      if (repicsSnap.docs.isEmpty) {
        debugPrint('📭 No repics found for user: $uid');
        return [];
      }

      // Step 2: Extract post IDs
      final postIds = repicsSnap.docs.map((doc) {
        final data = doc.data();
        return data['postId'] as String? ?? doc.id;
      }).toList();

      debugPrint('🔄 Found ${postIds.length} repics for user: $uid');

      // Step 3: Fetch actual posts (batch if > 10 for Firestore limit)
      return _fetchPostsByIds(postIds);
    } catch (e) {
      debugPrint('❌ Error fetching repics: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // QUOTES TAB
  // --------------------------------------------------------------------------
  /// Fetches quote posts authored by user
  /// 
  /// Data source: `posts` collection where authorId == uid AND isQuote == true
  /// Quote posts have: isQuote, quotedPostId, quotedPreview, commentary
  Future<List<PostModel>> getUserQuotes(String uid) async {
    try {
      final quotesSnap = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: uid)
          .where('isQuote', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('📝 Found ${quotesSnap.docs.length} quotes for user: $uid');

      return quotesSnap.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching quotes: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // SAVED TAB
  // --------------------------------------------------------------------------
  /// Fetches posts that user has saved/bookmarked
  /// 
  /// Data source: `users/{uid}/saved_posts` subcollection
  /// Each doc contains: { postId, savedAt }
  /// Then fetches actual posts from `posts` collection
  Future<List<PostModel>> getUserSaved(String uid) async {
    try {
      // Step 1: Get saved references from user's subcollection
      // Try 'savedAt' first, fall back to 'createdAt' for backward compatibility
      QuerySnapshot<Map<String, dynamic>> savedSnap;
      
      try {
        savedSnap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('saved_posts')
            .orderBy('savedAt', descending: true)
            .get();
      } catch (_) {
        // Index might not exist for savedAt, try createdAt
        savedSnap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('saved_posts')
            .orderBy('createdAt', descending: true)
            .get();
      }

      if (savedSnap.docs.isEmpty) {
        debugPrint('📭 No saved posts found for user: $uid');
        return [];
      }

      // Step 2: Extract post IDs
      final postIds = savedSnap.docs.map((doc) {
        final data = doc.data();
        return data['postId'] as String? ?? doc.id;
      }).toList();

      debugPrint('🔖 Found ${postIds.length} saved posts for user: $uid');

      // Step 3: Fetch actual posts
      return _fetchPostsByIds(postIds);
    } catch (e) {
      debugPrint('❌ Error fetching saved posts: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // HELPER: Batch fetch posts by IDs
  // --------------------------------------------------------------------------
  /// Fetches posts by IDs with Firestore's whereIn limit handling (max 10)
  Future<List<PostModel>> _fetchPostsByIds(List<String> postIds) async {
    if (postIds.isEmpty) return [];

    final List<PostModel> allPosts = [];

    // Firestore whereIn limit is 10, so batch the requests
    for (int i = 0; i < postIds.length; i += 10) {
      final batch = postIds.skip(i).take(10).toList();

      final postsSnap = await _firestore
          .collection('posts')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      final posts = postsSnap.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();

      allPosts.addAll(posts);
    }

    // Sort by original order (postIds order represents chronological order)
    // This maintains the order from the subcollection query
    final idOrder = {for (int i = 0; i < postIds.length; i++) postIds[i]: i};
    allPosts.sort((a, b) {
      final aIndex = idOrder[a.postId] ?? 999;
      final bIndex = idOrder[b.postId] ?? 999;
      return aIndex.compareTo(bIndex);
    });

    return allPosts;
  }

  // --------------------------------------------------------------------------
  // STREAM VERSIONS (for real-time updates if needed later)
  // --------------------------------------------------------------------------
  
  /// Stream of user's repics (real-time)
  Stream<List<PostModel>> watchUserRepics(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('repics')
        .orderBy('repickedAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
          if (snap.docs.isEmpty) return <PostModel>[];
          
          final postIds = snap.docs.map((doc) {
            final data = doc.data();
            return data['postId'] as String? ?? doc.id;
          }).toList();
          
          return _fetchPostsByIds(postIds);
        });
  }

  /// Stream of user's quotes (real-time)
  Stream<List<PostModel>> watchUserQuotes(String uid) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        .where('isQuote', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList());
  }

  /// Stream of user's saved posts (real-time)
  Stream<List<PostModel>> watchUserSaved(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('saved_posts')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
          if (snap.docs.isEmpty) return <PostModel>[];
          
          final postIds = snap.docs.map((doc) {
            final data = doc.data();
            return data['postId'] as String? ?? doc.id;
          }).toList();
          
          return _fetchPostsByIds(postIds);
        });
  }
}
