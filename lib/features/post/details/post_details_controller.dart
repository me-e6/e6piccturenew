import 'package:flutter/material.dart';

import '../create/post_model.dart';
import 'post_details_service.dart';

/// ============================================================================
/// POST DETAILS CONTROLLER
/// ============================================================================
/// Manages engagement state for the Post Details screen.
/// 
/// KEY IMPROVEMENTS:
/// - ✅ Immutable state (uses copyWith, never direct mutation)
/// - ✅ Optimistic UI updates with automatic rollback on errors
/// - ✅ Disposal safety to prevent "used after disposal" errors
/// - ✅ Race condition prevention with _isProcessing flag
/// - ✅ Automatic state hydration from Firestore
/// - ✅ User feedback via SnackBars
/// ============================================================================
class PostDetailsController extends ChangeNotifier {
  final PostDetailsService _service;
  
  PostModel _post;
  bool _isProcessing = false;
  bool _isDisposed = false;

  PostDetailsController(PostModel post, {PostDetailsService? service})
      : _post = post,
        _service = service ?? PostDetailsService();

  // --------------------------------------------------------------------------
  // STATE GETTERS
  // --------------------------------------------------------------------------
  
  /// Current post state (immutable - never mutate directly!)
  PostModel get post => _post;
  
  /// Whether an engagement action is in progress
  bool get isProcessing => _isProcessing;
  
  /// Check if controller is still mounted/active
  bool get mounted => !_isDisposed;

  // --------------------------------------------------------------------------
  // SAFE NOTIFY
  // --------------------------------------------------------------------------
  
  /// Safely notifies listeners only if not disposed
  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // HYDRATE - Load engagement state from Firestore
  // --------------------------------------------------------------------------
  /// Loads the current user's engagement state (liked, saved, repicced).
  /// 
  /// Call this after creating the controller to sync with Firestore.
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
      debugPrint('✅ [PostDetailsController] Hydrated: liked=${state['hasLiked']}, saved=${state['hasSaved']}, repicced=${state['hasRepicced']}');
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ [PostDetailsController] Hydration error: $e');
    }
  }

  // --------------------------------------------------------------------------
  // TOGGLE LIKE
  // --------------------------------------------------------------------------
  /// Toggles like state with optimistic update and rollback on failure.
  Future<void> toggleLike() async {
    if (_isProcessing || !mounted) return;

    _isProcessing = true;

    // Store previous state for rollback
    final previousPost = _post;
    final wasLiked = _post.hasLiked;

    // ─────────────────────────────────────────────────────────────────────────
    // OPTIMISTIC UPDATE
    // ─────────────────────────────────────────────────────────────────────────
    _post = _post.copyWith(
      hasLiked: !wasLiked,
      likeCount: wasLiked ? _post.likeCount - 1 : _post.likeCount + 1,
    );

    if (!mounted) return;
    _safeNotify();

    // ─────────────────────────────────────────────────────────────────────────
    // BACKEND CALL
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final success = await _service.toggleLike(_post.postId, wasLiked);

      if (!success && mounted) {
        // Rollback on failure
        _post = previousPost;
        _safeNotify();
        debugPrint('⚠️ [PostDetailsController] Like toggle failed, rolled back');
      }
    } catch (e) {
      // Rollback on error
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
  /// Toggles save state with optimistic update and rollback on failure.
  Future<void> toggleSave() async {
    if (_isProcessing || !mounted) return;

    _isProcessing = true;

    // Store previous state for rollback
    final previousPost = _post;
    final wasSaved = _post.hasSaved;

    // ─────────────────────────────────────────────────────────────────────────
    // OPTIMISTIC UPDATE
    // ─────────────────────────────────────────────────────────────────────────
    _post = _post.copyWith(
      hasSaved: !wasSaved,
      saveCount: wasSaved ? _post.saveCount - 1 : _post.saveCount + 1,
    );

    if (!mounted) return;
    _safeNotify();

    // ─────────────────────────────────────────────────────────────────────────
    // BACKEND CALL
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final success = await _service.toggleSave(_post.postId, wasSaved);

      if (!success && mounted) {
        // Rollback on failure
        _post = previousPost;
        _safeNotify();
        debugPrint('⚠️ [PostDetailsController] Save toggle failed, rolled back');
      }
    } catch (e) {
      // Rollback on error
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
  // TOGGLE REPIC (Twitter-Style)
  // --------------------------------------------------------------------------
  /// Toggles repic state with optimistic update, rollback, and user feedback.
  /// 
  /// Requires BuildContext for SnackBar feedback.
  Future<void> toggleRepic(BuildContext context) async {
    if (_isProcessing || !mounted) return;

    _isProcessing = true;

    // Store previous state for rollback
    final previousPost = _post;
    final wasRepicced = _post.hasRepicced;

    // ─────────────────────────────────────────────────────────────────────────
    // OPTIMISTIC UPDATE
    // ─────────────────────────────────────────────────────────────────────────
    _post = _post.copyWith(
      hasRepicced: !wasRepicced,
      repicCount: wasRepicced ? _post.repicCount - 1 : _post.repicCount + 1,
    );

    if (!mounted) return;
    _safeNotify();

    // ─────────────────────────────────────────────────────────────────────────
    // BACKEND CALL
    // ─────────────────────────────────────────────────────────────────────────
    try {
      bool success;
      
      if (wasRepicced) {
        // ───────────────────────────────────────────────────────────────────
        // UNDO REPIC
        // ───────────────────────────────────────────────────────────────────
        success = await _service.undoRepic(_post.postId);
        
        if (success && context.mounted) {
          _showSnackBar(
            context,
            message: 'Repic removed',
            isError: false,
          );
        }
      } else {
        // ───────────────────────────────────────────────────────────────────
        // CREATE REPIC
        // ───────────────────────────────────────────────────────────────────
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

      // ─────────────────────────────────────────────────────────────────────
      // HANDLE FAILURE
      // ─────────────────────────────────────────────────────────────────────
      if (!success && mounted) {
        _post = previousPost;
        _safeNotify();
        
        if (context.mounted) {
          _showSnackBar(
            context,
            message: 'Failed to ${wasRepicced ? "undo" : ""} repic. Try again.',
            isError: true,
          );
        }
      }
    } catch (e) {
      // Rollback on error
      if (!mounted) return;
      
      _post = previousPost;
      _safeNotify();
      debugPrint('❌ [PostDetailsController] Repic error: $e');
      
      if (context.mounted) {
        _showSnackBar(
          context,
          message: 'Something went wrong',
          isError: true,
        );
      }
    } finally {
      if (!mounted) return;
      
      _isProcessing = false;
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
  // REFRESH
  // --------------------------------------------------------------------------
  /// Reloads engagement state from Firestore.
  Future<void> refresh() async {
    if (!mounted) return;
    await hydrate();
  }

  // --------------------------------------------------------------------------
  // UPDATE POST
  // --------------------------------------------------------------------------
  /// Updates post data externally (e.g., from streams or parent widgets).
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
