import 'package:cloud_firestore/cloud_firestore.dart';

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
