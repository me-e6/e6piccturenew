import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'search_service.dart';
import '../profile/user_model.dart';
import '../post/create/post_model.dart';

enum SearchFilter { all, followers, following, mutual }

class AppSearchController extends ChangeNotifier {
  final SearchService _service = SearchService();

  bool isLoading = false;

  List<UserModel> _allUserResults = [];
  List<PostModel> postResults = [];

  List<UserModel> userResults = [];

  SearchFilter activeFilter = SearchFilter.all;

  bool _currentUserLoaded = false;
  List<String> _followersIds = [];
  List<String> _followingIds = [];

  // ---------------- LOAD CURRENT USER RELATIONS ----------------
  Future<void> _ensureCurrentUserLoaded() async {
    if (_currentUserLoaded) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userModel = await _service.getUserById(user.uid);

    if (userModel != null) {
      _followersIds = userModel.followersList;
      _followingIds = userModel.followingList;
    }

    _currentUserLoaded = true;
  }

  // ---------------- SEARCH ----------------
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _allUserResults = [];
      userResults = [];
      postResults = [];
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    await _ensureCurrentUserLoaded();

    _allUserResults = await _service.searchUsers(query);
    postResults = await _service.searchPostsByUserName(query);

    _applyFilter();

    isLoading = false;
    notifyListeners();
  }

  // ---------------- APPLY FILTER ----------------
  void setFilter(SearchFilter filter) {
    activeFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    switch (activeFilter) {
      case SearchFilter.all:
        userResults = List<UserModel>.from(_allUserResults);
        break;

      case SearchFilter.followers:
        userResults = _allUserResults
            .where((u) => _followersIds.contains(u.uid))
            .toList();
        break;

      case SearchFilter.following:
        userResults = _allUserResults
            .where((u) => _followingIds.contains(u.uid))
            .toList();
        break;

      case SearchFilter.mutual:
        userResults = _allUserResults.where((u) {
          return _followersIds.contains(u.uid) && _followingIds.contains(u.uid);
        }).toList();
        break;
    }
  }
}
