import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../post/create/post_model.dart';
import '../../post/create/post_delete_service.dart';
import '../../post/widgets/post_options_menu.dart';

/// ============================================================================
/// PICTURES GRID - v2 (Enhanced with Multi-Select)
/// ============================================================================
/// Instagram-style grid for profile tabs.
/// 
/// Features:
/// - ✅ Grid view (3 columns)
/// - ✅ Long-press to enter selection mode
/// - ✅ Multi-select with checkmarks
/// - ✅ Bulk delete
/// - ✅ Bulk archive (future)
/// - ✅ Bulk hide/private (future)
/// - ✅ Single tap options menu
/// - ✅ Share functionality
/// ============================================================================
class PicturesGrid extends StatefulWidget {
  final List<PostModel> posts;
  final void Function(PostModel post, int index)? onPostTap;
  final VoidCallback? onRefresh;
  final bool isOwner;
  final String? emptyMessage;

  const PicturesGrid({
    super.key,
    required this.posts,
    this.onPostTap,
    this.onRefresh,
    this.isOwner = false,
    this.emptyMessage,
  });

  @override
  State<PicturesGrid> createState() => _PicturesGridState();
}

class _PicturesGridState extends State<PicturesGrid> {
  // Selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedPostIds = {};

  // ─────────────────────────────────────────────────────────────────────────
  // SELECTION MODE CONTROLS
  // ─────────────────────────────────────────────────────────────────────────
  void _enterSelectionMode(String postId) {
    if (!widget.isOwner) return;
    
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedPostIds.add(postId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedPostIds.clear();
    });
  }

  void _toggleSelection(String postId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedPostIds.contains(postId)) {
        _selectedPostIds.remove(postId);
        if (_selectedPostIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedPostIds.add(postId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPostIds.addAll(widget.posts.map((p) => p.postId));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedPostIds.clear();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BULK ACTIONS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _bulkDelete() async {
    if (_selectedPostIds.isEmpty) return;

    final count = _selectedPostIds.length;
    final confirmed = await _showBulkDeleteConfirmation(count);

    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);

    // Show progress
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text('Deleting $count posts...'),
          ],
        ),
        duration: const Duration(seconds: 60),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final deleteService = PostDeleteService();
      final deleted = await deleteService.batchDelete(_selectedPostIds.toList());

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Deleted $deleted of $count posts'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: deleted == count ? Colors.green : Colors.orange,
        ),
      );

      _exitSelectionMode();
      widget.onRefresh?.call();
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool?> _showBulkDeleteConfirmation(int count) {
    final scheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete $count Posts?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This action cannot be undone.'),
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
                  Expanded(
                    child: Text(
                      'All engagements on these posts will be permanently deleted.',
                      style: TextStyle(fontSize: 12, color: scheme.onErrorContainer),
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
            child: Text('Cancel', style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete All',
              style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _bulkArchive() {
    // TODO: Implement archive
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Archive feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _bulkMakePrivate() {
    // TODO: Implement make private
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy settings coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (widget.posts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: scheme.onSurfaceVariant.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                widget.emptyMessage ?? 'No posts yet',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        // ─────────────────────────────────────────────────────────────────
        // SELECTION MODE HEADER
        // ─────────────────────────────────────────────────────────────────
        if (_isSelectionMode)
          SliverToBoxAdapter(
            child: _SelectionHeader(
              selectedCount: _selectedPostIds.length,
              totalCount: widget.posts.length,
              onSelectAll: _selectAll,
              onDeselectAll: _deselectAll,
              onCancel: _exitSelectionMode,
              onDelete: _bulkDelete,
              onArchive: _bulkArchive,
              onMakePrivate: _bulkMakePrivate,
            ),
          ),

        // ─────────────────────────────────────────────────────────────────
        // GRID
        // ─────────────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(2),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = widget.posts[index];
                final isSelected = _selectedPostIds.contains(post.postId);

                return _GridItem(
                  post: post,
                  index: index,
                  isSelectionMode: _isSelectionMode,
                  isSelected: isSelected,
                  isOwner: widget.isOwner,
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(post.postId);
                    } else {
                      widget.onPostTap?.call(post, index);
                    }
                  },
                  onLongPress: () => _enterSelectionMode(post.postId),
                  onDeleted: widget.onRefresh,
                );
              },
              childCount: widget.posts.length,
            ),
          ),
        ),
      ],
    );
  }
}

/// ============================================================================
/// SELECTION HEADER
/// ============================================================================
class _SelectionHeader extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onArchive;
  final VoidCallback onMakePrivate;

  const _SelectionHeader({
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onCancel,
    required this.onDelete,
    required this.onArchive,
    required this.onMakePrivate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allSelected = selectedCount == totalCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
          ),

          // Selected count
          Text(
            '$selectedCount selected',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: scheme.onPrimaryContainer,
            ),
          ),

          const Spacer(),

          // Select All / Deselect All
          TextButton(
            onPressed: allSelected ? onDeselectAll : onSelectAll,
            child: Text(allSelected ? 'Deselect All' : 'Select All'),
          ),

          const SizedBox(width: 8),

          // Action buttons
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: scheme.onPrimaryContainer),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            enabled: selectedCount > 0,
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  onDelete();
                  break;
                case 'archive':
                  onArchive();
                  break;
                case 'private':
                  onMakePrivate();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: scheme.error, size: 20),
                    const SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: scheme.error)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Archive'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'private',
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Make Private'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// GRID ITEM
/// ============================================================================
class _GridItem extends StatelessWidget {
  final PostModel post;
  final int index;
  final bool isSelectionMode;
  final bool isSelected;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onDeleted;

  const _GridItem({
    required this.post,
    required this.index,
    required this.isSelectionMode,
    required this.isSelected,
    required this.isOwner,
    required this.onTap,
    required this.onLongPress,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    final hasMultipleImages = post.imageUrls.length > 1;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          if (imageUrl != null)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              cacheWidth: 300,
              errorBuilder: (_, __, ___) => Container(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  color: scheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            )
          else
            Container(
              color: scheme.surfaceContainerHighest,
              child: Icon(
                post.isQuote ? Icons.format_quote : Icons.image_not_supported,
                color: scheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),

          // Multi-image indicator
          if (hasMultipleImages)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.collections,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),

          // Quote indicator
          if (post.isQuote)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.format_quote,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),

          // Selection overlay
          if (isSelectionMode)
            Container(
              color: isSelected
                  ? scheme.primary.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
            ),

          // Selection checkbox
          if (isSelectionMode)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? scheme.primary : Colors.white.withOpacity(0.8),
                  border: Border.all(
                    color: isSelected ? scheme.primary : scheme.outline,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),

          // Options menu (when NOT in selection mode, for owner)
          if (!isSelectionMode && isOwner)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PostOptionsMenu(
                  post: post,
                  onDeleted: onDeleted,
                  showShareOption: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
