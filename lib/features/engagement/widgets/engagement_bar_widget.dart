import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engagement_controller.dart';
import '../../post/create/post_model.dart';

/// ============================================================================
/// ENGAGEMENT BAR WIDGET - FIXED
/// ============================================================================
/// A self-contained engagement bar that:
/// - ✅ Creates its own EngagementController
/// - ✅ Handles disposal properly
/// - ✅ Shows like, reply, repic, save, share buttons
/// - ✅ Optimistic UI updates
/// ============================================================================
class EngagementBar extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onReplyTap;
  final VoidCallback? onQuoteTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onRepicQuoteMenuTap;

  const EngagementBar({
    super.key,
    required this.post,
    this.onReplyTap,
    this.onQuoteTap,
    this.onShareTap,
    this.onRepicQuoteMenuTap,
  });

  @override
  State<EngagementBar> createState() => _EngagementBarState();
}

class _EngagementBarState extends State<EngagementBar> {
  late EngagementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EngagementController(
      postId: widget.post.postId,
      initialPost: widget.post,
    );
    _controller.hydrate();
  }

  @override
  void didUpdateWidget(EngagementBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If post changed, update controller
    if (oldWidget.post.postId != widget.post.postId) {
      _controller.dispose();
      _controller = EngagementController(
        postId: widget.post.postId,
        initialPost: widget.post,
      );
      _controller.hydrate();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<EngagementController>(
        builder: (context, controller, _) {
          final post = controller.post;
          final scheme = Theme.of(context).colorScheme;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Like
                _EngagementButton(
                  icon: post.hasLiked ? Icons.favorite : Icons.favorite_border,
                  color: post.hasLiked ? Colors.red : scheme.onSurfaceVariant,
                  count: post.likeCount,
                  onTap: controller.toggleLike,
                ),

                // Reply
                _EngagementButton(
                  icon: Icons.chat_bubble_outline,
                  color: scheme.onSurfaceVariant,
                  count: post.replyCount,
                  onTap: widget.onReplyTap,
                ),

                // Repic + Quote
                _EngagementButton(
                  icon: Icons.repeat,
                  color: post.hasRepicced
                      ? Colors.green
                      : scheme.onSurfaceVariant,
                  count: post.repicCount + post.quoteReplyCount,
                  onTap:
                      widget.onRepicQuoteMenuTap ??
                      () => _showRepicQuoteMenu(context, controller),
                ),

                // Save
                _EngagementButton(
                  icon: post.hasSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: post.hasSaved ? Colors.amber : scheme.onSurfaceVariant,
                  count: post.saveCount,
                  onTap: controller.toggleSave,
                ),

                // Share
                _EngagementButton(
                  icon: Icons.share_outlined,
                  color: scheme.onSurfaceVariant,
                  count: null,
                  onTap: widget.onShareTap,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRepicQuoteMenu(
    BuildContext context,
    EngagementController controller,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final post = controller.post;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.repeat,
                color: post.hasRepicced ? Colors.green : scheme.primary,
              ),
              title: Text(post.hasRepicced ? 'Undo Repic' : 'Repic'),
              subtitle: const Text('Share to your followers'),
              onTap: () {
                Navigator.pop(ctx);
                controller.toggleRepic();
              },
            ),
            ListTile(
              leading: Icon(Icons.format_quote, color: scheme.primary),
              title: const Text('Quote'),
              subtitle: const Text('Add your thoughts'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onQuoteTap?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EngagementButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int? count;
  final VoidCallback? onTap;

  const _EngagementButton({
    required this.icon,
    required this.color,
    this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(count!),
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
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
/// STANDALONE LIKE BUTTON
/// ============================================================================
/// For use outside of the full engagement bar
/// ============================================================================
class LikeButton extends StatefulWidget {
  final String postId;
  final bool initialLiked;
  final int initialCount;

  const LikeButton({
    super.key,
    required this.postId,
    this.initialLiked = false,
    this.initialCount = 0,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  late bool _isLiked;
  late int _count;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialLiked;
    _count = widget.initialCount;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isLoading ? null : _toggleLike,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              size: 22,
              color: _isLiked
                  ? Colors.red
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            if (_count > 0) ...[
              const SizedBox(width: 4),
              Text(
                _count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: _isLiked
                      ? Colors.red
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLoading = true;
      _isLiked = !_isLiked;
      _count += _isLiked ? 1 : -1;
    });

    try {
      // TODO: Call engagement service
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
