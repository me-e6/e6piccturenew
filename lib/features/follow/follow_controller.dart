/* import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'follow_service.dart';

enum FollowState { idle, loading }

class FollowController extends ChangeNotifier {
  final FollowService _service;

  FollowController({FollowService? service})
    : _service = service ?? FollowService();

  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  FollowState state = FollowState.idle;
  bool _isFollowing = false;
  bool isProcessing = false;

  // -------------------------
  // PUBLIC GETTERS (CANONICAL)
  // -------------------------
  bool get isFollowing => _isFollowing;
  bool get isLoading => state == FollowState.loading;

  // --------------------------------------------------
  // INIT / CHECK
  // --------------------------------------------------
  Future<void> load(String targetUid) async {
    _isFollowing = await _service.isFollowing(
      currentUid: currentUid,
      targetUid: targetUid,
    );
    notifyListeners();
  }

  // --------------------------------------------------
  // FOLLOW
  // --------------------------------------------------
  Future<void> follow(String targetUid) async {
    if (isLoading || _isFollowing) return;

    state = FollowState.loading;
    notifyListeners();

    try {
      await _service.follow(currentUid: currentUid, targetUid: targetUid);
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
  Future<void> unfollow(String targetUid) async {
    if (isLoading || !_isFollowing) return;

    state = FollowState.loading;
    notifyListeners();

    try {
      await _service.unfollow(currentUid: currentUid, targetUid: targetUid);
      _isFollowing = false;
    } catch (e) {
      debugPrint('Unfollow failed: $e');
    } finally {
      state = FollowState.idle;
      notifyListeners();
    }
  }
}
 */
import 'package:flutter/material.dart';
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
