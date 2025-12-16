import 'package:flutter/foundation.dart';
import '../post/create/post_model.dart';
import 'engagement_service.dart';

class EngagementController extends ChangeNotifier {
  final EngagementService _service;

  EngagementController({EngagementService? service})
    : _service = service ?? EngagementService();

  // ------------------------------------------------------------
  // LIKE
  // ------------------------------------------------------------
  Future<void> likePost(PostModel post) async {
    if (post.hasLiked) return;

    // Optimistic update
    post.hasLiked = true;
    post.likeCount += 1;
    notifyListeners();

    try {
      await _service.likePost(post.postId);
    } catch (_) {
      // rollback
      post.hasLiked = false;
      post.likeCount -= 1;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // DISLIKE / UNLIKE
  // ------------------------------------------------------------
  Future<void> dislikePost(PostModel post) async {
    if (!post.hasLiked) return;

    post.hasLiked = false;
    post.likeCount = post.likeCount > 0 ? post.likeCount - 1 : 0;
    notifyListeners();

    try {
      await _service.unlikePost(post.postId);
    } catch (_) {
      post.hasLiked = true;
      post.likeCount += 1;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // SAVE / UNSAVE
  // ------------------------------------------------------------
  Future<void> savePost(PostModel post) async {
    post.hasSaved = !post.hasSaved;
    notifyListeners();

    try {
      await _service.savePost(post.postId, post.hasSaved);
    } catch (_) {
      post.hasSaved = !post.hasSaved;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // SHARE (NO COUNTER MUTATION YET)
  // ------------------------------------------------------------
  Future<void> sharePost(PostModel post) async {
    try {
      await _service.sharePost(post.postId);
    } catch (_) {
      // silent fail (sharing is non-critical)
    }
  }
}
