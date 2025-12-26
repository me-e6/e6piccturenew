import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../create/post_model.dart';
import 'post_details_controller.dart';

import '../../engagement/engagement_lists_sheet.dart';
import '../../engagement/widgets/repic_header_widget.dart';
import '../../profile/profile_entry.dart';
import '../quote/quote_post_screen.dart';
import '../reply/reply_screen.dart';
import '../reply/replies_list_screen.dart';

/// ============================================================================
/// POST DETAILS SCREEN
/// ============================================================================
/// Full-screen view of a single post with all engagement actions.
/// 
/// FEATURES:
/// - ✅ Theme-aware design
/// - ✅ All engagement actions: Like, Reply, Quote, Repic, Save
/// - ✅ DELETE button for post author
/// - ✅ Repic post support
/// - ✅ Engagement lists
/// - ✅ Image carousel
/// ============================================================================
class PostDetailsScreen extends StatelessWidget {
  final PostModel post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PostDetailsController(post)..hydrate(),
      child: const _PostDetailsView(),
    );
  }
}

// ============================================================================
// POST DETAILS VIEW
// ============================================================================

class _PostDetailsView extends StatelessWidget {
  const _PostDetailsView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PostDetailsController>();
    final post = controller.post;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar with image
          _PostAppBar(post: post, controller: controller),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Repic header
                if (post.isRepic && post.repicAuthorId != null)
                  RepicHeader(
                    repicAuthorId: post.repicAuthorId!,
                    repicAuthorName: post.repicAuthorName ?? 'User',
                    repicAuthorHandle: post.repicAuthorHandle,
                    repicAuthorAvatarUrl: post.repicAuthorAvatarUrl,
                    repicAuthorIsVerified: post.repicAuthorIsVerified,
                  ),

                // Author info
                _AuthorSection(post: post),

                const Divider(height: 1),

                // Caption
                _CaptionSection(post: post),

                // Engagement stats
                _EngagementStats(post: post),

                const Divider(height: 1),

                // Engagement actions
                const _EngagementActions(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// APP BAR WITH IMAGE + DELETE
// ============================================================================

class _PostAppBar extends StatelessWidget {
  final PostModel post;
  final PostDetailsController controller;

  const _PostAppBar({required this.post, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    final imageUrls = post.isRepic && post.originalImageUrls.isNotEmpty
        ? post.originalImageUrls
        : post.imageUrls;

    final hasImage = imageUrls.isNotEmpty;

    return SliverAppBar(
      expandedHeight: hasImage ? 420 : 100,
      pinned: true,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      
      // Back button
      leading: _CircleButton(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.pop(context),
      ),
      
      // More options (includes delete for author)
      actions: [
        _CircleButton(
          icon: Icons.more_vert,
          onPressed: () => _showMoreOptions(context),
        ),
        const SizedBox(width: 8),
      ],
      
      // Image
      flexibleSpace: hasImage
          ? FlexibleSpaceBar(
              background: _PostImageCarousel(imageUrls: imageUrls),
            )
          : null,
    );
  }

  void _showMoreOptions(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            
            // Share
            ListTile(
              leading: Icon(Icons.share_outlined, color: scheme.onSurface),
              title: Text('Share', style: TextStyle(color: scheme.onSurface)),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: Implement share
              },
            ),
            
            // Copy link
            ListTile(
              leading: Icon(Icons.link, color: scheme.onSurface),
              title: Text('Copy link', style: TextStyle(color: scheme.onSurface)),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: Implement copy link
              },
            ),

            // ─────────────────────────────────────────────────────────────────
            // DELETE (Author only)
            // ─────────────────────────────────────────────────────────────────
            if (controller.isAuthor) ...[
              const Divider(),
              ListTile(
                leading: controller.isDeleting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.error,
                        ),
                      )
                    : Icon(Icons.delete_outline, color: scheme.error),
                title: Text(
                  controller.isDeleting ? 'Deleting...' : 'Delete Post',
                  style: TextStyle(color: scheme.error),
                ),
                onTap: controller.isDeleting
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final deleted = await controller.deletePost(context);
                        if (deleted && context.mounted) {
                          Navigator.pop(context, 'deleted');
                        }
                      },
              ),
            ],
            
            // Report (non-author only)
            if (!controller.isAuthor)
              ListTile(
                leading: Icon(Icons.flag_outlined, color: scheme.error),
                title: Text('Report', style: TextStyle(color: scheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: Implement report
                },
              ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Circle button for app bar
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: scheme.surface.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: scheme.onSurface, size: 20),
      ),
    );
  }
}

// ============================================================================
// IMAGE CAROUSEL
// ============================================================================

