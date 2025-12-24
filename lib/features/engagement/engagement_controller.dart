/* import 'package:flutter/material.dart';
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
    // Check if disposed before starting
    if (!mounted) return;

    try {
      final snapshot = await _service.loadEngagementState(postId);

      // Check again after async operation (user might have navigated away)
      if (!mounted) return;

      _post = _post.copyWith(
        hasLiked: snapshot.hasLiked,
        hasSaved: snapshot.hasSaved,
        hasRepicced: snapshot.hasRepicced,
      );

      notifyListeners();
    } catch (e) {
      // Only log if still mounted
      if (!mounted) return;
      print('❌ Error hydrating engagement: $e');
    }
  }
}
 */

import 'package:flutter/material.dart';
import 'engagement_service.dart';
import '../post/create/post_model.dart';

/// Manages engagement state (likes, saves, repics) for a single post
///
/// Features:
/// - Optimistic UI updates with automatic rollback on errors
/// - Disposal safety to prevent "used after disposal" errors
/// - Race condition prevention with _isProcessing flag
/// - Automatic state hydration from Firestore
class EngagementController extends ChangeNotifier {
  final String postId;
  final EngagementService _service;

  late PostModel _post;
  bool _isProcessing = false;
  bool _isDisposed = false;

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

  /// Check if controller is still mounted/active
  bool get mounted => !_isDisposed;

  // ------------------------------------------------------------
  // LIKE
  // ------------------------------------------------------------
  Future<void> toggleLike() async {
    if (_isProcessing || !mounted) return;

    _isProcessing = true;

    final prev = _post;
    final isLiked = _post.hasLiked;

    // Optimistic update
    _post = _post.copyWith(
      hasLiked: !isLiked,
      likeCount: isLiked ? _post.likeCount - 1 : _post.likeCount + 1,
    );

    if (!mounted) return;
    notifyListeners();

    try {
      if (isLiked) {
        await _service.unlikePost(postId);
      } else {
        await _service.likePost(postId);
      }

      // Success - keep optimistic update
      if (!mounted) return;
    } catch (e) {
      // Rollback on error
      if (!mounted) return;

      _post = prev;
      notifyListeners();

      print('❌ Error toggling like: $e');
    } finally {
      if (!mounted) return;

      _isProcessing = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // SAVE
  // ------------------------------------------------------------
  Future<void> toggleSave() async {
    if (_isProcessing || !mounted) return;

    _isProcessing = true;

    final prev = _post;
    final isSaved = _post.hasSaved;

    // Optimistic update
    _post = _post.copyWith(
      hasSaved: !isSaved,
      saveCount: isSaved ? _post.saveCount - 1 : _post.saveCount + 1,
    );

    if (!mounted) return;
    notifyListeners();

    try {
      if (isSaved) {
        await _service.unsavePost(postId);
      } else {
        await _service.savePost(postId);
      }

      // Success - keep optimistic update
      if (!mounted) return;
    } catch (e) {
      // Rollback on error
      if (!mounted) return;

      _post = prev;
      notifyListeners();

      print('❌ Error toggling save: $e');
    } finally {
      if (!mounted) return;

      _isProcessing = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // REPIC (Repost)
  // ------------------------------------------------------------
  Future<void> toggleRepic() async {
    if (_isProcessing || !mounted) return;

    _isProcessing = true;

    final prev = _post;
    final isRepicced = _post.hasRepicced;

    // Optimistic update
    _post = _post.copyWith(
      hasRepicced: !isRepicced,
      repicCount: isRepicced ? _post.repicCount - 1 : _post.repicCount + 1,
    );

    if (!mounted) return;
    notifyListeners();

    try {
      if (isRepicced) {
        await _service.undoRepic(postId);
      } else {
        await _service.repicPost(postId);
      }

      // Success - keep optimistic update
      if (!mounted) return;
    } catch (e) {
      // Rollback on error
      if (!mounted) return;

      _post = prev;
      notifyListeners();

      print('❌ Error toggling repic: $e');
    } finally {
      if (!mounted) return;

      _isProcessing = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // QUOTE REPLY COUNTER
  // ------------------------------------------------------------
  Future<void> incrementQuoteReply() async {
    if (!mounted) return;

    try {
      await _service.incrementQuoteReplyCount(postId);

      if (!mounted) return;

      _post = _post.copyWith(quoteReplyCount: _post.quoteReplyCount + 1);
      notifyListeners();
    } catch (e) {
      if (!mounted) return;
      print('❌ Error incrementing quote reply: $e');
    }
  }

  // ------------------------------------------------------------
  // REPLY COUNTER
  // ------------------------------------------------------------
  Future<void> incrementReply() async {
    if (!mounted) return;

    try {
      await _service.incrementReplyCount(postId);

      if (!mounted) return;

      _post = _post.copyWith(replyCount: _post.replyCount + 1);
      notifyListeners();
    } catch (e) {
      if (!mounted) return;
      print('❌ Error incrementing reply: $e');
    }
  }

  // ------------------------------------------------------------
  // HYDRATE - Load engagement state from Firestore
  // ------------------------------------------------------------
  Future<void> hydrate() async {
    if (!mounted) return;

    try {
      final snapshot = await _service.loadEngagementState(postId);

      // Check again after async operation
      if (!mounted) return;

      _post = _post.copyWith(
        hasLiked: snapshot.hasLiked,
        hasSaved: snapshot.hasSaved,
        hasRepicced: snapshot.hasRepicced,
      );

      notifyListeners();
    } catch (e) {
      if (!mounted) return;
      print('❌ Error hydrating engagement: $e');
    }
  }

  // ------------------------------------------------------------
  // UPDATE POST DATA - For external updates (like from streams)
  // ------------------------------------------------------------
  void updatePost(PostModel newPost) {
    if (!mounted) return;

    _post = newPost;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // REFRESH - Reload engagement state
  // ------------------------------------------------------------
  Future<void> refresh() async {
    if (!mounted) return;
    await hydrate();
  }

  // ------------------------------------------------------------
  // DISPOSAL
  // ------------------------------------------------------------
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
