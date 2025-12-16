import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'follow_service.dart';

enum FollowState { idle, loading }

class FollowController extends ChangeNotifier {
  FollowController({FollowService? service})
    : _service = service ?? FollowService();

  final FollowService _service;

  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  FollowState state = FollowState.idle;
  bool _isFollowing = false;

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
