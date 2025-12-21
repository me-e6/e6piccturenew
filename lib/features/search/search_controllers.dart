import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../profile/user_model.dart';
import '../user/services/user_service.dart';
import '../follow/mutual_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchControllers extends ChangeNotifier {
  final UserService _userService;
  final MutualService _mutualService;
  final FirebaseAuth _auth;

  SearchControllers({
    UserService? userService,
    MutualService? mutualService,
    FirebaseAuth? auth,
  }) : _userService = userService ?? UserService(),
       _mutualService = mutualService ?? MutualService(),
       _auth = auth ?? FirebaseAuth.instance;

  List<UserModel> results = [];
  bool isLoading = false;

  Timer? _debounce;

  // ------------------------------------------------------------
  // QUERY HANDLER
  // ------------------------------------------------------------
  void onQueryChanged(String query) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final q = query.trim();
      if (q.isEmpty) {
        results = [];
        notifyListeners();
        return;
      }

      isLoading = true;
      notifyListeners();

      final users = await _userService.searchUsers(q);
      final currentUid = _auth.currentUser?.uid;

      final enriched = await Future.wait(
        users.map((u) async {
          if (currentUid == null || u.uid == currentUid) return u;

          final isMutual = await _mutualService.isMutual(
            currentUid: currentUid,
            targetUid: u.uid,
          );

          return u.copyWith(hasMutual: isMutual);
        }),
      );

      enriched.sort((a, b) => _rank(b, q).compareTo(_rank(a, q)));

      results = enriched;
      isLoading = false;
      notifyListeners();
    });
  }

  // ------------------------------------------------------------
  // RANKING LOGIC
  // ------------------------------------------------------------
  int _rank(UserModel u, String query) {
    int score = 0;
    final q = query.toLowerCase();

    final handle = u.handle.toLowerCase();
    final name = u.displayName.toLowerCase();

    if (handle.startsWith(q)) score += 100;
    if (name.startsWith(q)) score += 80;
    if (handle.contains(q) || name.contains(q)) score += 30;

    if (u.isVerified) score += 40;
    if (u.hasMutual == true) score += 25;

    score += log((u.followersCount + 1).toDouble()).toInt() * 10;

    return score;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
