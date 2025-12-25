import 'package:flutter/material.dart';
import '../../post/create/post_model.dart';

/// ============================================================================
/// REPICS GRID
/// ============================================================================
/// Displays posts that user has repicced in a grid format.
/// Each tile shows "Repic" badge overlay with repeat icon.
/// ============================================================================
class RepicsGrid extends StatelessWidget {
  final List<PostModel> posts;
  final void Function(PostModel post, int index)? onPostTap;

  const RepicsGrid({super.key, required this.posts, this.onPostTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                  Icons.repeat_rounded,
                  size: 48,
                  color: scheme.onSurfaceVariant.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'No repics yet',
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
          return _RepicGridTile(
            post: post,
            onTap: () => onPostTap?.call(post, index),
          );
        }, childCount: posts.length),
      ),
    );
  }
}

/// ============================================================================
/// REPIC GRID TILE
/// ============================================================================
class _RepicGridTile extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const _RepicGridTile({required this.post, this.onTap});

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

          // "REPIC" BADGE (top-right)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.repeat, size: 10, color: Colors.white),
                  SizedBox(width: 3),
                  Text(
                    'Repic',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
          Icons.repeat_rounded,
          size: 28,
          color: scheme.onSurfaceVariant.withOpacity(0.4),
        ),
      ),
    );
  }
}
