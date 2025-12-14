/* import 'package:flutter/material.dart';
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
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'follow_service.dart';
import '../user/services/account_state_guard.dart';

class FollowController extends ChangeNotifier {
  final FollowService _service = FollowService();
  final AccountStateGuard _guard = AccountStateGuard();

  bool isLoading = false;
  bool isFollowingUser = false;

  String? _currentUid;

  // Public getter (safe for UI)
  String get currentUid => _currentUid ?? "";

  FollowController() {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    _currentUid = user?.uid;
    notifyListeners();
  }

  // ----------------------------------------------------
  // CHECK IF CURRENT USER FOLLOWS "targetUid"
  // (READ operation — no guard needed)
  // ----------------------------------------------------
  Future<void> checkFollowing(String targetUid) async {
    if (_currentUid == null) {
      await _loadCurrentUser();
    }

    isLoading = true;
    notifyListeners();

    isFollowingUser = await _service.isFollowing(targetUid);

    isLoading = false;
    notifyListeners();
  }

  // ----------------------------------------------------
  // FOLLOW
  // ----------------------------------------------------
  Future<String> follow(String targetUid) async {
    if (_currentUid == null) {
      await _loadCurrentUser();
    }
    if (_currentUid == null) return "not-authenticated";

    isLoading = true;
    notifyListeners();

    // STEP 2 — Account State Enforcement
    final guardResult = await _guard.checkMutationAllowed(_currentUid!);

    if (guardResult != GuardResult.allowed) {
      isLoading = false;
      notifyListeners();
      return _mapGuardResultToError(guardResult);
    }

    await _service.followUser(targetUid);
    isFollowingUser = true;

    isLoading = false;
    notifyListeners();
    return "success";
  }

  // ----------------------------------------------------
  // UNFOLLOW
  // ----------------------------------------------------
  Future<String> unfollow(String targetUid) async {
    if (_currentUid == null) {
      await _loadCurrentUser();
    }
    if (_currentUid == null) return "not-authenticated";

    isLoading = true;
    notifyListeners();

    // STEP 2 — Account State Enforcement
    final guardResult = await _guard.checkMutationAllowed(_currentUid!);

    if (guardResult != GuardResult.allowed) {
      isLoading = false;
      notifyListeners();
      return _mapGuardResultToError(guardResult);
    }

    await _service.unfollowUser(targetUid);
    isFollowingUser = false;

    isLoading = false;
    notifyListeners();
    return "success";
  }

  // ----------------------------------------------------
  // GUARD RESULT MAPPING (UI-AGNOSTIC)
  // ----------------------------------------------------
  String _mapGuardResultToError(GuardResult result) {
    switch (result) {
      case GuardResult.readOnly:
        return "account-read-only";
      case GuardResult.suspended:
        return "account-suspended";
      case GuardResult.deleted:
        return "account-deleted";
      default:
        return "action-not-allowed";
    }
  }
}
