import 'package:flutter/material.dart';

import 'search_service.dart';
import '../profile/user_model.dart';
import '../post/create/post_model.dart';

enum SearchFilter { all, followers, following, mutual }

class AppSearchController extends ChangeNotifier {
  final SearchService _service = SearchService();

  bool isLoading = false;

  List<UserModel> _allUserResults = [];
  List<UserModel> userResults = [];
  List<PostModel> postResults = [];

  SearchFilter activeFilter = SearchFilter.all;

  // ---------------- SEARCH ----------------
  Future<void> search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _allUserResults = [];
      userResults = [];
      postResults = [];
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      _allUserResults = await _service.searchUsers(trimmed);
      postResults = await _service.searchPostsByUserName(trimmed);

      _applyFilter();
    } catch (e) {
      // Intentionally silent; UI reacts via empty state
      _allUserResults = [];
      userResults = [];
      postResults = [];
    }

    isLoading = false;
    notifyListeners();
  }

  // ---------------- FILTER ----------------
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

      // Relationship-based filters are deferred
      // They will be implemented later using FollowController / MutualController
      case SearchFilter.followers:
      case SearchFilter.following:
      case SearchFilter.mutual:
        userResults = List<UserModel>.from(_allUserResults);
        break;
    }
  }
}
