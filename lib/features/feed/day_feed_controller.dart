import 'package:flutter/foundation.dart';
import 'day_album_tracker.dart';
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

  // NEW: DayAlbum tracking
  final DayAlbumStatus? albumStatus;

  const DayFeedState({
    required this.posts,
    required this.isLoading,
    required this.hasNewPosts,
    required this.sessionStartedAt,
    this.errorMessage,
    this.albumStatus, // NEW
  });

  DayFeedState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? hasNewPosts,
    DateTime? sessionStartedAt,
    String? errorMessage,
    DayAlbumStatus? albumStatus,
    bool clearAlbumStatus = false, // NEW: Allow explicit clearing
  }) {
    return DayFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasNewPosts: hasNewPosts ?? this.hasNewPosts,
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      errorMessage: errorMessage,
      albumStatus: clearAlbumStatus ? null : (albumStatus ?? this.albumStatus),
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
/// - DayAlbum tracking (NEW)
///
/// Does NOT own:
/// - Firestore queries
/// - UI state (PageView, scroll)
/// - Engagement logic
/// - Follow / mutual logic
class DayFeedController extends ChangeNotifier {
  final DayFeedService _service;
  final DayAlbumTracker _albumTracker = DayAlbumTracker(); // NEW

  DayFeedState _state = DayFeedState(
    posts: const [],
    isLoading: true,
    hasNewPosts: false,
    sessionStartedAt: DateTime.now(),
    albumStatus: null, // NEW
  );

  /// ------------------------------
  /// COMPUTED GETTERS (READ-ONLY)
  /// ------------------------------
  int get totalPostCount => _state.posts.length;

  DayFeedState get state => _state;

  // NEW: Quick access to album status
  DayAlbumStatus? get albumStatus => _state.albumStatus;
  bool get hasUnseenPosts => _state.albumStatus?.hasUnseen ?? false;

  DayFeedController(this._service);

  /// ------------------------------
  /// init()
  /// ------------------------------
  /// Called once when the feed screen is created.
  /// Starts a new feed session + checks DayAlbum status.
  Future<void> init() async {
    _setLoading(true);

    try {
      // Fetch posts
      final posts = await _service.fetchTodayFeed();

      // Check DayAlbum status (NEW)
      final albumStatus = await _albumTracker.checkUnseenPosts();

      _state = DayFeedState(
        posts: posts,
        isLoading: false,
        hasNewPosts: false,
        sessionStartedAt: DateTime.now(),
        albumStatus: albumStatus, // NEW
      );

      debugPrint(
        '✅ DayFeed initialized: ${posts.length} posts, Album status: $albumStatus',
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
  /// Replaces the entire feed session + marks DayAlbum as viewed.
  Future<void> refresh() async {
    _setLoading(true);

    try {
      final posts = await _service.fetchTodayFeed();

      // Mark DayAlbum as viewed (NEW)
      await _albumTracker.markAsViewed();

      _state = DayFeedState(
        posts: posts,
        isLoading: false,
        hasNewPosts: false,
        sessionStartedAt: DateTime.now(),
        albumStatus: null, // Clear pill after refresh (NEW)
      );

      debugPrint('✅ Feed refreshed & DayAlbum marked as viewed');
    } catch (e) {
      _setError(e.toString());
    }

    notifyListeners();
  }

  /// ------------------------------
  /// dismissAlbumPill()
  /// ------------------------------
  /// NEW: User taps the pill - mark as viewed and hide pill
  Future<void> dismissAlbumPill() async {
    if (_state.albumStatus == null || !_state.albumStatus!.hasUnseen) {
      return;
    }

    // Mark as viewed
    await _albumTracker.markAsViewed();

    // Optionally refresh feed
    await refresh();

    debugPrint('✅ DayAlbum pill dismissed');
  }

  /// ------------------------------
  /// checkAlbumStatus()
  /// ------------------------------
  /// NEW: Manually check for new posts (e.g., on app resume)
  Future<void> checkAlbumStatus() async {
    try {
      final albumStatus = await _albumTracker.checkUnseenPosts();

      _state = _state.copyWith(albumStatus: albumStatus);
      notifyListeners();

      debugPrint('✅ Album status checked: $albumStatus');
    } catch (e) {
      debugPrint('❌ Error checking album status: $e');
    }
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
  /// resetAlbumOnLogout()
  /// ------------------------------
  /// NEW: Call this when user logs out
  Future<void> resetAlbumOnLogout() async {
    await _albumTracker.resetSession();
    debugPrint('✅ DayAlbum session reset on logout');
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
      albumStatus: _state.albumStatus, // Preserve album status on error
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

  @override
  void dispose() {
    // Clean up if needed
    super.dispose();
  }
}
