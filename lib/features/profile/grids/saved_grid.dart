import 'package:flutter/material.dart';
import '../../post/create/post_model.dart';

/// ============================================================================
/// SAVED GRID
/// ============================================================================
/// Displays posts that user has saved/bookmarked in a grid format.
/// Each tile shows bookmark icon overlay.
///
/// NOTE: This tab is only visible to the profile owner.
/// ============================================================================
class SavedGrid extends StatelessWidget {
  final List<PostModel> posts;
  final void Function(PostModel post, int index)? onPostTap;
  final bool isOwner;

  const SavedGrid({
    super.key,
    required this.posts,
    this.onPostTap,
    this.isOwner = true, // Default true for backward compatibility
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Not owner - show private message
    if (!isOwner) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: scheme.onSurfaceVariant.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Saved posts are private',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Empty state
    if (posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border_rounded,
                  size: 48,
                  color: scheme.onSurfaceVariant.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'No saved posts yet',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the bookmark icon on posts to save them',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(2),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final post = posts[index];
          return _SavedGridTile(
            post: post,
            onTap: () => onPostTap?.call(post, index),
          );
        }, childCount: posts.length),
      ),
    );
  }
}

/// ============================================================================
/// SAVED GRID TILE
/// ============================================================================
class _SavedGridTile extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const _SavedGridTile({required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = post.imageUrls.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // THUMBNAIL IMAGE OR PLACEHOLDER
          if (hasImage)
            Image.network(
              post.imageUrls.first,
              fit: BoxFit.cover,
              cacheWidth: 300,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: scheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _buildPlaceholder(scheme),
            )
          else
            _buildPlaceholder(scheme),

          // BOOKMARK ICON (top-right)
          const Positioned(
            top: 4,
            right: 4,
            child: Icon(
              Icons.bookmark,
              color: Colors.white,
              size: 18,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),

          // MULTI-IMAGE INDICATOR (top-left)
          if (post.imageUrls.length > 1)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.collections,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Placeholder when no image available
  Widget _buildPlaceholder(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.bookmark_outline,
          size: 28,
          color: scheme.onSurfaceVariant.withOpacity(0.4),
        ),
      ),
    );
  }
}
