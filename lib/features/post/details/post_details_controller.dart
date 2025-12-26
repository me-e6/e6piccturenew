import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../create/post_model.dart';
import '../create/post_delete_service.dart';
import 'post_details_service.dart';

/// ============================================================================
/// POST DETAILS CONTROLLER
/// ============================================================================
/// Manages engagement state and post deletion for the Post Details screen.
/// 
/// FEATURES:
/// - ✅ Immutable state (uses copyWith)
/// - ✅ Optimistic UI updates with rollback
/// - ✅ Post deletion (author only)
/// - ✅ Disposal safety
/// - ✅ Automatic state hydration
/// ============================================================================
class PostDetailsController extends ChangeNotifier {
  final PostDetailsService _service;
  final PostDeleteService _deleteService;
  final FirebaseAuth _auth;
  
  PostModel _post;
  bool _isProcessing = false;
  bool _isDeleting = false;
  bool _isDisposed = false;

  PostDetailsController(
    PostModel post, {
    PostDetailsService? service,
    PostDeleteService? deleteService,
    FirebaseAuth? auth,
  })  : _post = post,
        _service = service ?? PostDetailsService(),
        _deleteService = deleteService ?? PostDeleteService(),
        _auth = auth ?? FirebaseAuth.instance;

  // --------------------------------------------------------------------------
  // STATE GETTERS
  // --------------------------------------------------------------------------
  
  PostModel get post => _post;
  bool get isProcessing => _isProcessing;
  bool get isDeleting => _isDeleting;
  bool get isBusy => _isProcessing || _isDeleting;
  bool get mounted => !_isDisposed;

  /// Whether the current user is the author of this post
  bool get isAuthor {
    final uid = _auth.currentUser?.uid;
    return uid != null && uid == _post.authorId;
  }

  /// Whether the current user can delete this post
  bool get canDelete => isAuthor && !_isDeleting;

  // --------------------------------------------------------------------------
  // SAFE NOTIFY
  // --------------------------------------------------------------------------
  
  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // HYDRATE
  // --------------------------------------------------------------------------
  Future<void> hydrate() async {
    if (!mounted) return;

    try {
      debugPrint('🔄 [PostDetailsController] Hydrating engagement state...');
      
      final state = await _service.loadEngagementState(_post.postId);

      if (!mounted) return;

      _post = _post.copyWith(
        hasLiked: state['hasLiked'] ?? false,
        hasSaved: state['hasSaved'] ?? false,
        hasRepicced: state['hasRepicced'] ?? false,
      );

      _safeNotify();
      debugPrint('✅ [PostDetailsController] Hydrated');
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ [PostDetailsController] Hydration error: $e');
    }
  }

  // --------------------------------------------------------------------------
  // TOGGLE LIKE
  // --------------------------------------------------------------------------
  Future<void> toggleLike() async {
    if (_isProcessing || !mounted) return;

    _isProcessing = true;

    final previousPost = _post;
    final wasLiked = _post.hasLiked;

    // Optimistic update
    _post = _post.copyWith(
      hasLiked: !wasLiked,
      likeCount: wasLiked ? _post.likeCount - 1 : _post.likeCount + 1,
    );

    if (!mounted) return;
    _safeNotify();

    try {
      final success = await _service.toggleLike(_post.postId, wasLiked);

      if (!success && mounted) {
        _post = previousPost;
        _safeNotify();
      }
    } catch (e) {
      if (!mounted) return;
      _post = previousPost;
      _safeNotify();
      debugPrint('❌ [PostDetailsController] Like error: $e');
    } finally {
      if (!mounted) return;
      _isProcessing = false;
      _safeNotify();
    }
  }

  // --------------------------------------------------------------------------
  // TOGGLE SAVE
  // --------------------------------------------------------------------------
  Future<void> toggleSave() async {
    if (_isProcessing || !mounted) return;

    _isProcessing = true;

    final previousPost = _post;
    final wasSaved = _post.hasSaved;

    // Optimistic update
    _post = _post.copyWith(
      hasSaved: !wasSaved,
      saveCount: wasSaved ? _post.saveCount - 1 : _post.saveCount + 1,
    );

    if (!mounted) return;
    _safeNotify();

    try {
      final success = await _service.toggleSave(_post.postId, wasSaved);

      if (!success && mounted) {
        _post = previousPost;
        _safeNotify();
      }
    } catch (e) {
      if (!mounted) return;
      _post = previousPost;
      _safeNotify();
      debugPrint('❌ [PostDetailsController] Save error: $e');
    } finally {
      if (!mounted) return;
      _isProcessing = false;
      _safeNotify();
    }
  }

