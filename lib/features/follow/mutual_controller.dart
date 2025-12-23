/* import 'package:flutter/material.dart';
import 'mutual_service.dart';

enum MutualLoadState { idle, loading, success, empty, error }

class MutualController extends ChangeNotifier {
  MutualController({MutualService? service})
    : _service = service ?? MutualService();

  final MutualService _service;

  MutualLoadState state = MutualLoadState.idle;
  List<String> mutualUids = [];
  String? error;

  bool _isLoading = false;

  Future<void> loadMutuals(String uid) async {
    if (_isLoading) return;

    _isLoading = true;
    state = MutualLoadState.loading;
    notifyListeners();

    try {
      final result = await _service.getMutualUids(uid);
      mutualUids = result;

      state = mutualUids.isEmpty
          ? MutualLoadState.empty
          : MutualLoadState.success;
    } catch (e, st) {
      error = e.toString();
      debugPrint('MutualController.loadMutuals failed: $e');
      debugPrint('$st');
      state = MutualLoadState.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int get count => mutualUids.length;
}
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mutual_service.dart';

enum MutualLoadState { idle, loading, success, empty, error }

class MutualController extends ChangeNotifier {
  final MutualService _service;
  final FirebaseAuth _auth;

  MutualController({MutualService? service, FirebaseAuth? auth})
    : _service = service ?? MutualService(),
      _auth = auth ?? FirebaseAuth.instance;

  MutualLoadState state = MutualLoadState.idle;
  List<String> mutualUids = [];
  String? error;
  String? _currentUserId;
  String? _targetUserId;

  bool _isLoading = false;

  // -------------------------
  // PUBLIC GETTERS
  // -------------------------
  bool get isLoading => _isLoading;
  int get count => mutualUids.length;
  bool get hasMutuals => mutualUids.isNotEmpty;
  String? get currentUserId => _currentUserId;
  String? get targetUserId => _targetUserId;

  // --------------------------------------------------
  // LOAD MUTUAL - Initialize with user IDs
  // --------------------------------------------------
  Future<void> loadMutual({
    String? currentUserId,
    required String targetUserId,
  }) async {
    _currentUserId = currentUserId ?? _auth.currentUser?.uid;
    _targetUserId = targetUserId;

    if (_currentUserId == null) {
      debugPrint('Cannot load mutuals: currentUserId is null');
      error = 'User not authenticated';
      state = MutualLoadState.error;
      notifyListeners();
      return;
    }

    if (_currentUserId == _targetUserId) {
      // User viewing their own profile - no mutuals with self
      mutualUids = [];
      state = MutualLoadState.empty;
      notifyListeners();
      return;
    }

    await _loadMutuals(_currentUserId!, _targetUserId!);
  }

  // --------------------------------------------------
  // LOAD MUTUALS (Internal method)
  // --------------------------------------------------
  Future<void> _loadMutuals(String currentUid, String targetUid) async {
    if (_isLoading) return;

    _isLoading = true;
    state = MutualLoadState.loading;
    error = null;
    notifyListeners();

    try {
      final result = await _service.getMutualUids(targetUid);
      mutualUids = result;

      state = mutualUids.isEmpty
          ? MutualLoadState.empty
          : MutualLoadState.success;
    } catch (e, st) {
      error = e.toString();
      debugPrint('MutualController._loadMutuals failed: $e');
      debugPrint('$st');
      state = MutualLoadState.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // LOAD MUTUALS (Public method - kept for backward compatibility)
  // --------------------------------------------------
  Future<void> loadMutuals(String uid) async {
    _targetUserId = uid;
    await _loadMutuals(_currentUserId ?? _auth.currentUser!.uid, uid);
  }

  // --------------------------------------------------
  // CHECK IF SPECIFIC USER IS MUTUAL
  // --------------------------------------------------
  bool isMutual(String uid) {
    return mutualUids.contains(uid);
  }

  // --------------------------------------------------
  // REFRESH (Reload mutuals)
  // --------------------------------------------------
  Future<void> refresh() async {
    if (_currentUserId != null && _targetUserId != null) {
      await _loadMutuals(_currentUserId!, _targetUserId!);
    }
  }

  // --------------------------------------------------
  // CLEAR (Reset state)
  // --------------------------------------------------
  void clear() {
    mutualUids = [];
    error = null;
    state = MutualLoadState.idle;
    _currentUserId = null;
    _targetUserId = null;
    notifyListeners();
  }
}
