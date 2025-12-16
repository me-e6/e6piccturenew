import 'package:flutter/foundation.dart';

import '../post/create/post_model.dart';
import 'day_feed_service.dart';

/// ------------------------------
/// DayFeedState
/// ------------------------------
/// Immutable state object for the Day Feed session.
/// Replaced wholesale on updates.
class DayFeedState {
  final List<PostModel> posts;
  final bool isLoading;
  final bool hasNewPosts;
  final DateTime sessionStartedAt;
  final String? errorMessage;

  const DayFeedState({
    required this.posts,
    required this.isLoading,
    required this.hasNewPosts,
    required this.sessionStartedAt,
    this.errorMessage,
  });

  DayFeedState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? hasNewPosts,
    DateTime? sessionStartedAt,
    String? errorMessage,
  }) {
    return DayFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasNewPosts: hasNewPosts ?? this.hasNewPosts,
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      errorMessage: errorMessage,
    );
  }
}

/// ------------------------------
/// DayFeedController
/// ------------------------------
/// Owns:
/// - Feed session lifecycle
/// - Loading / error state
/// - Banner state
///
/// Does NOT own:
/// - Firestore queries
/// - UI state (PageView, scroll)
/// - Engagement logic
/// - Follow / mutual logic
class DayFeedController extends ChangeNotifier {
  final DayFeedService _service;

  DayFeedState _state = DayFeedState(
    posts: const [],
    isLoading: true,
    hasNewPosts: false,
    sessionStartedAt: DateTime.now(),
  );

  /// ------------------------------
  /// COMPUTED GETTERS (READ-ONLY)
  /// ------------------------------
  int get totalPostCount => _state.posts.length;

  DayFeedState get state => _state;

  DayFeedController(this._service);

  /// ------------------------------
  /// init()
  /// ------------------------------
  /// Called once when the feed screen is created.
  /// Starts a new feed session.
  Future<void> init() async {
    _setLoading(true);

    try {
      final posts = await _service.fetchTodayFeed();

      _state = DayFeedState(
        posts: posts,
        isLoading: false,
        hasNewPosts: false,
        sessionStartedAt: DateTime.now(),
      );
    } catch (e) {
      _setError(e.toString());
    }

    notifyListeners();
  }

  /// ------------------------------
  /// refresh()
  /// ------------------------------
  /// Explicit user action (pull-to-refresh or banner tap).
  /// Replaces the entire feed session.
  Future<void> refresh() async {
    await init();
  }

  /// ------------------------------
  /// markBannerSeen()
  /// ------------------------------
  /// Clears the "new posts available" banner state.
  void markBannerSeen() {
    if (!_state.hasNewPosts) return;

    _state = _state.copyWith(hasNewPosts: false);
    notifyListeners();
  }

  /// ------------------------------
  /// INTERNAL HELPERS
  /// ------------------------------
  void _setLoading(bool loading) {
    _state = _state.copyWith(isLoading: loading, errorMessage: null);
    notifyListeners();
  }

  void _setError(String message) {
    _state = DayFeedState(
      posts: const [],
      isLoading: false,
      hasNewPosts: false,
      sessionStartedAt: DateTime.now(),
      errorMessage: message,
    );
  }

  /// ------------------------------
  /// OPTIONAL (Future hook)
  /// ------------------------------
  /// Can be called later when background polling
  /// or push signals detect new content.
  void flagNewPostsAvailable() {
    if (_state.hasNewPosts) return;

    _state = _state.copyWith(hasNewPosts: true);
    notifyListeners();
  }
}
