import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'day_feed_service.dart';

class DayFeedController extends ChangeNotifier {
  DayFeedController({required this.followingUids, DayFeedService? service})
    : _service = service ?? DayFeedService();

  final DayFeedService _service;
  final List<String> followingUids;

  final List<DocumentSnapshot<Map<String, dynamic>>> _posts = [];
  List<DocumentSnapshot<Map<String, dynamic>>> get posts => _posts;

  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;

  int todayCount = 0;
  DocumentSnapshot? _lastDoc;

  DateTime get _since => DateTime.now().subtract(const Duration(hours: 24));

  // ---------------------------------------------------------------------------
  // OPTIMISTIC UI OVERLAY (LOCAL ONLY)
  // ---------------------------------------------------------------------------

  final Map<String, int> _optimisticLikeDelta = {};

  int optimisticLikeDeltaFor(String postId) {
    return _optimisticLikeDelta[postId] ?? 0;
  }

  void optimisticLike(String postId, bool currentlyLiked) {
    _optimisticLikeDelta[postId] =
        (_optimisticLikeDelta[postId] ?? 0) + (currentlyLiked ? -1 : 1);

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // INITIAL LOAD
  // ---------------------------------------------------------------------------

  Future<void> loadInitialFeed() async {
    isLoading = true;
    notifyListeners();

    _posts.clear();
    _lastDoc = null;
    hasMore = true;

    final snapshot = await _service.fetchInitialFeed(
      followingUids: followingUids,
      since: _since,
    );

    _applySnapshot(snapshot);

    todayCount = await _service.fetchTodayCount(
      followingUids: followingUids,
      since: _since,
    );

    isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // PAGINATION
  // ---------------------------------------------------------------------------

  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore || _lastDoc == null) return;

    isLoadingMore = true;
    notifyListeners();

    final snapshot = await _service.fetchMoreFeed(
      followingUids: followingUids,
      since: _since,
      lastDoc: _lastDoc!,
    );

    _applySnapshot(snapshot);

    isLoadingMore = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // REFRESH
  // ---------------------------------------------------------------------------

  Future<void> refresh() async {
    await loadInitialFeed();
  }

  // ---------------------------------------------------------------------------
  // LOGIN MESSAGE
  // ---------------------------------------------------------------------------

  String getDayFeedMessage() {
    if (todayCount == 0) return "No new Picctures yet";
    return "You have $todayCount new Picctures today";
  }

  // ---------------------------------------------------------------------------
  // INTERNAL
  // ---------------------------------------------------------------------------

  void _applySnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.docs.isEmpty) {
      hasMore = false;
      return;
    }

    for (final doc in snapshot.docs) {
      if (_service.shouldIncludePost(doc.data())) {
        _posts.add(doc);
      }
    }

    _lastDoc = snapshot.docs.last;
  }
}
