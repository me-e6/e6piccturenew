import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../post/create/post_model.dart';

/// ============================================================================
/// DAY FEED SERVICE - v2 (With Mutuals-First Algorithm)
/// ============================================================================
/// Feed Priority Order:
/// 1. Mutuals' posts (people who follow each other)
/// 2. Following's posts
/// 3. Other posts (discover)
/// 
/// Features:
/// - ✅ Real-time streams
/// - ✅ Mutuals-first ordering
/// - ✅ Efficient batching
/// - ✅ Caching for mutuals list
/// ============================================================================
class DayFeedService {
  DayFeedService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Cache for mutuals (refreshed periodically)
  Set<String>? _mutualsCache;
  Set<String>? _followingCache;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  // --------------------------------------------------------------------------
  // FETCH TODAY FEED (WITH MUTUALS PRIORITY)
  // --------------------------------------------------------------------------
  Future<List<PostModel>> fetchTodayFeed() async {
    final DateTime now = DateTime.now();
    final DateTime since = now.subtract(const Duration(hours: 24));
    final uid = _auth.currentUser?.uid;

    try {
      // Fetch raw posts
      final querySnapshot = await _firestore
          .collection('posts')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .orderBy('createdAt', descending: true)
          .limit(100) // Fetch more to allow sorting
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final posts = querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();

      // If no user logged in, return as-is
      if (uid == null) {
        return posts.take(50).toList();
      }

      // Apply mutuals-first ordering
      return _sortByPriority(posts, uid);
    } catch (e) {
      debugPrint('❌ Error fetching feed: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // WATCH TODAY FEED (REAL-TIME WITH PRIORITY)
  // --------------------------------------------------------------------------
  Stream<List<PostModel>> watchTodayFeed() {
    final DateTime now = DateTime.now();
    final DateTime since = now.subtract(const Duration(hours: 24));
    final uid = _auth.currentUser?.uid;

    return _firestore
        .collection('posts')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) {
            return <PostModel>[];
          }

          final posts = snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();

          if (uid == null) {
            return posts.take(50).toList();
          }

          return _sortByPriority(posts, uid);
        });
  }

  // --------------------------------------------------------------------------
  // SORT BY PRIORITY (Mutuals → Following → Others)
  // --------------------------------------------------------------------------
  Future<List<PostModel>> _sortByPriority(List<PostModel> posts, String uid) async {
    // Refresh cache if needed
    await _refreshCacheIfNeeded(uid);

    final mutuals = _mutualsCache ?? {};
    final following = _followingCache ?? {};

    // Separate posts into buckets
    final List<PostModel> mutualPosts = [];
    final List<PostModel> followingPosts = [];
    final List<PostModel> otherPosts = [];

    for (final post in posts) {
      // Skip own posts from priority sorting
      if (post.authorId == uid) {
        mutualPosts.insert(0, post); // Own posts at top
        continue;
      }

      // For repics, check the repic author
      final authorToCheck = post.isRepic 
          ? (post.repicAuthorId ?? post.authorId)
          : post.authorId;

      if (mutuals.contains(authorToCheck)) {
        mutualPosts.add(post);
      } else if (following.contains(authorToCheck)) {
        followingPosts.add(post);
      } else {
        otherPosts.add(post);
      }
    }

    // Combine with priority order
    final sortedPosts = [
      ...mutualPosts,
      ...followingPosts,
      ...otherPosts,
    ];

    debugPrint('📊 Feed sorted: ${mutualPosts.length} mutuals, '
        '${followingPosts.length} following, ${otherPosts.length} others');

    return sortedPosts.take(50).toList();
  }

  // --------------------------------------------------------------------------
  // REFRESH CACHE IF NEEDED
  // --------------------------------------------------------------------------
  Future<void> _refreshCacheIfNeeded(String uid) async {
    final now = DateTime.now();
    
    if (_cacheTimestamp != null && 
        now.difference(_cacheTimestamp!) < _cacheDuration &&
        _mutualsCache != null) {
      return; // Cache is still valid
    }

    try {
      // Fetch followers
      final followersSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followers')
          .get();

      // Fetch following
      final followingSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('following')
          .get();

      final followers = followersSnap.docs.map((d) => d.id).toSet();
      final following = followingSnap.docs.map((d) => d.id).toSet();

      // Mutuals = intersection
      _mutualsCache = followers.intersection(following);
      _followingCache = following;
      _cacheTimestamp = now;

      debugPrint('✅ Cache refreshed: ${_mutualsCache!.length} mutuals, '
          '${_followingCache!.length} following');
    } catch (e) {
      debugPrint('⚠️ Error refreshing cache: $e');
      // Keep old cache if refresh fails
    }
  }

  // --------------------------------------------------------------------------
  // FORCE REFRESH CACHE
  // --------------------------------------------------------------------------
  Future<void> refreshCache() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _cacheTimestamp = null; // Invalidate cache
    await _refreshCacheIfNeeded(uid);
  }

  // --------------------------------------------------------------------------
  // WATCH SINGLE POST
  // --------------------------------------------------------------------------
  Stream<PostModel?> watchSinglePost(String postId) {
    return _firestore.collection('posts').doc(postId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PostModel.fromFirestore(doc);
    });
  }

  // --------------------------------------------------------------------------
  // GET POST COUNTS
  // --------------------------------------------------------------------------
  Future<Map<String, Map<String, int>>> getPostCounts(
    List<String> postIds,
  ) async {
    if (postIds.isEmpty) return {};
    if (postIds.length > 10) {
      throw Exception('Cannot fetch counts for more than 10 posts at once');
    }

    final snapshot = await _firestore
        .collection('posts')
        .where(FieldPath.documentId, whereIn: postIds)
        .get();

    final Map<String, Map<String, int>> counts = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      counts[doc.id] = {
        'likeCount': (data['likeCount'] as int?) ?? 0,
        'replyCount': (data['replyCount'] as int?) ?? 0,
        'quoteReplyCount': (data['quoteReplyCount'] as int?) ?? 0,
        'repicCount': (data['repicCount'] as int?) ?? 0,
        'saveCount': (data['saveCount'] as int?) ?? 0,
      };
    }

    return counts;
  }

  // --------------------------------------------------------------------------
  // GET MUTUALS COUNT (for UI display)
  // --------------------------------------------------------------------------
  Future<int> getMutualsCount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;

    await _refreshCacheIfNeeded(uid);
    return _mutualsCache?.length ?? 0;
  }

  // --------------------------------------------------------------------------
  // CHECK IF USER IS MUTUAL
  // --------------------------------------------------------------------------
  Future<bool> isMutual(String targetUid) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    await _refreshCacheIfNeeded(uid);
    return _mutualsCache?.contains(targetUid) ?? false;
  }
}
