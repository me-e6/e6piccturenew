import 'package:flutter/material.dart';
import '../create/post_model.dart';
import 'immersive_post_service.dart';

class ImmersivePostController extends ChangeNotifier {
  final PostModel post;
  final ImmersivePostService _service = ImmersivePostService();

  int currentIndex = 0;
  bool isProcessingLike = false;

  ImmersivePostController(this.post);

  int get totalImages => post.resolvedImages.length;

  void onPageChanged(int index) {
    currentIndex = index;
    notifyListeners();
  }

  // --------------------------------------------------
  // OPTIMISTIC LIKE TOGGLE
  // --------------------------------------------------
  Future<void> toggleLike() async {
    if (isProcessingLike) return;
    isProcessingLike = true;

    // 1️⃣ Optimistic UI update
    final previousLiked = post.hasLiked;
    post.hasLiked = !previousLiked;
    post.likeCount += post.hasLiked ? 1 : -1;
    notifyListeners();

    try {
      // 2️⃣ Firestore update
      await _service.toggleLike(post.postId, previousLiked);
    } catch (_) {
      // 3️⃣ Rollback if failure
      post.hasLiked = previousLiked;
      post.likeCount += post.hasLiked ? 1 : -1;
      notifyListeners();
    }

    isProcessingLike = false;
  }
}
