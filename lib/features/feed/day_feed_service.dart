/* import 'package:cloud_firestore/cloud_firestore.dart';

import '../post/create/post_model.dart';

/// ------------------------------
/// DayFeedService
/// ------------------------------
/// Stateless service responsible for fetching
/// today's feed posts from Firestore.
///
/// Guarantees:
/// - Finite result
/// - Time-bounded (last 24 hours)
/// - Ordered (newest first)
/// - No listeners
/// - No pagination
class DayFeedService {
  DayFeedService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// ------------------------------
  /// fetchTodayFeed()
  /// ------------------------------
  /// Fetches posts created in the last 24 hours.
  ///
  /// NOTE:
  /// Visibility enforcement (public/followers/mutuals/private)
  /// is assumed to be handled by:
  /// - Firestore security rules
  /// - Or pre-filtered queries (later phase)
  ///
  /// This method intentionally stays simple and safe.
  Future<List<PostModel>> fetchTodayFeed() async {
    final DateTime now = DateTime.now();
    final DateTime since = now.subtract(const Duration(hours: 24));

    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Let controller decide how to surface the error
      rethrow;
    }
  }
}
 */

import 'package:cloud_firestore/cloud_firestore.dart';

import '../post/create/post_model.dart';

/// ------------------------------
/// DayFeedService
/// ------------------------------
/// ✅ FIXED: Added real-time streams for engagement counters
///
/// Provides BOTH:
/// 1. fetchTodayFeed() - One-time fetch (existing)
/// 2. watchTodayFeed() - Real-time stream (NEW)
///
/// Guarantees:
/// - Finite result
/// - Time-bounded (last 24 hours)
/// - Ordered (newest first)
/// - Real-time updates for counters
class DayFeedService {
  DayFeedService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// ------------------------------
  /// fetchTodayFeed() - ONE-TIME FETCH
  /// ------------------------------
  /// Use for initial load or manual refresh
  Future<List<PostModel>> fetchTodayFeed() async {
    final DateTime now = DateTime.now();
    final DateTime since = now.subtract(const Duration(hours: 24));

    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// ------------------------------
  /// watchTodayFeed() - REAL-TIME STREAM ✅ NEW
  /// ------------------------------
  /// Returns a stream that emits whenever:
  /// - New posts are created
  /// - Engagement counters change (like, reply, quote)
  /// - Posts are deleted
  ///
  /// Controller should subscribe to this for live updates
  Stream<List<PostModel>> watchTodayFeed() {
    final DateTime now = DateTime.now();
    final DateTime since = now.subtract(const Duration(hours: 24));

    return _firestore
        .collection('posts')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return <PostModel>[];
          }

          return snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
        });
  }

  /// ------------------------------
  /// watchSinglePost() - REAL-TIME POST ✅ NEW
  /// ------------------------------
  /// Watch a specific post for real-time counter updates
  /// Useful for detail views or featured posts
  Stream<PostModel?> watchSinglePost(String postId) {
    return _firestore.collection('posts').doc(postId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PostModel.fromFirestore(doc);
    });
  }

  /// ------------------------------
  /// getPostCounts() - ATOMIC READ ✅ NEW
  /// ------------------------------
  /// Get current engagement counts for multiple posts
  /// Useful for batch updates or reconciliation
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
      };
    }

    return counts;
  }
}
