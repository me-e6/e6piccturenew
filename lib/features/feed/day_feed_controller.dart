import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/state/load_state.dart';
import '../post/create/post_model.dart';
import '../follow/follow_service.dart';
import 'day_feed_service.dart';

class DayFeedController extends ChangeNotifier {
  DayFeedController({DayFeedService? feedService, FollowService? followService})
    : _feedService = feedService ?? DayFeedService(),
      _followService = followService ?? FollowService();

  final DayFeedService _feedService;
  final FollowService _followService;

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------
  LoadState state = LoadState.idle;
  String? errorMessage;

  // ------------------------------------------------------------
  // DATA
  // ------------------------------------------------------------
  final List<PostModel> _posts = [];
  List<PostModel> get posts => List.unmodifiable(_posts);

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // ------------------------------------------------------------
  // DAY ALBUM COUNTS
  // ------------------------------------------------------------
  int followerPostCount = 0;
  int systemPostCount = 0;
  int get totalPostCount => followerPostCount + systemPostCount;

  // ------------------------------------------------------------
  // ENTRY POINT
  // ------------------------------------------------------------
  Future<void> loadInitial() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _loadInitialFeed(uid);
  }

  // ------------------------------------------------------------
  // INITIAL LOAD
  // ------------------------------------------------------------
  Future<void> _loadInitialFeed(String currentUid) async {
    if (state == LoadState.loading) return;

    state = LoadState.loading;
    notifyListeners();

    try {
      _posts.clear();
      _lastDoc = null;
      _hasMore = true;

      final followingList = await _followService.getFollowingUids(currentUid);
      final followingUids = followingList.toSet();

      final result = await _feedService.fetchTodayPosts(
        followingUids: followingUids,
        lastDoc: null,
      );

      // ------------------------------------------------------------
      // SPLIT POSTS → FOLLOWER vs SYSTEM
      // ------------------------------------------------------------
      final List<PostModel> followerPosts = [];
      final List<PostModel> systemPosts = [];

      for (final post in result.posts) {
        if (_isSystemPost(
          post: post,
          followingUids: followingUids.toSet(),
          currentUid: result.currentUid,
        )) {
          systemPosts.add(post);
        } else {
          followerPosts.add(post);
        }
      }

      // ------------------------------------------------------------
      // MERGE WITH INSERTION RULES
      // ------------------------------------------------------------
      final mergedPosts = _mergeFollowerAndSystemPosts(
        followerPosts: followerPosts,
        systemPosts: systemPosts,
      );

      // ------------------------------------------------------------
      // APPLY VISIBILITY (FINAL GATE)
      // ------------------------------------------------------------
      final visiblePosts = _applyVisibilityRules(
        posts: mergedPosts,
        followingUids: followingUids.toSet(),
        mutualUids: result.mutualUids,
        currentUid: result.currentUid,
      );

      _posts.addAll(visiblePosts);
      _lastDoc = result.lastDoc;
      _hasMore = result.hasMore;

      followerPostCount = result.followerPostCount;
      systemPostCount = result.systemPostCount;

      state = _posts.isEmpty ? LoadState.empty : LoadState.success;
    } catch (e) {
      errorMessage = e.toString();
      state = LoadState.error;
    }

    notifyListeners();
  }

  // ------------------------------------------------------------
  // LOAD MORE
  // ------------------------------------------------------------
  Future<void> loadMore() async {
    if (!_hasMore || state == LoadState.loadingMore) return;

    state = LoadState.loadingMore;
    notifyListeners();

    try {
      final currentUid = FirebaseAuth.instance.currentUser!.uid;
      /*    final followingUids = (await _followService.getFollowingUids(
        currentUid,
      )).toSet(); */
      final Set<String> followingUids = {};

      final result = await _feedService.fetchTodayPosts(
        followingUids: followingUids,
        lastDoc: _lastDoc,
      );

      final visiblePosts = _applyVisibilityRules(
        posts: result.posts,
        followingUids: followingUids,
        mutualUids: result.mutualUids,
        currentUid: currentUid,
      );

      _posts.addAll(visiblePosts);
      _lastDoc = result.lastDoc;
      _hasMore = result.hasMore;

      state = LoadState.success;
    } catch (_) {
      state = LoadState.success;
    }

    notifyListeners();
  }

  // ------------------------------------------------------------
  // VISIBILITY RULES
  // ------------------------------------------------------------
  List<PostModel> _applyVisibilityRules({
    required List<PostModel> posts,
    required Set<String> followingUids,
    required Set<String> mutualUids,
    required String currentUid,
  }) {
    return posts.where((post) {
      if (post.authorId == currentUid) return true;

      switch (post.visibility) {
        case PostVisibility.public:
          return true;
        case PostVisibility.followers:
          return followingUids.contains(post.authorId);
        case PostVisibility.mutuals:
          return mutualUids.contains(post.authorId);
        case PostVisibility.private:
          return false;
      }
    }).toList();
  }

  // ------------------------------------------------------------
  // SYSTEM POST IDENTIFICATION (NO SCHEMA CHANGE)
  // ------------------------------------------------------------
  bool _isSystemPost({
    required PostModel post,
    required Set<String> followingUids,
    required String currentUid,
  }) {
    return post.authorId != currentUid &&
        !followingUids.contains(post.authorId);
  }

  // ------------------------------------------------------------
  // SYSTEM INSERTION RULE (DETERMINISTIC)
  // ------------------------------------------------------------
  bool _shouldInsertSystemPost(int index) {
    // Example rule: after every 4 posts
    return index != 0 && index % 4 == 0;
  }

  // ------------------------------------------------------------
  // MERGE FOLLOWER + SYSTEM POSTS (NO VISIBILITY HERE)
  // ------------------------------------------------------------
  List<PostModel> _mergeFollowerAndSystemPosts({
    required List<PostModel> followerPosts,
    required List<PostModel> systemPosts,
  }) {
    final List<PostModel> merged = [];
    int systemIndex = 0;

    for (int i = 0; i < followerPosts.length; i++) {
      merged.add(followerPosts[i]);

      if (_shouldInsertSystemPost(i) && systemIndex < systemPosts.length) {
        merged.add(systemPosts[systemIndex]);
        systemIndex++;
      }
    }

    // Append remaining system posts (if any)
    if (systemIndex < systemPosts.length) {
      merged.addAll(systemPosts.sublist(systemIndex));
    }

    return merged;
  }

  // ------------------------------------------------------------
  // RESET
  // ------------------------------------------------------------
  void reset() {
    _posts.clear();
    _lastDoc = null;
    _hasMore = true;
    followerPostCount = 0;
    systemPostCount = 0;
    state = LoadState.idle;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // OPTIMISTIC LIKE (FEED-SIDE ONLY)
  // ------------------------------------------------------------
  void optimisticLike(String postId, bool wasLiked) {
    final index = _posts.indexWhere((p) => p.postId == postId);
    if (index == -1) return;

    final post = _posts[index];

    _posts[index] = post.copyWith(
      hasLiked: !wasLiked,
      likeCount: wasLiked ? post.likeCount - 1 : post.likeCount + 1,
    );

    notifyListeners();
  }
}
