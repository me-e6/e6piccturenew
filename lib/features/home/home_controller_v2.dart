import 'package:flutter/foundation.dart';
import '../feed/day_feed_controller.dart';
import '../feed/day_feed_service.dart';

class HomeControllerV2 extends ChangeNotifier {
  final DayFeedController _dayFeed;

  /// Normal constructor (used by ProxyProvider update)
  HomeControllerV2({required DayFeedController dayFeedController})
    : _dayFeed = dayFeedController;

  /// Dummy constructor (used ONLY during provider creation)
  HomeControllerV2.empty() : _dayFeed = _DummyDayFeedController();

  String get dayAlbumMessage {
    final count = _dayFeed.totalPostCount;

    if (count == 0) {
      return "No pictures in the last 24 hours";
    }

    return "Hey, you have $count pictures to review in your Day Album";
  }
}

/// ------------------------------------------------------------
/// INTERNAL DUMMY — NEVER USED FOR REAL DATA
/// ------------------------------------------------------------
class _DummyDayFeedController extends DayFeedController {
  _DummyDayFeedController() : super(DayFeedService());
}
