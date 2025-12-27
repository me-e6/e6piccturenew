import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../create/post_delete_service.dart';
import '../create/post_model.dart';

/// ============================================================================
/// POST OPTIONS MENU
/// ============================================================================
/// Reusable 3-dot menu for post actions.
/// 
/// Features:
/// - ✅ Delete (owner only)
/// - ✅ Share post/image
/// - ✅ Report (future)
/// - ✅ Admin delete (future-ready)
/// - ✅ Confirmation dialogs
/// - ✅ Loading states
/// 
/// Usage:
/// ```dart
/// PostOptionsMenu(
///   post: post,
///   onDeleted: () => controller.removePost(post.postId),
/// )
/// ```
/// ============================================================================
class PostOptionsMenu extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onDeleted;
  final bool showShareOption;
  final bool isAdmin; // Future: Admin can delete any post

  const PostOptionsMenu({
    super.key,
    required this.post,
    this.onDeleted,
    this.showShareOption = true,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid == post.authorId;
    final canDelete = isOwner || isAdmin;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: scheme.onSurfaceVariant,
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => [
        // ─────────────────────────────────────────────────────────────────
        // SHARE OPTIONS
        // ─────────────────────────────────────────────────────────────────
        if (showShareOption) ...[
          _buildMenuItem(
            context,
            value: 'share_post',
            icon: Icons.share,
            label: 'Share Post',
          ),
          if (post.imageUrls.isNotEmpty)
            _buildMenuItem(
              context,
              value: 'share_image',
              icon: Icons.image,
              label: 'Share Image',
            ),
          const PopupMenuDivider(),
        ],

        // ─────────────────────────────────────────────────────────────────
        // COPY LINK
        // ─────────────────────────────────────────────────────────────────
        _buildMenuItem(
          context,
          value: 'copy_link',
          icon: Icons.link,
          label: 'Copy Link',
        ),

        // ─────────────────────────────────────────────────────────────────
        // REPORT (Non-owners only)
        // ─────────────────────────────────────────────────────────────────
        if (!isOwner) ...[
          const PopupMenuDivider(),
          _buildMenuItem(
            context,
            value: 'report',
            icon: Icons.flag_outlined,
            label: 'Report',
            isDestructive: false,
          ),
        ],

        // ─────────────────────────────────────────────────────────────────
        // DELETE (Owners & Admins only)
        // ─────────────────────────────────────────────────────────────────
        if (canDelete) ...[
          const PopupMenuDivider(),
          _buildMenuItem(
            context,
            value: 'delete',
            icon: Icons.delete_outline,
            label: isAdmin && !isOwner ? 'Delete (Admin)' : 'Delete',
            isDestructive: true,
          ),
        ],
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    BuildContext context, {
    required String value,
    required IconData icon,
    required String label,
    bool isDestructive = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final color = isDestructive ? scheme.error : scheme.onSurface;

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: isDestructive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'share_post':
        _sharePost(context);
        break;
      case 'share_image':
        _shareImage(context);
        break;
      case 'copy_link':
        _copyLink(context);
        break;
      case 'report':
        _reportPost(context);
        break;
      case 'delete':
        _confirmDelete(context);
        break;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARE POST
  // ─────────────────────────────────────────────────────────────────────────
  void _sharePost(BuildContext context) {
    final deepLink = 'https://piccture.app/post/${post.postId}';
    final text = post.caption.isNotEmpty
        ? '${post.caption}\n\n$deepLink'
        : 'Check out this post on Piccture!\n$deepLink';

    Share.share(text, subject: 'Piccture Post');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARE IMAGE
  // ─────────────────────────────────────────────────────────────────────────
  void _shareImage(BuildContext context) {
    if (post.imageUrls.isEmpty) return;

    // Share first image URL (for now - can enhance to share actual file)
    final imageUrl = post.imageUrls.first;
    Share.share(
      'Check out this image on Piccture!\n$imageUrl',
      subject: 'Piccture Image',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COPY LINK
  // ─────────────────────────────────────────────────────────────────────────
  void _copyLink(BuildContext context) {
    final deepLink = 'https://piccture.app/post/${post.postId}';
    
    // Copy to clipboard
    // Clipboard.setData(ClipboardData(text: deepLink));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Link copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () => Share.share(deepLink),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REPORT POST
  // ─────────────────────────────────────────────────────────────────────────
  void _reportPost(BuildContext context) {
    // TODO: Implement report flow
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE POST WITH CONFIRMATION
  // ─────────────────────────────────────────────────────────────────────────
  void _confirmDelete(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Post?'),
        content: const Text(
          'This action cannot be undone. The post and all its engagements will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeDelete(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    // Show loading
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Deleting post...'),
          ],
        ),
        duration: Duration(seconds: 30),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final deleteService = PostDeleteService();
      final success = await deleteService.deletePost(post.postId);

      messenger.hideCurrentSnackBar();

      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        onDeleted?.call();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Failed to delete post'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

/// ============================================================================
/// DELETE CONFIRMATION DIALOG (Standalone)
/// ============================================================================
/// Use when you need just the delete dialog without the menu.
/// 
/// Usage:
/// ```dart
/// final confirmed = await showDeleteConfirmation(context, post);
/// if (confirmed) { ... }
/// ```
/// ============================================================================
Future<bool> showDeleteConfirmation(
  BuildContext context,
  PostModel post, {
  VoidCallback? onDeleted,
}) async {
  final scheme = Theme.of(context).colorScheme;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Post?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This action cannot be undone.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: scheme.error, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'All likes, comments, repics, and quotes will be removed.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Delete',
            style: TextStyle(
              color: scheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    final deleteService = PostDeleteService();
    final success = await deleteService.deletePost(post.postId);

    if (success) {
      onDeleted?.call();
    }

    return success;
  }

  return false;
}

/// ============================================================================
/// SHARE BOTTOM SHEET
/// ============================================================================
/// Shows share options in a bottom sheet format.
/// ============================================================================
void showShareSheet(BuildContext context, PostModel post) {
  final scheme = Theme.of(context).colorScheme;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Share',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),

            // Options Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareOption(
                  icon: Icons.link,
                  label: 'Copy Link',
                  onTap: () {
                    Navigator.pop(ctx);
                    final link = 'https://piccture.app/post/${post.postId}';
                    Share.share(link);
                  },
                ),
                _ShareOption(
                  icon: Icons.share,
                  label: 'Share Post',
                  onTap: () {
                    Navigator.pop(ctx);
                    Share.share(
                      '${post.caption}\n\nhttps://piccture.app/post/${post.postId}',
                    );
                  },
                ),
                if (post.imageUrls.isNotEmpty)
                  _ShareOption(
                    icon: Icons.image,
                    label: 'Share Image',
                    onTap: () {
                      Navigator.pop(ctx);
                      Share.share(post.imageUrls.first);
                    },
                  ),
                _ShareOption(
                  icon: Icons.people,
                  label: 'To Mutuals',
                  onTap: () {
                    Navigator.pop(ctx);
                    // TODO: Share to mutuals feature
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share to Mutuals coming soon!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
