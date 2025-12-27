import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../post/create/post_model.dart';

/// ============================================================================
/// PROFILE TABS SERVICE - FIXED
/// ============================================================================
/// ✅ FIX: Added fallback queries that don't require indexes
/// ✅ FIX: Better error handling
/// ✅ FIX: Handles missing index gracefully
///
/// Handles Firestore queries for Profile Tab content:
/// - Repics (posts user has repicced)
/// - Quotes (quote posts authored by user)
/// - Saved (posts user has bookmarked)
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
  /// Data source: `users/{uid}/repics` subcollection
  /// Each doc contains: { postId, repicPostId, repickedAt }
  Future<List<PostModel>> getUserRepics(String uid) async {
    try {
      QuerySnapshot<Map<String, dynamic>> repicsSnap;
      
      // ✅ FIX: Try with orderBy first, fallback to without if index missing
      try {
        repicsSnap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('repics')
            .orderBy('repickedAt', descending: true)
            .limit(50)
            .get();
      } catch (e) {
        // Index might not exist, try without ordering
        debugPrint('⚠️ Repics index missing, fetching without order: $e');
        repicsSnap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('repics')
            .limit(50)
            .get();
      }

      if (repicsSnap.docs.isEmpty) {
        debugPrint('📭 No repics found for user: $uid');
        return [];
      }

      // Extract post IDs (the original posts that were repicced)
      final postIds = repicsSnap.docs.map((doc) {
        final data = doc.data();
        // 'postId' field contains the original post ID
        return data['postId'] as String? ?? doc.id;
      }).where((id) => id.isNotEmpty).toList();

      debugPrint('🔄 Found ${postIds.length} repics for user: $uid');

      if (postIds.isEmpty) return [];

      // Fetch actual posts
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
  Future<List<PostModel>> getUserQuotes(String uid) async {
    try {
      QuerySnapshot<Map<String, dynamic>> quotesSnap;
      
      // ✅ FIX: Try composite query, fallback to simple query
      try {
        quotesSnap = await _firestore
            .collection('posts')
            .where('authorId', isEqualTo: uid)
            .where('isQuote', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get();
      } catch (e) {
        // Composite index might not exist
        debugPrint('⚠️ Quotes composite index missing: $e');
        
        // Fallback: Get all user posts and filter client-side
        final allPosts = await _firestore
            .collection('posts')
            .where('authorId', isEqualTo: uid)
            .limit(100)
            .get();
        
        final quotes = allPosts.docs
            .where((doc) => doc.data()['isQuote'] == true)
            .toList();
        
        debugPrint('📝 Found ${quotes.length} quotes (client-filtered) for user: $uid');
        
        return quotes
            .map((doc) => PostModel.fromFirestore(doc))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

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
  Future<List<PostModel>> getUserSaved(String uid) async {
    try {
      QuerySnapshot<Map<String, dynamic>> savedSnap;
      
      // ✅ FIX: Try with orderBy, fallback to without
      try {
        savedSnap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('saved_posts')
            .orderBy('savedAt', descending: true)
            .limit(50)
            .get();
      } catch (e) {
        debugPrint('⚠️ Saved posts index missing, trying without order: $e');
        
        try {
          savedSnap = await _firestore
              .collection('users')
              .doc(uid)
              .collection('saved_posts')
              .orderBy('createdAt', descending: true)
              .limit(50)
              .get();
        } catch (e2) {
          // No index at all, just get docs
          savedSnap = await _firestore
              .collection('users')
              .doc(uid)
              .collection('saved_posts')
              .limit(50)
              .get();
        }
      }

      if (savedSnap.docs.isEmpty) {
        debugPrint('📭 No saved posts found for user: $uid');
        return [];
      }

      // Extract post IDs
      final postIds = savedSnap.docs.map((doc) {
        final data = doc.data();
        return data['postId'] as String? ?? doc.id;
      }).where((id) => id.isNotEmpty).toList();

      debugPrint('🔖 Found ${postIds.length} saved posts for user: $uid');

      if (postIds.isEmpty) return [];

      // Fetch actual posts
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

      try {
        final postsSnap = await _firestore
            .collection('posts')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        final posts = postsSnap.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList();

        allPosts.addAll(posts);
      } catch (e) {
        debugPrint('❌ Error fetching batch of posts: $e');
      }
    }

    // Sort by original order (postIds order represents chronological order)
    final idOrder = {for (int i = 0; i < postIds.length; i++) postIds[i]: i};
    allPosts.sort((a, b) {
      final aIndex = idOrder[a.postId] ?? 999;
      final bIndex = idOrder[b.postId] ?? 999;
      return aIndex.compareTo(bIndex);
    });

    return allPosts;
  }

  // --------------------------------------------------------------------------
  // STREAM VERSIONS (for real-time updates)
  // --------------------------------------------------------------------------
  
  /// Stream of user's repics (real-time)
  Stream<List<PostModel>> watchUserRepics(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('repics')
        .snapshots()
        .asyncMap((snap) async {
          if (snap.docs.isEmpty) return <PostModel>[];
          
          final postIds = snap.docs.map((doc) {
            final data = doc.data();
            return data['postId'] as String? ?? doc.id;
          }).where((id) => id.isNotEmpty).toList();
          
          return _fetchPostsByIds(postIds);
        });
  }

  /// Stream of user's saved posts (real-time)
  Stream<List<PostModel>> watchUserSaved(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('saved_posts')
        .snapshots()
        .asyncMap((snap) async {
          if (snap.docs.isEmpty) return <PostModel>[];
          
          final postIds = snap.docs.map((doc) {
            final data = doc.data();
            return data['postId'] as String? ?? doc.id;
          }).where((id) => id.isNotEmpty).toList();
          
          return _fetchPostsByIds(postIds);
        });
  }
}
