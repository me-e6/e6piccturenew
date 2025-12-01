import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../post/create/post_model.dart';
import '../search/search_service.dart';

class HomeController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SearchService _searchService = SearchService();

  /// Local memory cache
  List<PostModel> _cachedFeed = [];

  /// UI state
  List<PostModel> feedPosts = [];
  bool isLoading = true;
  bool isMoreLoading = false;

  /// Offline mode flag
  bool isOffline = false;

  /// Pagination cursor
  DocumentSnapshot? lastDoc;
  bool hasMore = true;

  HomeController() {
    _initialize();
  }

  // --------------------------------------------------------
  // INITIAL LOAD (CACHE FIRST, THEN SERVER)
  // --------------------------------------------------------
  Future<void> _initialize() async {
    // 1) Load from cache immediately if available
    if (_cachedFeed.isNotEmpty) {
      feedPosts = List<PostModel>.from(_cachedFeed);
      notifyListeners();
    }

    // 2) Load fresh feed from Firestore
    await loadFeed();
  }

  // --------------------------------------------------------
  // LOAD FIRST PAGE
  // --------------------------------------------------------
  Future<void> loadFeed() async {
    isLoading = true;
    notifyListeners();

    try {
      final List<String> mutuals = await _searchService.getMutualUserIds();

      Query query = _db
          .collection("posts")
          .where("uid", whereIn: mutuals.isEmpty ? ["dummy"] : mutuals)
          .orderBy("createdAt", descending: true)
          .limit(10);

      final snapshot = await query.get();

      feedPosts = snapshot.docs.map((d) => PostModel.fromDocument(d)).toList();

      // Update cache
      _cachedFeed = List<PostModel>.from(feedPosts);

      // Mark online
      isOffline = false;

      if (snapshot.docs.isNotEmpty) {
        lastDoc = snapshot.docs.last;
      }

      hasMore = snapshot.docs.length == 10;
    } catch (e) {
      // No internet → fallback to cached data
      isOffline = true;

      feedPosts = List<PostModel>.from(_cachedFeed);
    }

    isLoading = false;
    notifyListeners();
  }

  // --------------------------------------------------------
  // LOAD NEXT PAGE (pagination)
  // --------------------------------------------------------
  Future<void> loadMore() async {
    if (!hasMore || isMoreLoading || lastDoc == null) return;

    isMoreLoading = true;
    notifyListeners();

    try {
      final List<String> mutuals = await _searchService.getMutualUserIds();

      Query query = _db
          .collection("posts")
          .where("uid", whereIn: mutuals.isEmpty ? ["dummy"] : mutuals)
          .orderBy("createdAt", descending: true)
          .startAfterDocument(lastDoc!)
          .limit(10);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final newPosts = snapshot.docs
            .map((d) => PostModel.fromDocument(d))
            .toList();

        feedPosts.addAll(newPosts);

        // Update cache
        _cachedFeed = List<PostModel>.from(feedPosts);

        lastDoc = snapshot.docs.last;
      }

      hasMore = snapshot.docs.length == 10;
      isOffline = false;
    } catch (e) {
      // Stay offline, keep cached data
      isOffline = true;
    }

    isMoreLoading = false;
    notifyListeners();
  }

  // --------------------------------------------------------
  // PULL-TO-REFRESH — clears cache and fetches fresh page
  // --------------------------------------------------------
  Future<void> refreshFeed() async {
    lastDoc = null;
    hasMore = true;

    feedPosts.clear();
    _cachedFeed.clear();

    await loadFeed();
  }
}
