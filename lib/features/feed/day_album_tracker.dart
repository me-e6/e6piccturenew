import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../post/create/post_model.dart';

/// ---------------------------------------------------------------------------
/// DAY ALBUM TRACKER - Manages 24-hour session and unseen posts
/// ---------------------------------------------------------------------------
/// Responsibilities:
/// - Track last viewed timestamp (SharedPreferences)
/// - Query Firestore for 24h window posts
/// - Calculate unseen posts since last view
/// - Return DayAlbumStatus with appropriate messaging
///
/// Does NOT own:
/// - UI state
/// - Controller logic
/// - Post engagement
class DayAlbumTracker {
  static const String _lastViewedKey = 'day_album_last_viewed';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DayAlbumTracker({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Get the current user's UID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// ---------------------------------------------------------------------------
  /// CHECK FOR UNSEEN POSTS - Called on app launch or when needed
  /// ---------------------------------------------------------------------------
  /// Logic:
  /// 1. If first visit OR 24h+ gap → Show all posts in current 24h window
  /// 2. If within 24h → Show only posts created AFTER last viewed time
  /// 3. If no new posts → Return hasUnseen: false
  Future<DayAlbumStatus> checkUnseenPosts() async {
    if (_currentUserId == null) {
      debugPrint('⚠️ No authenticated user - skipping album check');
      return DayAlbumStatus(hasUnseen: false, unseenCount: 0, totalInWindow: 0);
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get last viewed timestamp (null if first visit)
      final lastViewedMillis = prefs.getInt(_lastViewedKey);
      final lastViewedTime = lastViewedMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(lastViewedMillis)
          : null;

      // Calculate 24-hour window
      final now = DateTime.now();
      final windowStart = now.subtract(const Duration(hours: 24));

      debugPrint(
        '🔍 Checking DayAlbum: Last viewed = $lastViewedTime, Window = $windowStart to $now',
      );

      // Query posts in the last 24 hours (matches your DayFeedService logic)
      final querySnapshot = await _firestore
          .collection('posts')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(windowStart),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('createdAt', descending: true)
          .limit(100) // Reasonable limit to avoid huge queries
          .get();

      final totalInWindow = querySnapshot.docs.length;
      debugPrint('📊 Found $totalInWindow posts in 24h window');

      // CASE 1: First visit ever OR more than 24h since last visit
      if (lastViewedTime == null ||
          now.difference(lastViewedTime).inHours >= 24) {
        debugPrint('📱 First visit or 24h+ gap detected');

        if (totalInWindow == 0) {
          return DayAlbumStatus(
            hasUnseen: false,
            unseenCount: 0,
            totalInWindow: 0,
          );
        }

        return DayAlbumStatus(
          hasUnseen: true,
          unseenCount: totalInWindow,
          totalInWindow: totalInWindow,
          message:
              'Day Album has $totalInWindow ${totalInWindow > 1 ? 'Picctures' : 'Piccture'}',
        );
      }

      // CASE 2: Within 24h - count posts AFTER last viewed time
      final unseenPosts = querySnapshot.docs.where((doc) {
        try {
          final post = PostModel.fromFirestore(doc);
          return post.createdAt.isAfter(lastViewedTime);
        } catch (e) {
          debugPrint('⚠️ Error parsing post ${doc.id}: $e');
          return false;
        }
      }).toList();

      final unseenCount = unseenPosts.length;
      debugPrint('📱 $unseenCount unseen posts since last view');

      // CASE 3: New posts since last view
      if (unseenCount > 0) {
        return DayAlbumStatus(
          hasUnseen: true,
          unseenCount: unseenCount,
          totalInWindow: totalInWindow,
          message:
              '$unseenCount new ${unseenCount > 1 ? 'Picctures' : 'Piccture'} in Day Album',
        );
      }

      // CASE 4: No new posts
      return DayAlbumStatus(
        hasUnseen: false,
        unseenCount: 0,
        totalInWindow: totalInWindow,
      );
    } catch (e) {
      debugPrint('❌ Error checking unseen posts: $e');
      return DayAlbumStatus(
        hasUnseen: false,
        unseenCount: 0,
        totalInWindow: 0,
        errorMessage: e.toString(),
      );
    }
  }

  /// ---------------------------------------------------------------------------
  /// MARK AS VIEWED - Called when user taps pill or refreshes feed
  /// ---------------------------------------------------------------------------
  /// Saves current timestamp to SharedPreferences.
  /// Next time checkUnseenPosts() is called, it will compare against this time.
  Future<void> markAsViewed() async {
    if (_currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // Save current timestamp
      await prefs.setInt(_lastViewedKey, now.millisecondsSinceEpoch);

      debugPrint('✅ Day Album marked as viewed at: $now');
    } catch (e) {
      debugPrint('❌ Error marking as viewed: $e');
    }
  }

  /// ---------------------------------------------------------------------------
  /// RESET SESSION - Called on logout
  /// ---------------------------------------------------------------------------
  /// Clears all stored timestamps so next login starts fresh.
  Future<void> resetSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastViewedKey);
      debugPrint('✅ Day Album session reset (logout)');
    } catch (e) {
      debugPrint('❌ Error resetting session: $e');
    }
  }

  /// ---------------------------------------------------------------------------
  /// GET LAST VIEWED TIME - For debugging/testing
  /// ---------------------------------------------------------------------------
  Future<DateTime?> getLastViewedTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt(_lastViewedKey);
      return millis != null
          ? DateTime.fromMillisecondsSinceEpoch(millis)
          : null;
    } catch (e) {
      debugPrint('❌ Error getting last viewed time: $e');
      return null;
    }
  }

  /// ---------------------------------------------------------------------------
  /// CLEAR ALL DATA - For testing only
  /// ---------------------------------------------------------------------------
  @visibleForTesting
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('🧪 All DayAlbum data cleared (test mode)');
  }
}

/// ---------------------------------------------------------------------------
/// DAY ALBUM STATUS - Result object
/// ---------------------------------------------------------------------------
/// Immutable state returned by DayAlbumTracker.
/// Controller stores this in DayFeedState.
class DayAlbumStatus {
  final bool hasUnseen;
  final int unseenCount;
  final int totalInWindow;
  final String? message;
  final String? errorMessage;

  const DayAlbumStatus({
    required this.hasUnseen,
    required this.unseenCount,
    required this.totalInWindow,
    this.message,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'DayAlbumStatus(hasUnseen: $hasUnseen, unseenCount: $unseenCount, total: $totalInWindow, message: "$message")';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayAlbumStatus &&
        other.hasUnseen == hasUnseen &&
        other.unseenCount == unseenCount &&
        other.totalInWindow == totalInWindow &&
        other.message == message;
  }

  @override
  int get hashCode {
    return Object.hash(hasUnseen, unseenCount, totalInWindow, message);
  }
}
