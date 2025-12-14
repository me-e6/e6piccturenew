import 'package:cloud_firestore/cloud_firestore.dart';

class DayFeedService {
  DayFeedService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int pageSize = 15;

  // ---------------------------------------------------------------------------
  // INITIAL FETCH
  // ---------------------------------------------------------------------------

  Future<QuerySnapshot<Map<String, dynamic>>> fetchInitialFeed({
    required List<String> followingUids,
    required DateTime since,
  }) async {
    return _baseQuery(
      followingUids: followingUids,
      since: since,
    ).limit(pageSize).get();
  }

  // ---------------------------------------------------------------------------
  // PAGINATION
  // ---------------------------------------------------------------------------

  Future<QuerySnapshot<Map<String, dynamic>>> fetchMoreFeed({
    required List<String> followingUids,
    required DateTime since,
    required DocumentSnapshot lastDoc,
  }) async {
    return _baseQuery(
      followingUids: followingUids,
      since: since,
    ).startAfterDocument(lastDoc).limit(pageSize).get();
  }

  // ---------------------------------------------------------------------------
  // COUNT FOR LOGIN MESSAGE
  // ---------------------------------------------------------------------------

  Future<int> fetchTodayCount({
    required List<String> followingUids,
    required DateTime since,
  }) async {
    if (followingUids.isEmpty) return 0;

    final snapshot = await _firestore
        .collection('posts')
        .where('authorId', whereIn: _chunk(followingUids))
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .where('isRemoved', isEqualTo: false)
        .count()
        .get();

    // NON-NULLABLE in current SDK
    return snapshot.count ?? 0;
  }

  // ---------------------------------------------------------------------------
  // BASE QUERY
  // ---------------------------------------------------------------------------

  Query<Map<String, dynamic>> _baseQuery({
    required List<String> followingUids,
    required DateTime since,
  }) {
    if (followingUids.isEmpty) {
      return _firestore
          .collection('posts')
          .where('authorId', isEqualTo: '__none__');
    }

    return _firestore
        .collection('posts')
        .where('authorId', whereIn: _chunk(followingUids))
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .where('isRemoved', isEqualTo: false)
        .orderBy('createdAt', descending: true);
  }

  // ---------------------------------------------------------------------------
  // EXTENSION HOOKS (FUTURE)
  // ---------------------------------------------------------------------------

  bool shouldIncludePost(Map<String, dynamic> postData) {
    return true;
  }

  bool shouldInsertSuggestion(int index) {
    return index != 0 && index % 10 == 0;
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  List<String> _chunk(List<String> uids) {
    return uids.length <= 10 ? uids : uids.sublist(0, 10);
  }
}
