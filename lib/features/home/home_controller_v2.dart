import 'package:flutter/material.dart';
import '../feed/day_feed_controller.dart';

/// ---------------------------------------------------------------------------
/// HomeControllerV2
/// ---------------------------------------------------------------------------
/// This controller represents HOME as a gateway layer.
/// It consumes feed signals but never owns feed logic.
///
/// Safe for:
/// - feed changes
/// - suggestion engine upgrades
/// - analytics hooks
/// - AI actions
/// - messenger gating
/// - premium logic
/// ---------------------------------------------------------------------------
class HomeControllerV2 extends ChangeNotifier {
  HomeControllerV2({required DayFeedController dayFeedController})
    : _dayFeedController = dayFeedController {
    _bind();
  }

  final DayFeedController _dayFeedController;

  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------

  bool isLoading = true;

  /// Home-level message shown to the user
  String dayAlbumMessage = "";

  /// Whether Home should highlight new content
  bool hasNewContent = false;

  /// Suggested users (placeholder for now)
  final List<String> suggestedUserIds = [];

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------

  void _bind() {
    // Initial sync
    _syncFromFeed();

    // Listen to feed changes safely
    _dayFeedController.addListener(_syncFromFeed);
  }

  @override
  void dispose() {
    _dayFeedController.removeListener(_syncFromFeed);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SYNC LOGIC (SAFE & IDENTITY-BASED)
  // ---------------------------------------------------------------------------

  void _syncFromFeed() {
    isLoading = _dayFeedController.isLoading;

    dayAlbumMessage = _dayFeedController.getDayFeedMessage();

    hasNewContent = _dayFeedController.todayCount > 0;

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // EXTENSION HOOKS (INTENTIONAL NO-OPS)
  // ---------------------------------------------------------------------------

  /// Future: refresh suggestions based on taste graph
  Future<void> refreshSuggestions() async {
    // Placeholder:
    // - taste-based
    // - mutual graph
    // - creator discovery
    suggestedUserIds.clear();
    notifyListeners();
  }

  /// Future: app resume hook
  void onAppResume() {
    // Example future use:
    // - re-evaluate new content
    // - show subtle banner
  }
}