class _PostImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const _PostImageCarousel({required this.imageUrls});

  @override
  State<_PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends State<_PostImageCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Images
        PageView.builder(
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: widget.imageUrls[index],
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image, size: 48),
              ),
            );
          },
        ),

        // Page indicators
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (index) {
                final isActive = index == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 8 : 6,
                  height: isActive ? 8 : 6,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white54,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),

        // Counter badge
        if (widget.imageUrls.length > 1)
          Positioned(
            top: 100,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// AUTHOR SECTION
// ============================================================================

class _AuthorSection extends StatelessWidget {
  final PostModel post;

  const _AuthorSection({required this.post});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileEntry(userId: post.authorId)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.surfaceContainerHighest,
              backgroundImage: post.authorAvatarUrl != null
                  ? CachedNetworkImageProvider(post.authorAvatarUrl!)
                  : null,
              child: post.authorAvatarUrl == null
                  ? Icon(Icons.person, color: scheme.onSurfaceVariant)
                  : null,
            ),

            const SizedBox(width: 12),

            // Name and handle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          post.authorName.isNotEmpty ? post.authorName : 'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (post.authorIsVerified) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified, size: 18, color: scheme.primary),
                      ],
                    ],
                  ),
                  if (post.authorHandle != null)
                    Text(
                      '@${post.authorHandle}',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

            // Timestamp
            Text(
              _formatTimestamp(post.createdAt),
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

// ============================================================================
// CAPTION SECTION
// ============================================================================

class _CaptionSection extends StatelessWidget {
  final PostModel post;

  const _CaptionSection({required this.post});

  @override
  Widget build(BuildContext context) {
    final caption = post.isRepic ? post.originalCaption : post.caption;
    if (caption.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        caption,
        style: TextStyle(
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.5,
        ),
      ),
    );
  }
}

// ============================================================================
// ENGAGEMENT STATS
// ============================================================================

class _EngagementStats extends StatelessWidget {
  final PostModel post;

  const _EngagementStats({required this.post});

  @override
  Widget build(BuildContext context) {
    final hasStats = post.likeCount > 0 ||
        post.replyCount > 0 ||
        post.quoteReplyCount > 0 ||
        post.repicCount > 0;

    if (!hasStats) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        children: [
          if (post.likeCount > 0)
            _StatItem(count: post.likeCount, label: 'Likes', onTap: () {}),
          if (post.replyCount > 0)
            _StatItem(
              count: post.replyCount,
              label: 'Replies',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RepliesListScreen(post: post)),
              ),
            ),
          if (post.quoteReplyCount > 0)
            _StatItem(
              count: post.quoteReplyCount,
              label: 'Quotes',
              onTap: () => EngagementListsSheet.show(
                context,
                postId: post.postId,
                repicCount: post.repicCount,
                quoteCount: post.quoteReplyCount,
                likeCount: post.likeCount,
              ),
            ),
          if (post.repicCount > 0)
            _StatItem(
              count: post.repicCount,
              label: 'Repics',
              onTap: () => EngagementListsSheet.show(
                context,
                postId: post.postId,
                repicCount: post.repicCount,
                quoteCount: post.quoteReplyCount,
                likeCount: post.likeCount,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;

  const _StatItem({required this.count, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: _formatCount(count),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: scheme.onSurface,
                ),
              ),
              TextSpan(
                text: ' $label',
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
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

// ============================================================================
// ENGAGEMENT ACTIONS
// ============================================================================

class _EngagementActions extends StatelessWidget {
  const _EngagementActions();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PostDetailsController>();
    final post = controller.post;
    final scheme = Theme.of(context).colorScheme;
    final iconColor = scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Like
          _ActionButton(
            icon: post.hasLiked ? Icons.favorite : Icons.favorite_border,
            label: 'Like',
            color: post.hasLiked ? Colors.red : iconColor,
            onTap: controller.isBusy ? null : controller.toggleLike,
          ),

          // Reply
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Reply',
            color: iconColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReplyScreen(postId: post.postId)),
            ).then((_) {
              if (context.mounted) controller.refresh();
            }),
          ),

          // Quote
          _ActionButton(
            icon: Icons.format_quote_rounded,
            label: 'Quote',
            color: iconColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QuotePostScreen(postId: post.postId)),
            ).then((result) {
              if (result != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Quote posted!'),
                    backgroundColor: scheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                controller.refresh();
              }
            }),
          ),

          // Repic
          _ActionButton(
            icon: post.hasRepicced ? Icons.repeat_on : Icons.repeat,
            label: 'Repic',
            color: post.hasRepicced ? Colors.green : iconColor,
            onTap: controller.isBusy ? null : () => controller.toggleRepic(context),
          ),

          // Save
          _ActionButton(
            icon: post.hasSaved ? Icons.bookmark : Icons.bookmark_border,
            label: 'Save',
            color: post.hasSaved ? Colors.amber : iconColor,
            onTap: controller.isBusy ? null : controller.toggleSave,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
