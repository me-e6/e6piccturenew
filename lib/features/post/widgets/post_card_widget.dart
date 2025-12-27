import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import './../create/post_model.dart';
import '../../post/widgets/post_options_menu.dart';
import '../../common/widgets/badges_widgets.dart';

/// ============================================================================
/// POST CARD WIDGET - v2 (Enhanced)
/// ============================================================================
/// Complete post card with:
/// - ✅ Author header with all badges (Verified, Gazetteer, Mutual)
/// - ✅ Repic header ("User repicced")
/// - ✅ Multi-image support
/// - ✅ Quote post rendering
/// - ✅ Engagement bar
/// - ✅ Options menu (delete, share, report)
/// - ✅ Share to mutuals
/// ============================================================================
class PostCard extends StatelessWidget {
  final PostModel post;
  final bool isMutual;
  final bool isGazetteer;
  final VoidCallback? onTap;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onReplyTap;
  final VoidCallback? onRepicTap;
  final VoidCallback? onQuoteTap;
  final VoidCallback? onSaveTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onDeleted;
  final bool isProcessing;

  const PostCard({
    super.key,
    required this.post,
    this.isMutual = false,
    this.isGazetteer = false,
    this.onTap,
    this.onAuthorTap,
    this.onLikeTap,
    this.onReplyTap,
    this.onRepicTap,
    this.onQuoteTap,
    this.onSaveTap,
    this.onShareTap,
    this.onDeleted,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: scheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // REPIC HEADER (if applicable)
          // ═══════════════════════════════════════════════════════════════════
          if (post.isRepic && post.repicAuthorName != null)
            _RepicHeader(
              repicAuthorName: post.repicAuthorName!,
              repicAuthorHandle: post.repicAuthorHandle,
            ),

          // ═══════════════════════════════════════════════════════════════════
          // AUTHOR HEADER
          // ═══════════════════════════════════════════════════════════════════
          _AuthorHeader(
            post: post,
            isMutual: isMutual,
            isGazetteer: isGazetteer,
            onTap: onAuthorTap,
            onDeleted: onDeleted,
          ),

          // ═══════════════════════════════════════════════════════════════════
          // CONTENT (Image or Quote)
          // ═══════════════════════════════════════════════════════════════════
          GestureDetector(
            onTap: onTap,
            child: post.isQuote && post.imageUrls.isEmpty
                ? _QuoteContent(post: post)
                : _ImageContent(post: post),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // CAPTION
          // ═══════════════════════════════════════════════════════════════════
          if (post.caption.isNotEmpty && !post.isQuote)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                post.caption,
                style: TextStyle(fontSize: 14, color: scheme.onSurface),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // ═══════════════════════════════════════════════════════════════════
          // ENGAGEMENT BAR
          // ═══════════════════════════════════════════════════════════════════
          _EngagementBar(
            post: post,
            isProcessing: isProcessing,
            onLikeTap: onLikeTap,
            onReplyTap: onReplyTap,
            onRepicTap: onRepicTap,
            onQuoteTap: onQuoteTap,
            onSaveTap: onSaveTap,
            onShareTap: onShareTap,
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// REPIC HEADER
/// ============================================================================
class _RepicHeader extends StatelessWidget {
  final String repicAuthorName;
  final String? repicAuthorHandle;

  const _RepicHeader({required this.repicAuthorName, this.repicAuthorHandle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat, size: 14, color: Colors.green.shade700),
          const SizedBox(width: 6),
          Text(
            '$repicAuthorName repicced',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// AUTHOR HEADER
/// ============================================================================
class _AuthorHeader extends StatelessWidget {
  final PostModel post;
  final bool isMutual;
  final bool isGazetteer;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;

  const _AuthorHeader({
    required this.post,
    this.isMutual = false,
    this.isGazetteer = false,
    this.onTap,
    this.onDeleted,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 6),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: onTap,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: scheme.surfaceContainerHighest,
              backgroundImage: post.authorAvatarUrl != null
                  ? CachedNetworkImageProvider(post.authorAvatarUrl!)
                  : null,
              child: post.authorAvatarUrl == null
                  ? Icon(Icons.person, size: 18, color: scheme.onSurfaceVariant)
                  : null,
            ),
          ),

          const SizedBox(width: 10),

          // Name + Handle + Badges
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row with badges
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (post.authorIsVerified) ...[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 14),
                      ],
                      if (isGazetteer) ...[
                        const SizedBox(width: 4),
                        const GazetteerBadge.iconOnly(iconSize: 14),
                      ],
                    ],
                  ),

                  // Handle + Mutual + Time
                  Row(
                    children: [
                      if (post.authorHandle != null)
                        Text(
                          '@${post.authorHandle}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      if (isMutual) const MutualBadge.inline(),
                      Text(
                        ' · ${_formatTime(post.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Options menu
          PostOptionsMenu(post: post, onDeleted: onDeleted),
        ],
      ),
    );
  }
}

/// ============================================================================
/// IMAGE CONTENT
/// ============================================================================
class _ImageContent extends StatelessWidget {
  final PostModel post;

  const _ImageContent({required this.post});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Get images (handle repic posts)
    final images = post.isRepic && post.originalImageUrls.isNotEmpty
        ? post.originalImageUrls
        : post.imageUrls;

    if (images.isEmpty) {
      return const SizedBox(height: 200);
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main image
          CachedNetworkImage(
            imageUrl: images.first,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: scheme.surfaceContainerHighest,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: scheme.surfaceContainerHighest,
              child: Icon(Icons.broken_image, color: scheme.onSurfaceVariant),
            ),
          ),

          // Multi-image indicator
          if (images.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.collections,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '1/${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// QUOTE CONTENT
/// ============================================================================
class _QuoteContent extends StatelessWidget {
  final PostModel post;

  const _QuoteContent({required this.post});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = post.quotedPreview;
    final thumbnailUrl = post.quotedThumbnailUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commentary
          if (post.commentary != null && post.commentary!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                post.commentary!,
                style: TextStyle(fontSize: 15, color: scheme.onSurface),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Quoted post preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                // Thumbnail
                if (thumbnailUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),

                if (thumbnailUrl != null) const SizedBox(width: 12),

                // Quote info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: 16,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              preview?['authorName'] ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: scheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (preview?['caption'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          preview!['caption'],
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// ENGAGEMENT BAR
/// ============================================================================
class _EngagementBar extends StatelessWidget {
  final PostModel post;
  final bool isProcessing;
  final VoidCallback? onLikeTap;
  final VoidCallback? onReplyTap;
  final VoidCallback? onRepicTap;
  final VoidCallback? onQuoteTap;
  final VoidCallback? onSaveTap;
  final VoidCallback? onShareTap;

  const _EngagementBar({
    required this.post,
    this.isProcessing = false,
    this.onLikeTap,
    this.onReplyTap,
    this.onRepicTap,
    this.onQuoteTap,
    this.onSaveTap,
    this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LIKE
          _EngagementButton(
            icon: post.hasLiked ? Icons.favorite : Icons.favorite_border,
            color: post.hasLiked ? Colors.red : iconColor,
            count: post.likeCount,
            onTap: isProcessing ? null : onLikeTap,
          ),

          // REPLY
          _EngagementButton(
            icon: Icons.chat_bubble_outline,
            color: iconColor,
            count: post.replyCount,
            onTap: onReplyTap,
          ),

          // REPIC + QUOTE
          _RepicQuoteButton(
            repicCount: post.repicCount,
            quoteCount: post.quoteReplyCount,
            hasRepicced: post.hasRepicced,
            iconColor: iconColor,
            onRepicTap: isProcessing ? null : onRepicTap,
            onQuoteTap: onQuoteTap,
          ),

          // SAVE
          _EngagementButton(
            icon: post.hasSaved ? Icons.bookmark : Icons.bookmark_border,
            color: post.hasSaved ? Colors.amber : iconColor,
            count: post.saveCount,
            onTap: isProcessing ? null : onSaveTap,
          ),

          // SHARE
          _EngagementButton(
            icon: Icons.share_outlined,
            color: iconColor,
            count: 0,
            onTap: onShareTap,
            showCount: false,
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// ENGAGEMENT BUTTON
/// ============================================================================
class _EngagementButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback? onTap;
  final bool showCount;

  const _EngagementButton({
    required this.icon,
    required this.color,
    required this.count,
    this.onTap,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            if (showCount && count > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(count),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

/// ============================================================================
/// REPIC + QUOTE COMBINED BUTTON
/// ============================================================================
class _RepicQuoteButton extends StatelessWidget {
  final int repicCount;
  final int quoteCount;
  final bool hasRepicced;
  final Color iconColor;
  final VoidCallback? onRepicTap;
  final VoidCallback? onQuoteTap;

  const _RepicQuoteButton({
    required this.repicCount,
    required this.quoteCount,
    required this.hasRepicced,
    required this.iconColor,
    this.onRepicTap,
    this.onQuoteTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = repicCount + quoteCount;
    final color = hasRepicced ? Colors.green : iconColor;

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'repic') onRepicTap?.call();
        if (value == 'quote') onQuoteTap?.call();
      },
      offset: const Offset(0, -80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.repeat, size: 20, color: color),
            if (totalCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(totalCount),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'repic',
          child: Row(
            children: [
              Icon(
                Icons.repeat,
                size: 20,
                color: hasRepicced ? Colors.green : null,
              ),
              const SizedBox(width: 12),
              Text(hasRepicced ? 'Undo Repic' : 'Repic'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'quote',
          child: Row(
            children: [
              Icon(Icons.format_quote, size: 20),
              SizedBox(width: 12),
              Text('Quote'),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
