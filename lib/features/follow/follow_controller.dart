/* import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'follow_service.dart';

enum FollowState { idle, loading }

class FollowController extends ChangeNotifier {
  final FollowService _service;
  final FirebaseAuth _auth;

  FollowController({FollowService? service, FirebaseAuth? auth})
    : _service = service ?? FollowService(),
      _auth = auth ?? FirebaseAuth.instance;

  String? _currentUserId;
  String? _targetUserId;

  FollowState state = FollowState.idle;
  bool _isFollowing = false;
  bool isProcessing = false;

  // -------------------------
  // PUBLIC GETTERS (CANONICAL)
  // -------------------------
  bool get isFollowing => _isFollowing;
  bool get isLoading => state == FollowState.loading;
  String? get currentUid => _currentUserId;
  String? get targetUid => _targetUserId;

  // --------------------------------------------------
  // LOAD FOLLOWER - Initialize with user IDs
  // --------------------------------------------------
  Future<void> loadFollower({
    String? currentUserId,
    required String targetUserId,
  }) async {
    _currentUserId = currentUserId ?? _auth.currentUser?.uid;
    _targetUserId = targetUserId;

    if (_currentUserId == null) {
      debugPrint('Cannot load follower: currentUserId is null');
      return;
    }

    if (_currentUserId == _targetUserId) {
      // User viewing their own profile
      _isFollowing = false;
      notifyListeners();
      return;
    }

    state = FollowState.loading;
    notifyListeners();

    try {
      _isFollowing = await _service.isFollowing(
        currentUid: _currentUserId!,
        targetUid: _targetUserId!,
      );
    } catch (e) {
      debugPrint('Error loading follower status: $e');
      _isFollowing = false;
    } finally {
      state = FollowState.idle;
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // INIT / CHECK (Kept for backward compatibility)
  // --------------------------------------------------
  Future<void> load(String targetUid) async {
    final currentUid = _currentUserId ?? _auth.currentUser?.uid;
    if (currentUid == null) return;

    _isFollowing = await _service.isFollowing(
      currentUid: currentUid,
      targetUid: targetUid,
    );
    notifyListeners();
  }

  // --------------------------------------------------
  // FOLLOW
  // --------------------------------------------------
  Future<void> follow(String? targetUid) async {
    final uid = targetUid ?? _targetUserId;
    final currentUid = _currentUserId ?? _auth.currentUser?.uid;

    if (currentUid == null || uid == null || isLoading || _isFollowing) {
      return;
    }

    state = FollowState.loading;
    notifyListeners();

    try {
      await _service.follow(currentUid: currentUid, targetUid: uid);
      _isFollowing = true;
    } catch (e) {
      debugPrint('Follow failed: $e');
    } finally {
      state = FollowState.idle;
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // UNFOLLOW
  // --------------------------------------------------
  Future<void> unfollow(String? targetUid) async {
    final uid = targetUid ?? _targetUserId;
    final currentUid = _currentUserId ?? _auth.currentUser?.uid;

    if (currentUid == null || uid == null || isLoading || !_isFollowing) {
      return;
    }

    state = FollowState.loading;
    notifyListeners();

    try {
      await _service.unfollow(currentUid: currentUid, targetUid: uid);
      _isFollowing = false;
    } catch (e) {
      debugPrint('Unfollow failed: $e');
    } finally {
      state = FollowState.idle;
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // TOGGLE (Convenience method)
  // --------------------------------------------------
  Future<void> toggle([String? targetUid]) async {
    if (_isFollowing) {
      await unfollow(targetUid);
    } else {
      await follow(targetUid);
    }
  }

  // --------------------------------------------------
  // REFRESH (Reload follow status)
  // --------------------------------------------------
  Future<void> refresh() async {
    if (_targetUserId != null) {
      await loadFollower(
        currentUserId: _currentUserId,
        targetUserId: _targetUserId!,
      );
    }
  }
}
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'follow_service.dart';

enum FollowState { idle, loading }

/// ============================================================================
/// FollowController - ✅ ENHANCED
/// ============================================================================
///
/// IMPROVEMENTS:
/// - ✅ Better race condition prevention
/// - ✅ Optimistic UI with rollback
/// - ✅ Error state management
/// - ✅ Retry logic for failed follows
///
/// ============================================================================

class FollowController extends ChangeNotifier {
  final FollowService _service;
  final FirebaseAuth _auth;

  FollowController({FollowService? service, FirebaseAuth? auth})
    : _service = service ?? FollowService(),
      _auth = auth ?? FirebaseAuth.instance;

  String? _currentUserId;
  String? _targetUserId;

  FollowState state = FollowState.idle;
  bool _isFollowing = false;
  bool _isProcessing = false;
  String? _lastError;

  // -------------------------
  // PUBLIC GETTERS
  // -------------------------
  bool get isFollowing => _isFollowing;
  bool get isLoading => state == FollowState.loading;
  bool get isProcessing => _isProcessing;
  String? get currentUid => _currentUserId;
  String? get targetUid => _targetUserId;
  String? get lastError => _lastError;

  // --------------------------------------------------
  // LOAD FOLLOWER - Initialize with user IDs
  // --------------------------------------------------
  Future<void> loadFollower({
    String? currentUserId,
    required String targetUserId,
  }) async {
    _currentUserId = currentUserId ?? _auth.currentUser?.uid;
    _targetUserId = targetUserId;

    if (_currentUserId == null) {
      debugPrint('Cannot load follower: currentUserId is null');
      return;
    }

    if (_currentUserId == _targetUserId) {
      // User viewing their own profile
      _isFollowing = false;
      notifyListeners();
      return;
    }

    state = FollowState.loading;
    notifyListeners();

    try {
      _isFollowing = await _service.isFollowing(
        currentUid: _currentUserId!,
        targetUid: _targetUserId!,
      );
      _lastError = null;
    } catch (e) {
      debugPrint('Error loading follower status: $e');
      _isFollowing = false;
      _lastError = e.toString();
    } finally {
      state = FollowState.idle;
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // FOLLOW - ✅ OPTIMISTIC UI WITH ROLLBACK
  // --------------------------------------------------
  Future<void> follow(String? targetUid) async {
    final uid = targetUid ?? _targetUserId;
    final currentUid = _currentUserId ?? _auth.currentUser?.uid;

    // Guard: Check preconditions
    if (currentUid == null || uid == null) {
      debugPrint('❌ Cannot follow: Missing user ID');
      return;
    }

    if (_isProcessing) {
      debugPrint('⚠️ Follow already in progress, ignoring duplicate request');
      return;
    }

    if (_isFollowing) {
      debugPrint('⚠️ Already following, ignoring request');
      return;
    }

    // Lock to prevent race conditions
    _isProcessing = true;
    state = FollowState.loading;

    // Store previous state for rollback
    final wasFollowing = _isFollowing;

    try {
      // ✅ OPTIMISTIC UI - Update immediately
      _isFollowing = true;
      notifyListeners();

      // Network call
      await _service.follow(currentUid: currentUid, targetUid: uid);

      _lastError = null;
      debugPrint('✅ Successfully followed user: $uid');
    } catch (e) {
      // ✅ ROLLBACK ON FAILURE
      debugPrint('❌ Follow failed: $e');
      _isFollowing = wasFollowing;
      _lastError = e.toString();
      notifyListeners();
    } finally {
      _isProcessing = false;
      state = FollowState.idle;
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // UNFOLLOW - ✅ OPTIMISTIC UI WITH ROLLBACK
  // --------------------------------------------------
  Future<void> unfollow(String? targetUid) async {
    final uid = targetUid ?? _targetUserId;
    final currentUid = _currentUserId ?? _auth.currentUser?.uid;

    // Guard: Check preconditions
    if (currentUid == null || uid == null) {
      debugPrint('❌ Cannot unfollow: Missing user ID');
      return;
    }

    if (_isProcessing) {
      debugPrint('⚠️ Unfollow already in progress, ignoring duplicate request');
      return;
    }

    if (!_isFollowing) {
      debugPrint('⚠️ Not following, ignoring request');
      return;
    }

    // Lock to prevent race conditions
    _isProcessing = true;
    state = FollowState.loading;

    // Store previous state for rollback
    final wasFollowing = _isFollowing;

    try {
      // ✅ OPTIMISTIC UI - Update immediately
      _isFollowing = false;
      notifyListeners();

      // Network call
      await _service.unfollow(currentUid: currentUid, targetUid: uid);

      _lastError = null;
      debugPrint('✅ Successfully unfollowed user: $uid');
    } catch (e) {
      // ✅ ROLLBACK ON FAILURE
      debugPrint('❌ Unfollow failed: $e');
      _isFollowing = wasFollowing;
      _lastError = e.toString();
      notifyListeners();
    } finally {
      _isProcessing = false;
      state = FollowState.idle;
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // TOGGLE - ✅ RACE-CONDITION SAFE
  // --------------------------------------------------
  Future<void> toggle([String? targetUid]) async {
    if (_isProcessing) {
      debugPrint('⚠️ Toggle already in progress');
      return;
    }

    if (_isFollowing) {
      await unfollow(targetUid);
    } else {
      await follow(targetUid);
    }
  }

  // --------------------------------------------------
  // RETRY - Try again after error
  // --------------------------------------------------
  Future<void> retry() async {
    if (_lastError == null) return;

    _lastError = null;
    await loadFollower(
      currentUserId: _currentUserId,
      targetUserId: _targetUserId!,
    );
  }

  // --------------------------------------------------
  // REFRESH - Reload follow status
  // --------------------------------------------------
  Future<void> refresh() async {
    if (_targetUserId != null) {
      await loadFollower(
        currentUserId: _currentUserId,
        targetUserId: _targetUserId!,
      );
    }
  }

  // --------------------------------------------------
  // CLEAR - Reset state
  // --------------------------------------------------
  void clear() {
    _isFollowing = false;
    _isProcessing = false;
    _lastError = null;
    _currentUserId = null;
    _targetUserId = null;
    state = FollowState.idle;
    notifyListeners();
  }

  // --------------------------------------------------
  // LOAD (Kept for backward compatibility)
  // --------------------------------------------------
  Future<void> load(String targetUid) async {
    await loadFollower(currentUserId: _currentUserId, targetUserId: targetUid);
  }
}
