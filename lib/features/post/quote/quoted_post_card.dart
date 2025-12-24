import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'quote_model.dart';

/// ------------------------------------------------------------
/// QUOTED POST CARD
/// ------------------------------------------------------------
/// Displays a preview of the quoted/original post.
/// Used in:
/// - Quote creation screen (preview what's being quoted)
/// - Feed (embedded in quote posts)
/// - Post details (show quoted content)
/// 
/// Features:
/// - Thumbnail image preview
/// - Author info with verification badge
/// - Preview text (50 char limit)
/// - Tap to navigate to original
/// - Dark mode support
/// - Deleted post handling
/// ------------------------------------------------------------
class QuotedPostCard extends StatelessWidget {
  final QuotedPostPreview preview;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool compact;

  const QuotedPostCard({
    super.key,
    required this.preview,
    this.onTap,
    this.showBorder = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Handle deleted original post
    if (preview.isOriginalDeleted) {
      return _buildDeletedCard(scheme);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? scheme.surfaceContainerHighest.withOpacity(0.4)
              : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: showBorder
              ? Border.all(
                  color: scheme.outlineVariant.withOpacity(isDark ? 0.3 : 0.5),
                  width: 1,
                )
              : null,
        ),
        child: compact ? _buildCompactLayout(theme, scheme) : _buildFullLayout(theme, scheme),
      ),
    );
  }

  // ------------------------------------------------------------
  // FULL LAYOUT (Default)
  // ------------------------------------------------------------
  Widget _buildFullLayout(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // THUMBNAIL (if available)
          if (preview.thumbnailUrl != null) ...[
            _buildThumbnail(scheme),
            const SizedBox(width: 12),
          ],

          // CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // AUTHOR ROW
                _buildAuthorRow(theme, scheme),

                const SizedBox(height: 6),

                // PREVIEW TEXT OR IMAGE INDICATOR
                if (preview.previewText != null && preview.previewText!.isNotEmpty)
                  Text(
                    preview.previewText!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (preview.thumbnailUrl != null)
                  Row(
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 14,
                        color: scheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Photo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // NAVIGATION ARROW (if tappable)
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: scheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // COMPACT LAYOUT (For feed items)
  // ------------------------------------------------------------
  Widget _buildCompactLayout(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          // SMALL THUMBNAIL
          if (preview.thumbnailUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: preview.thumbnailUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: scheme.surfaceContainerHighest,
                ),
                errorWidget: (_, __, ___) => Container(
                  color: scheme.surfaceContainerHighest,
                  child: Icon(Icons.broken_image, size: 16, color: scheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // AUTHOR
                _buildCompactAuthorRow(theme, scheme),

                if (preview.previewText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    preview.previewText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // AUTHOR ROW
  // ------------------------------------------------------------
  Widget _buildAuthorRow(ThemeData theme, ColorScheme scheme) {
    return Row(
      children: [
        // AVATAR
        if (preview.authorAvatarUrl != null)
          CircleAvatar(
            radius: 12,
            backgroundImage: CachedNetworkImageProvider(preview.authorAvatarUrl!),
            backgroundColor: scheme.surfaceContainerHighest,
          )
        else
          CircleAvatar(
            radius: 12,
            backgroundColor: scheme.surfaceContainerHighest,
            child: Icon(Icons.person, size: 14, color: scheme.onSurfaceVariant),
          ),

        const SizedBox(width: 8),

        // NAME
        Flexible(
          child: Text(
            preview.authorName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // VERIFICATION BADGE
        if (preview.isVerifiedOwner) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.verified,
            size: 14,
            color: scheme.primary,
          ),
        ],

        // HANDLE
        if (preview.authorHandle != null) ...[
          const SizedBox(width: 4),
          Text(
            '@${preview.authorHandle}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildCompactAuthorRow(ThemeData theme, ColorScheme scheme) {
    return Row(
      children: [
        Flexible(
          child: Text(
            preview.authorName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (preview.isVerifiedOwner) ...[
          const SizedBox(width: 3),
          Icon(Icons.verified, size: 12, color: scheme.primary),
        ],
        if (preview.authorHandle != null) ...[
          const SizedBox(width: 4),
          Text(
            '@${preview.authorHandle}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------
  // THUMBNAIL
  // ------------------------------------------------------------
  Widget _buildThumbnail(ColorScheme scheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: preview.thumbnailUrl!,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 64,
          height: 64,
          color: scheme.surfaceContainerHighest,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 64,
          height: 64,
          color: scheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image_outlined,
            color: scheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DELETED POST CARD
  // ------------------------------------------------------------
  Widget _buildDeletedCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link_off,
            size: 18,
            color: scheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Text(
            'Original post unavailable',
            style: TextStyle(
              color: scheme.onSurfaceVariant.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// QUOTE POST FEED ITEM
/// ------------------------------------------------------------
/// Complete widget for displaying a quote post in the feed.
/// Combines the quote author's commentary with the quoted preview.
/// ------------------------------------------------------------
class QuotePostFeedItem extends StatelessWidget {
  final String quoteAuthorName;
  final String? quoteAuthorHandle;
  final String? quoteAuthorAvatarUrl;
  final bool isQuoteAuthorVerified;
  final String? commentary;
  final QuotedPostPreview quotedPreview;
  final DateTime createdAt;
  final VoidCallback? onTap;
  final VoidCallback? onQuotedPostTap;
  final Widget? engagementBar;

  const QuotePostFeedItem({
    super.key,
    required this.quoteAuthorName,
    this.quoteAuthorHandle,
    this.quoteAuthorAvatarUrl,
    this.isQuoteAuthorVerified = false,
    this.commentary,
    required this.quotedPreview,
    required this.createdAt,
    this.onTap,
    this.onQuotedPostTap,
    this.engagementBar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QUOTE AUTHOR HEADER
            _buildQuoteAuthorHeader(theme, scheme),

            // COMMENTARY (if exists)
            if (commentary != null && commentary!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                commentary!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // QUOTED POST PREVIEW
            QuotedPostCard(
              preview: quotedPreview,
              onTap: onQuotedPostTap,
              compact: true,
            ),

            // ENGAGEMENT BAR (likes, comments, etc.)
            if (engagementBar != null) ...[
              const SizedBox(height: 12),
              engagementBar!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteAuthorHeader(ThemeData theme, ColorScheme scheme) {
    return Row(
      children: [
        // AVATAR
        if (quoteAuthorAvatarUrl != null)
          CircleAvatar(
            radius: 18,
            backgroundImage: CachedNetworkImageProvider(quoteAuthorAvatarUrl!),
            backgroundColor: scheme.surfaceContainerHighest,
          )
        else
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.surfaceContainerHighest,
            child: Icon(Icons.person, size: 18, color: scheme.onSurfaceVariant),
          ),

        const SizedBox(width: 10),

        // NAME & HANDLE
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      quoteAuthorName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isQuoteAuthorVerified) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.verified, size: 16, color: scheme.primary),
                  ],
                ],
              ),
              if (quoteAuthorHandle != null)
                Text(
                  '@$quoteAuthorHandle',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),

        // TIMESTAMP
        Text(
          _formatTimestamp(createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),

        // QUOTE INDICATOR
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.format_quote, size: 12, color: scheme.primary),
              const SizedBox(width: 2),
              Text(
                'Quote',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}';
  }
}
