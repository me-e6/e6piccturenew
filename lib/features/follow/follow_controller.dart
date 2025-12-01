import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'follow_service.dart';

class FollowController extends ChangeNotifier {
  final FollowService _service = FollowService();

  bool isLoading = false;
  bool isFollowingUser = false;

  String? _currentUid;

  // Public getter (useful in UI)
  String get currentUid => _currentUid ?? "";

  FollowController() {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    _currentUid = user?.uid;
    notifyListeners(); // Important so UI knows UID is ready
  }

  // ----------------------------------------------------
  // CHECK IF CURRENT USER FOLLOWS "targetUid"
  // ----------------------------------------------------
  Future<void> checkFollowing(String targetUid) async {
    if (_currentUid == null) {
      await _loadCurrentUser();
    }

    isLoading = true;
    notifyListeners();

    final status = await _service.isFollowing(targetUid);
    isFollowingUser = status;

    isLoading = false;
    notifyListeners();
  }

  // ----------------------------------------------------
  // FOLLOW
  // ----------------------------------------------------
  Future<void> follow(String targetUid) async {
    if (_currentUid == null) {
      await _loadCurrentUser();
    }
    if (_currentUid == null) return;

    isLoading = true;
    notifyListeners();

    await _service.followUser(targetUid);
    isFollowingUser = true;

    isLoading = false;
    notifyListeners();
  }

  // ----------------------------------------------------
  // UNFOLLOW
  // ----------------------------------------------------
  Future<void> unfollow(String targetUid) async {
    if (_currentUid == null) {
      await _loadCurrentUser();
    }
    if (_currentUid == null) return;

    isLoading = true;
    notifyListeners();

    await _service.unfollowUser(targetUid);
    isFollowingUser = false;

    isLoading = false;
    notifyListeners();
  }
}
