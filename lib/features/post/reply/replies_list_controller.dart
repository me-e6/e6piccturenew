import 'package:flutter/material.dart';
import 'reply_model.dart';
import 'replies_list_service.dart';

class RepliesListController extends ChangeNotifier {
  final String postId;
  final RepliesListService _service = RepliesListService();

  RepliesListController(this.postId) {
    loadReplies();
  }

  bool isLoading = true;
  List<ReplyModel> replies = [];

  Future<void> loadReplies() async {
    isLoading = true;
    notifyListeners();

    replies = await _service.fetchReplies(postId);

    isLoading = false;
    notifyListeners();
  }
}
