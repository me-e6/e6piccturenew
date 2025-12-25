import 'package:flutter/material.dart';
import '../../post/create/post_model.dart';

/// ============================================================================
/// QUOTES GRID
/// ============================================================================
/// Displays user's quote posts in a grid format.
///
/// Quote posts may have:
/// - Their own images (imageUrls) - rare
/// - No images but quotedPreview with thumbnailUrl - common
/// - Only commentary text - also possible
///
/// Grid shows thumbnail from either:
/// 1. post.imageUrls.first (if quote has own image)
/// 2. post.quotedPreview['thumbnailUrl'] (quoted post's image)
/// 3. Placeholder with quote icon (no images)
/// ============================================================================
class QuotesGrid extends StatelessWidget {
  final List<PostModel> posts;
  final void Function(PostModel post, int index)? onPostTap;

  const QuotesGrid({super.key, required this.posts, this.onPostTap});

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
                  Icons.format_quote_rounded,
                  size: 48,
                  color: scheme.onSurfaceVariant.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'No quotes yet',
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
          return _QuoteGridTile(
            post: post,
            onTap: () => onPostTap?.call(post, index),
          );
        }, childCount: posts.length),
      ),
    );
  }
}

/// ============================================================================
/// QUOTE GRID TILE
/// ============================================================================
/// Individual tile for a quote post.
/// Shows thumbnail with "Quote" badge overlay.
/// ============================================================================
class _QuoteGridTile extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const _QuoteGridTile({required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Determine thumbnail URL
    final thumbnailUrl = _getThumbnailUrl();

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // THUMBNAIL IMAGE OR PLACEHOLDER
          if (thumbnailUrl != null)
            Image.network(
              thumbnailUrl,
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

          // "QUOTE" BADGE (bottom-left)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'Quote',
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

          // MULTI-IMAGE INDICATOR (top-right) - if quoted post had multiple images
          if (_hasMultipleImages())
            Positioned(
              top: 4,
              right: 4,
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

  /// Get thumbnail URL from either:
  /// 1. Quote post's own images
  /// 2. Quoted post's preview thumbnail
  String? _getThumbnailUrl() {
    // First priority: Quote post's own images
    if (post.imageUrls.isNotEmpty) {
      return post.imageUrls.first;
    }

    // Second priority: Quoted post's thumbnail from preview
    final preview = post.quotedPreview;
    if (preview != null) {
      final quotedThumbnail = preview['thumbnailUrl'] as String?;
      if (quotedThumbnail != null && quotedThumbnail.isNotEmpty) {
        return quotedThumbnail;
      }
    }

    // No thumbnail available
    return null;
  }

  /// Check if there are multiple images
  bool _hasMultipleImages() {
    // Check quote's own images
    if (post.imageUrls.length > 1) return true;

    // Check quoted post's image count from preview
    final preview = post.quotedPreview;
    if (preview != null) {
      final imageCount = preview['imageCount'] as int? ?? 0;
      if (imageCount > 1) return true;
    }

    return false;
  }

  /// Placeholder when no thumbnail available
  Widget _buildPlaceholder(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.format_quote_rounded,
              size: 28,
              color: scheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 4),
            // Show commentary preview if available
            if (post.commentary != null && post.commentary!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  post.commentary!,
                  style: TextStyle(
                    fontSize: 8,
                    color: scheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
