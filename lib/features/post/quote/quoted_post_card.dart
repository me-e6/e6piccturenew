import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'quote_model.dart';

/// ------------------------------------------------------------
/// QUOTED POST CARD - v2 (Visual Card Design)
/// ------------------------------------------------------------
/// Displays a quote post as a VISUAL CARD with image-first design.
/// 
/// ✅ NEW DESIGN:
/// - Full-bleed background image
/// - Quote commentary as overlay on top
/// - Compact original author badge (bottom-right)
/// - "Quote" indicator badge (top-right)
/// - NO text outside the image - everything is visual
/// 
/// Used in:
/// - Feed (embedded in quote posts)
/// - Post details (show quoted content)
/// - Quotes list screen
/// ------------------------------------------------------------
class QuotedPostCard extends StatelessWidget {
  final QuotedPostPreview preview;
  final String? commentary;  // ✅ NEW: Commentary to display as overlay
  final VoidCallback? onTap;
  final bool showBorder;
  final bool compact;

  const QuotedPostCard({
    super.key,
    required this.preview,
    this.commentary,
    this.onTap,
    this.showBorder = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Handle deleted original post
    if (preview.isOriginalDeleted) {
      return _buildDeletedCard(scheme);
    }

    // ✅ Use visual card design when there's a thumbnail
    if (preview.thumbnailUrl != null && preview.thumbnailUrl!.isNotEmpty) {
      return _buildVisualCard(context, theme, scheme);
    }

    // Fallback to text-based layout for posts without images
    return _buildTextOnlyCard(context, theme, scheme);
  }

  // ============================================================================
  // ✅ NEW: VISUAL CARD (Image-first design with overlay)
  // ============================================================================
  Widget _buildVisualCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    final thumbnailUrl = preview.thumbnailUrl!;
    final authorName = preview.authorName;
    final authorHandle = preview.authorHandle;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: compact ? 1.2 : 0.9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            boxShadow: compact ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ═══════════════════════════════════════════════════════════
                // BACKGROUND IMAGE (Full bleed)
                // ═══════════════════════════════════════════════════════════
                CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      size: 40,
                    ),
                  ),
                ),

                // ═══════════════════════════════════════════════════════════
                // QUOTE OVERLAY (Top) - Commentary text
                // ═══════════════════════════════════════════════════════════
                if (commentary != null && commentary!.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 10 : 14,
                        vertical: compact ? 8 : 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: compact ? 14 : 18,
                          ),
                          SizedBox(width: compact ? 4 : 6),
                          Expanded(
                            child: Text(
                              commentary!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 12 : 14,
                                fontWeight: FontWeight.w600,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ═══════════════════════════════════════════════════════════
                // ORIGINAL POSTER BADGE (Bottom-right)
                // ═══════════════════════════════════════════════════════════
                Positioned(
                  bottom: compact ? 6 : 10,
                  right: compact ? 6 : 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 6 : 8,
                      vertical: compact ? 3 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(compact ? 8 : 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_outlined,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: compact ? 10 : 12,
                        ),
                        SizedBox(width: compact ? 3 : 4),
                        Text(
                          authorHandle != null
                              ? '@$authorHandle'
                              : authorName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: compact ? 9 : 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ═══════════════════════════════════════════════════════════
                // QUOTE BADGE (Top-right) - Show only if no commentary
                // ═══════════════════════════════════════════════════════════
                if (commentary == null || commentary!.isEmpty)
                  Positioned(
                    top: compact ? 6 : 10,
                    right: compact ? 6 : 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 5 : 6,
                        vertical: compact ? 2 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(compact ? 6 : 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.repeat,
                            color: Colors.white,
                            size: compact ? 8 : 10,
                          ),
                          SizedBox(width: compact ? 2 : 3),
                          Text(
                            'Quote',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 7 : 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // TEXT-ONLY CARD (For posts without images - fallback)
  // ============================================================================
  Widget _buildTextOnlyCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 14),
        decoration: BoxDecoration(
          color: isDark
              ? scheme.surfaceContainerHighest.withOpacity(0.4)
              : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
          border: showBorder
              ? Border.all(
                  color: scheme.outlineVariant.withOpacity(isDark ? 0.3 : 0.5),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Commentary (if provided)
            if (commentary != null && commentary!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: compact ? 14 : 16,
                    color: scheme.primary,
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  Expanded(
                    child: Text(
                      commentary!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 8 : 12),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withOpacity(0.3),
              ),
              SizedBox(height: compact ? 8 : 12),
            ],

            // Author row
            _buildAuthorRow(theme, scheme),

            // Preview text (if available)
            if (preview.previewText != null && preview.previewText!.isNotEmpty) ...[
              SizedBox(height: compact ? 6 : 8),
              Text(
                preview.previewText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // AUTHOR ROW
  // ============================================================================
  Widget _buildAuthorRow(ThemeData theme, ColorScheme scheme) {
    return Row(
      children: [
        // Avatar
        if (preview.authorAvatarUrl != null)
          CircleAvatar(
            radius: compact ? 10 : 12,
            backgroundImage: CachedNetworkImageProvider(preview.authorAvatarUrl!),
            backgroundColor: scheme.surfaceContainerHighest,
          )
        else
          CircleAvatar(
            radius: compact ? 10 : 12,
            backgroundColor: scheme.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              size: compact ? 10 : 12,
              color: scheme.onSurfaceVariant,
            ),
          ),

        SizedBox(width: compact ? 6 : 8),

        // Name
        Flexible(
          child: Text(
            preview.authorName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
              fontSize: compact ? 11 : 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Verification badge
        if (preview.isVerifiedOwner) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.verified,
            size: compact ? 12 : 14,
            color: scheme.primary,
          ),
        ],

        // Handle
        if (preview.authorHandle != null) ...[
          const SizedBox(width: 4),
          Text(
            '@${preview.authorHandle}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: compact ? 10 : 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  // ============================================================================
  // DELETED CARD
  // ============================================================================
  Widget _buildDeletedCard(ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
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
            size: compact ? 14 : 18,
            color: scheme.onSurfaceVariant.withOpacity(0.5),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            'Original post unavailable',
            style: TextStyle(
              color: scheme.onSurfaceVariant.withOpacity(0.5),
              fontStyle: FontStyle.italic,
              fontSize: compact ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// QUOTE POST FEED ITEM - v2 (Visual Design)
/// ------------------------------------------------------------
/// Complete widget for displaying a quote post in the feed.
/// ✅ NOW: Uses visual card design instead of text + thumbnail
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
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // ✅ Visual quote card (image-first with commentary overlay)
            QuotedPostCard(
              preview: quotedPreview,
              commentary: commentary,
              onTap: onQuotedPostTap,
            ),

            // Engagement bar (likes, comments, etc.)
            if (engagementBar != null) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: engagementBar!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
