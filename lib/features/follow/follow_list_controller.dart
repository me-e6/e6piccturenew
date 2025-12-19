import 'package:flutter/material.dart';
import 'follow_list_service.dart';
import '.././profile/user_model.dart';

enum FollowListType { followers, following }

class FollowListController extends ChangeNotifier {
  FollowListController({
    required this.userId,
    required this.type,
    FollowListService? service,
  }) : _service = service ?? FollowListService();

  final String userId;
  final FollowListType type;
  final FollowListService _service;

  bool isLoading = true;
  List<UserModel> users = [];
  String? error;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      users = type == FollowListType.followers
          ? await _service.getFollowers(userId)
          : await _service.getFollowing(userId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
