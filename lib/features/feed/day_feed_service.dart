import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../post/create/post_model.dart';

/// ------------------------------------------------------------
/// DAY FEED SERVICE — TODAY POSTS (FOLLOWERS + SYSTEM)
/// ------------------------------------------------------------
/// - Fetches posts from last 24 hours
/// - Supports pagination
/// - Separates follower vs system posts (counts only)
/// - NO visibility enforcement here
/// - NO UI logic
class DayFeedService {
  DayFeedService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int pageSize = 15;

  /// ------------------------------------------------------------
  /// FETCH TODAY POSTS (PAGINATED)
  /// ------------------------------------------------------------
  Future<DayFeedResult> fetchTodayPosts({
    required Set<String> followingUids,
    DocumentSnapshot? lastDoc,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    final DateTime startOfToday = _startOfToday();
    final Timestamp sinceTs = Timestamp.fromDate(startOfToday);

    Query<Map<String, dynamic>> query = _firestore
        .collection('posts')
        .where('createdAt', isGreaterThanOrEqualTo: sinceTs)
        .where('isRemoved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(pageSize);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snap = await query.get();

    final List<PostModel> posts = snap.docs
        .map(PostModel.fromDocument)
        .toList();

    // -------------------------
    // FOLLOWER VS SYSTEM SPLIT
    // -------------------------
    int followerCount = 0;
    int systemCount = 0;

    for (final post in posts) {
      if (followingUids.contains(post.authorId) ||
          post.authorId == currentUid) {
        followerCount++;
      } else {
        systemCount++;
      }
    }

    // -------------------------
    // MUTUALS (DERIVED)
    // -------------------------
    final mutualUids = await _getMutualUids(
      currentUid: currentUid,
      followingUids: followingUids,
    );

    return DayFeedResult(
      posts: posts,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : lastDoc,
      hasMore: snap.docs.length == pageSize,
      followerPostCount: followerCount,
      systemPostCount: systemCount,
      mutualUids: mutualUids,
      currentUid: currentUid,
    );
  }

  // ------------------------------------------------------------
  // MUTUAL DERIVATION (CANONICAL)
  // ------------------------------------------------------------
  Future<Set<String>> _getMutualUids({
    required String currentUid,
    required Set<String> followingUids,
  }) async {
    final followersSnap = await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('followers')
        .get();

    final followerUids = followersSnap.docs.map((d) => d.id).toSet();

    return followingUids.intersection(followerUids);
  }

  // ------------------------------------------------------------
  // START OF TODAY
  // ------------------------------------------------------------
  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

/// ------------------------------------------------------------
/// DAY FEED RESULT (SERVICE → CONTROLLER CONTRACT)
/// ------------------------------------------------------------
class DayFeedResult {
  final List<PostModel> posts;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  final int followerPostCount;
  final int systemPostCount;

  final Set<String> mutualUids;
  final String currentUid;

  DayFeedResult({
    required this.posts,
    required this.lastDoc,
    required this.hasMore,
    required this.followerPostCount,
    required this.systemPostCount,
    required this.mutualUids,
    required this.currentUid,
  });
}