  // --------------------------------------------------------------------------
  // TOGGLE REPIC
  // --------------------------------------------------------------------------
  Future<void> toggleRepic(BuildContext context) async {
    if (_isProcessing || !mounted) return;

    _isProcessing = true;

    final previousPost = _post;
    final wasRepicced = _post.hasRepicced;

    // Optimistic update
    _post = _post.copyWith(
      hasRepicced: !wasRepicced,
      repicCount: wasRepicced ? _post.repicCount - 1 : _post.repicCount + 1,
    );

    if (!mounted) return;
    _safeNotify();

    try {
      bool success;
      
      if (wasRepicced) {
        success = await _service.undoRepic(_post.postId);
        
        if (success && context.mounted) {
          _showSnackBar(context, message: 'Repic removed', isError: false);
        }
      } else {
        final repicPostId = await _service.repic(_post.postId);
        success = repicPostId != null;
        
        if (success && context.mounted) {
          _showSnackBar(
            context,
            message: 'Repicced! Now on your profile.',
            isError: false,
            isPrimary: true,
          );
        }
      }

      if (!success && mounted) {
        _post = previousPost;
        _safeNotify();
        
        if (context.mounted) {
          _showSnackBar(context, message: 'Failed to repic', isError: true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      _post = previousPost;
      _safeNotify();
      debugPrint('❌ [PostDetailsController] Repic error: $e');
      
      if (context.mounted) {
        _showSnackBar(context, message: 'Something went wrong', isError: true);
      }
    } finally {
      if (!mounted) return;
      _isProcessing = false;
      _safeNotify();
    }
  }

  // --------------------------------------------------------------------------
  // DELETE POST
  // --------------------------------------------------------------------------
  /// Deletes the post if the current user is the author.
  /// 
  /// Shows confirmation dialog before deletion.
  /// Returns true if deleted, false otherwise.
  Future<bool> deletePost(BuildContext context) async {
    if (!canDelete || !mounted) return false;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text(
          'This will permanently delete this post and all its images. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    _isDeleting = true;
    _safeNotify();

    try {
      debugPrint('🗑️ [PostDetailsController] Deleting post: ${_post.postId}');

      final success = await _deleteService.deletePost(_post.postId);

      if (success) {
        debugPrint('✅ [PostDetailsController] Post deleted');
        
        if (context.mounted) {
          _showSnackBar(
            context,
            message: 'Post deleted',
            isError: false,
          );
        }
        return true;
      } else {
        if (context.mounted) {
          _showSnackBar(
            context,
            message: 'Failed to delete post',
            isError: true,
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('❌ [PostDetailsController] Delete error: $e');
      
      if (context.mounted) {
        _showSnackBar(
          context,
          message: 'Error deleting post',
          isError: true,
        );
      }
      return false;
    } finally {
      if (!mounted) return false;
      _isDeleting = false;
      _safeNotify();
    }
  }

  // --------------------------------------------------------------------------
  // SNACKBAR HELPER
  // --------------------------------------------------------------------------
  void _showSnackBar(
    BuildContext context, {
    required String message,
    required bool isError,
    bool isPrimary = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? scheme.error
            : isPrimary
                ? scheme.primary
                : null,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // REFRESH & UPDATE
  // --------------------------------------------------------------------------
  Future<void> refresh() async {
    if (!mounted) return;
    await hydrate();
  }

  void updatePost(PostModel newPost) {
    if (!mounted) return;
    _post = newPost;
    _safeNotify();
  }

  // --------------------------------------------------------------------------
  // DISPOSAL
  // --------------------------------------------------------------------------
  @override
  void dispose() {
    debugPrint('🗑️ [PostDetailsController] Disposing...');
    _isDisposed = true;
    super.dispose();
  }
}
