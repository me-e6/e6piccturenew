import 'package:flutter/material.dart';
import '../create/post_model.dart';
import 'post_details_service.dart';

class PostDetailsController extends ChangeNotifier {
  final PostModel post;
  final PostDetailsService _service = PostDetailsService();

  PostDetailsController(this.post);

  bool isProcessing = false;

  Future<void> toggleLike() async {
    if (isProcessing) return;
    isProcessing = true;
    notifyListeners();

    await _service.toggleLike(post.postId, post.hasLiked);
    post.hasLiked = !post.hasLiked;
    post.likeCount += post.hasLiked ? 1 : -1;

    isProcessing = false;
    notifyListeners();
  }

  Future<void> toggleSave() async {
    if (isProcessing) return;
    isProcessing = true;
    notifyListeners();

    await _service.toggleSave(post.postId, post.hasSaved);
    post.hasSaved = !post.hasSaved;

    isProcessing = false;
    notifyListeners();
  }

  Future<void> repost(BuildContext context) async {
    if (isProcessing) return;
    isProcessing = true;
    notifyListeners();

    await _service.repost(
      post.postId,
      post.imageUrl,
      post.uid,
      post.originalOwnerName ?? "",
    );

    isProcessing = false;
    notifyListeners();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Re-pic created.")));
  }
}
