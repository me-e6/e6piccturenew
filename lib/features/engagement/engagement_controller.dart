import 'package:flutter/material.dart';
import 'engagement_service.dart';

class EngagementController extends ChangeNotifier {
  final EngagementService _service = EngagementService();

  bool isProcessing = false;

  Future<void> reply({required String postId, required String text}) async {
    _setLoading(true);
    await _service.replyToPost(postId: postId, text: text);
    _setLoading(false);
  }

  Future<void> quoteReply({
    required String postId,
    required String text,
    required Map<String, dynamic> quotedPostSnapshot,
  }) async {
    _setLoading(true);
    await _service.quoteReply(
      postId: postId,
      text: text,
      quotedPostSnapshot: quotedPostSnapshot,
    );
    _setLoading(false);
  }

  Future<void> bookmark(String postId, {required bool isBookmarked}) async {
    _setLoading(true);
    if (isBookmarked) {
      await _service.removeBookmark(postId);
    } else {
      await _service.bookmarkPost(postId);
    }
    _setLoading(false);
  }

  Future<void> deletePost(String postId) async {
    _setLoading(true);
    await _service.deletePost(postId);
    _setLoading(false);
  }

  void _setLoading(bool value) {
    isProcessing = value;
    notifyListeners();
  }
}
