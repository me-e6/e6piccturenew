import 'package:flutter/material.dart';
import 'engagement_service.dart';
import '../post/create/post_model.dart';

class EngagementController extends ChangeNotifier {
  final String postId;
  final EngagementService _service;

  late PostModel _post;
  bool _isProcessing = false;

  EngagementController({
    required this.postId,
    EngagementService? service,
    required PostModel initialPost,
  }) : _service = service ?? EngagementService() {
    _post = initialPost;
  }

  // ------------------------------------------------------------
  // STATE GETTERS
  // ------------------------------------------------------------
  PostModel get post => _post;
  bool get isProcessing => _isProcessing;

  // ------------------------------------------------------------
  // LIKE
  // ------------------------------------------------------------
  Future<void> toggleLike() async {
    if (_isProcessing) return;

    _isProcessing = true;

    final prev = _post;
    final isLiked = _post.hasLiked;

    _post = _post.copyWith(
      hasLiked: !isLiked,
      likeCount: isLiked ? _post.likeCount - 1 : _post.likeCount + 1,
    );
    notifyListeners();

    try {
      if (isLiked) {
        await _service.unlikePost(postId);
      } else {
        await _service.likePost(postId);
      }
    } catch (_) {
      _post = prev;
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // SAVE
  // ------------------------------------------------------------
  Future<void> toggleSave() async {
    if (_isProcessing) return;

    _isProcessing = true;

    final prev = _post;
    final isSaved = _post.hasSaved;

    _post = _post.copyWith(
      hasSaved: !isSaved,
      saveCount: isSaved ? _post.saveCount - 1 : _post.saveCount + 1,
    );
    notifyListeners();

    try {
      if (isSaved) {
        await _service.unsavePost(postId);
      } else {
        await _service.savePost(postId);
      }
    } catch (_) {
      _post = prev;
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // REPIC
  // ------------------------------------------------------------
  Future<void> toggleRepic() async {
    if (_isProcessing) return;

    _isProcessing = true;

    final prev = _post;
    final isRepicced = _post.hasRepicced;

    _post = _post.copyWith(
      hasRepicced: !isRepicced,
      repicCount: isRepicced ? _post.repicCount - 1 : _post.repicCount + 1,
    );
    notifyListeners();

    try {
      if (isRepicced) {
        await _service.undoRepic(postId);
      } else {
        await _service.repicPost(postId);
      }
    } catch (_) {
      _post = prev;
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // QUOTE REPLY COUNTER
  // ------------------------------------------------------------
  Future<void> incrementQuoteReply() async {
    try {
      await _service.incrementQuoteReplyCount(postId);
      _post = _post.copyWith(quoteReplyCount: _post.quoteReplyCount + 1);
      notifyListeners();
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // REPLY COUNTER
  // ------------------------------------------------------------
  Future<void> incrementReply() async {
    try {
      await _service.incrementReplyCount(postId);
      _post = _post.copyWith(replyCount: _post.replyCount + 1);
      notifyListeners();
    } catch (_) {}
  }

  // ----------------------- Engagement_Controller.dart ------------------
  Future<void> hydrate() async {
    final snapshot = await _service.loadEngagementState(postId);

    _post = _post.copyWith(
      hasLiked: snapshot.hasLiked,
      hasSaved: snapshot.hasSaved,
      hasRepicced: snapshot.hasRepicced,
    );

    notifyListeners();
  }
}
