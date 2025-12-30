import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e6piccturenew/features/common/widgets/gazetteer_badge.dart';
import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';
import '../engagement/engagement_lists_sheet.dart'; // ✅ NEW
import '../engagement/widgets/repic_header_widget.dart'; // ✅ NEW
import '../post/quote/quote_post_screen.dart';
import '../post/quote/quotes_list_screen.dart';
import '../post/reply/reply_screen.dart';
import '../post/reply/replies_list_screen.dart';

/// ===========================================================================
/// DAY ALBUM / MEMORY VIEWER V4
/// ===========================================================================
/// ENHANCEMENTS V4:
/// - ✅ Swipe down shows Engagement Lists (Repics/Quotes) BEFORE dismiss
/// - ✅ Repic post support (shows original content with repic header)
/// - ✅ Count taps navigate to respective lists
/// - ✅ Quote + Reply buttons with counts
/// - ✅ Theme-aware colors
/// ===========================================================================
class DayAlbumViewerScreen extends StatefulWidget {
  final List<PostModel> posts;
  final DateTime sessionStartedAt;
  final int initialIndex;

  const DayAlbumViewerScreen({
    super.key,
    required this.posts,
    required this.sessionStartedAt,
    this.initialIndex = 0,
  });

  @override
  State<DayAlbumViewerScreen> createState() => _DayAlbumViewerScreenState();
}

class _DayAlbumViewerScreenState extends State<DayAlbumViewerScreen> {
  late final PageController _postController;

  int _currentPostIndex = 0;
  double _dragOffset = 0.0;
  bool _engagementSheetShown = false; // ✅ Track if sheet was shown

  static const double _engagementThreshold =
      80.0; // ✅ First threshold for engagement
  static const double _dismissThreshold =
      200.0; // ✅ Second threshold for dismiss
  static const double _maxDrag = 350.0;

  @override
  void initState() {
    super.initState();
    _currentPostIndex = widget.initialIndex;
    _postController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  double get _dragProgress => (_dragOffset / _maxDrag).clamp(0.0, 1.0);

  /// Get current post being viewed
  PostModel get _currentPost => widget.posts[_currentPostIndex];

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 - (_dragProgress * 0.05);
    final backgroundOpacity = 1.0 - (_dragProgress * 0.35);

    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor.withOpacity(backgroundOpacity),
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            // Only allow downward drag
            if (details.delta.dy > 0) {
              setState(() => _dragOffset += details.delta.dy);
            }
          },
          onVerticalDragEnd: (_) {
            // ✅ NEW: Two-threshold system
            if (_dragOffset > _dismissThreshold) {
              // Second threshold - dismiss the screen
              Navigator.pop(context);
            } else if (_dragOffset > _engagementThreshold &&
                !_engagementSheetShown) {
              // First threshold - show engagement lists
              _showEngagementLists();
              _engagementSheetShown = true;
              setState(() => _dragOffset = 0);
            } else {
              // Reset drag
              setState(() => _dragOffset = 0);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..translate(0.0, _dragOffset)
              ..scale(scale),
            child: Stack(
              children: [
                /// POST-LEVEL PAGE VIEW
                PageView.builder(
                  controller: _postController,
                  itemCount: widget.posts.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPostIndex = index;
                      _engagementSheetShown = false; // Reset on page change
                    });
                  },
                  itemBuilder: (context, index) {
                    return ChangeNotifierProvider(
                      create: (_) {
                        final controller = EngagementController(
                          postId: widget.posts[index].postId,
                          initialPost: widget.posts[index],
                        );
                        controller.hydrate();
                        return controller;
                      },
                      child: _MemoryPost(post: widget.posts[index]),
                    );
                  },
                ),

                /// TOP OVERLAY
                _TopOverlay(
                  current: _currentPostIndex + 1,
                  total: widget.posts.length,
                  onClose: () => Navigator.pop(context),
                ),

                /// POST-LEVEL TIMELINE DOTS
                _PostTimelineDots(
                  count: widget.posts.length,
                  activeIndex: _currentPostIndex,
                ),

                /// ✅ NEW: Swipe Down Hint
                _SwipeDownHint(post: _currentPost),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ NEW: Show engagement lists bottom sheet
  void _showEngagementLists() {
    EngagementListsSheet.show(
      context,
      postId: _currentPost.postId,
      repicCount: _currentPost.repicCount,
      quoteCount: _currentPost.quoteReplyCount,
      likeCount: _currentPost.likeCount,
    );
  }
}

/// ===========================================================================
/// SWIPE DOWN HINT
/// ===========================================================================
class _SwipeDownHint extends StatelessWidget {
  final PostModel post;

  const _SwipeDownHint({required this.post});

  @override
  Widget build(BuildContext context) {
    final hasEngagement = post.repicCount > 0 || post.quoteReplyCount > 0;

    if (!hasEngagement) return const SizedBox.shrink();

    return Positioned(
      bottom: 90,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                'Swipe for ${post.repicCount} repics, ${post.quoteReplyCount} quotes',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===========================================================================
/// MEMORY POST (IMAGE-LEVEL NAVIGATION) - ✅ UPDATED FOR REPICS
/// ===========================================================================
class _MemoryPost extends StatefulWidget {
  final PostModel post;

  const _MemoryPost({required this.post});

  @override
  State<_MemoryPost> createState() => _MemoryPostState();
}

class _MemoryPostState extends State<_MemoryPost> {
  late final PageController _imageController;

  Timer? _autoAdvanceTimer;
  bool _isUserInteracting = false;
  int _currentImageIndex = 0;

  static const Duration _autoAdvanceInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _imageController.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();

    // ✅ Use effective images (original for repics)
    final images = _effectiveImageUrls;
    if (images.length <= 1) return;

    _autoAdvanceTimer = Timer.periodic(_autoAdvanceInterval, (_) {
      if (_isUserInteracting) return;

      if (_currentImageIndex < images.length - 1) {
        _imageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _autoAdvanceTimer?.cancel();
      }
    });
  }

  void _pauseAutoAdvance() {
    _isUserInteracting = true;
  }

  void _resumeAutoAdvance() {
    _isUserInteracting = false;
  }

  void _handleTap(BuildContext context, TapDownDetails details) {
    final images = _effectiveImageUrls;
    if (images.length <= 1) return;

    final width = MediaQuery.of(context).size.width;
    final dx = details.localPosition.dx;

    _pauseAutoAdvance();

    if (dx < width * 0.3 && _currentImageIndex > 0) {
      _imageController.previousPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else if (dx > width * 0.7 && _currentImageIndex < images.length - 1) {
      _imageController.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  /// ✅ Get effective image URLs (original for repics)
  List<String> get _effectiveImageUrls {
    if (widget.post.isRepic && widget.post.originalImageUrls.isNotEmpty) {
      return widget.post.originalImageUrls;
    }
    return widget.post.imageUrls;
  }

  /// ✅ Get effective caption (original for repics)
  String get _effectiveCaption {
    if (widget.post.isRepic) {
      return widget.post.originalCaption;
    }
    return widget.post.caption;
  }

  @override
  Widget build(BuildContext context) {
    final images = _effectiveImageUrls;
    final scheme = Theme.of(context).colorScheme;

    // Handle posts with no images
    if (images.isEmpty) {
      final isQuotePost =
          widget.post.isQuote ||
          widget.post.quotedPostId != null ||
          widget.post.quotedPreview != null;

      if (isQuotePost) {
        return _buildQuotePostView(context, scheme);
      }

      return Column(
        children: [
          // ✅ Repic header if this is a repic
          if (widget.post.isRepic && widget.post.repicAuthorId != null)
            RepicHeader(
              repicAuthorId: widget.post.repicAuthorId!,
              repicAuthorName: widget.post.repicAuthorName ?? 'User',
              repicAuthorHandle: widget.post.repicAuthorHandle,
              repicAuthorAvatarUrl: widget.post.repicAuthorAvatarUrl,
              repicAuthorIsVerified: widget.post.repicAuthorIsVerified,
            ),
          Expanded(
            child: Container(
              color: scheme.surfaceContainerHighest,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 64,
                      color: scheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No image available',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _MemoryEngagementBar(post: widget.post),
          const SizedBox(height: 12),
        ],
      );
    }

    return Column(
      children: [
        // ✅ NEW: Repic header (shows "User repicced")
        if (widget.post.isRepic && widget.post.repicAuthorId != null)
          RepicHeader(
            repicAuthorId: widget.post.repicAuthorId!,
            repicAuthorName: widget.post.repicAuthorName ?? 'User',
            repicAuthorHandle: widget.post.repicAuthorHandle,
            repicAuthorAvatarUrl: widget.post.repicAuthorAvatarUrl,
            repicAuthorIsVerified: widget.post.repicAuthorIsVerified,
          ),

        /// IMAGE VIEWER WITH TAP ZONES
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _handleTap(context, details),
            child: Listener(
              onPointerDown: (_) => _pauseAutoAdvance(),
              onPointerUp: (_) => _resumeAutoAdvance(),
              onPointerCancel: (_) => _resumeAutoAdvance(),
              child: PageView.builder(
                controller: _imageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemBuilder: (context, index) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final pixelRatio = MediaQuery.of(
                        context,
                      ).devicePixelRatio;
                      final width = constraints.maxWidth > 0
                          ? constraints.maxWidth
                          : 400;
                      var cacheWidth = (width * pixelRatio).toInt();

                      if (cacheWidth > 2048) cacheWidth = 2048;
                      if (cacheWidth < 400) cacheWidth = 400;

                      return Image.network(
                        images[index],
                        fit: BoxFit.contain,
                        cacheWidth: cacheWidth,
                        loadingBuilder: (_, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                        errorBuilder: (_, __, ___) {
                          return Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),

        /// IMAGE-LEVEL DOTS
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _ImageDots(
              count: images.length,
              activeIndex: _currentImageIndex,
            ),
          ),

        const SizedBox(height: 12),

        /// ENGAGEMENT BAR
        _MemoryEngagementBar(post: widget.post),

        const SizedBox(height: 12),
      ],
    );
  }

  /// Quote Post view
  Widget _buildQuotePostView(BuildContext context, ColorScheme scheme) {
    final quotedPreview = widget.post.quotedPreview;
    final commentary = widget.post.commentary;

    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (commentary != null && commentary.isNotEmpty) ...[
                  Text(
                    commentary,
                    style: TextStyle(
                      fontSize: 18,
                      color: scheme.onSurface,
                      height: 1.4,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: _buildQuotedPreviewCard(
                    context,
                    scheme,
                    quotedPreview,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _MemoryEngagementBar(post: widget.post),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildQuotedPreviewCard(
    BuildContext context,
    ColorScheme scheme,
    Map<String, dynamic>? preview,
  ) {
    if (preview == null) {
      return Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.link_off,
                size: 48,
                color: scheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Original post unavailable',
                style: TextStyle(
                  color: scheme.onSurfaceVariant.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final authorName = preview['authorName'] as String? ?? 'Unknown';
    final authorHandle = preview['authorHandle'] as String?;
    final authorAvatarUrl = preview['authorAvatarUrl'] as String?;
    final isVerified = preview['isVerifiedOwner'] as bool? ?? false;
    final thumbnailUrl = preview['thumbnailUrl'] as String?;
    final previewText = preview['previewText'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (thumbnailUrl != null)
              Expanded(
                flex: 3,
                child: Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: scheme.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: scheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ),
              ),

            // Author info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (authorAvatarUrl != null)
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(authorAvatarUrl),
                          backgroundColor: scheme.surfaceContainerHighest,
                        )
                      else
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: scheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    authorName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: scheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isVerified) ...[
                                  const SizedBox(width: 6),
                                  GazetteerBadge.small(),
                                  //const GazetteerStampBadge(size: 70),
                                ],
                              ],
                            ),
                            if (authorHandle != null)
                              Text(
                                '@$authorHandle',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (previewText != null && previewText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      previewText,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurface,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===========================================================================
/// TOP OVERLAY
/// ===========================================================================
class _TopOverlay extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onClose;

  const _TopOverlay({
    required this.current,
    required this.total,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.4), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.surface.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$current / $total',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Close button
            IconButton(
              onPressed: onClose,
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.surface.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: scheme.onSurface, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===========================================================================
/// IMAGE-LEVEL DOTS
/// ===========================================================================
class _ImageDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _ImageDots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(0.3);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 8 : 5,
          height: isActive ? 8 : 5,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

/// ===========================================================================
/// POST-LEVEL TIMELINE DOTS
/// ===========================================================================
class _PostTimelineDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _PostTimelineDots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(0.4);

    return Positioned(
      top: 44,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = index == activeIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 10 : 6,
            height: isActive ? 10 : 6,
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

/// ===========================================================================
/// ENGAGEMENT BAR V4 - ✅ UPDATED: Count taps show lists
/// ===========================================================================
class _MemoryEngagementBar extends StatelessWidget {
  final PostModel post;

  const _MemoryEngagementBar({required this.post});

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementController>();
    final currentPost = engagement.post;
    final scheme = Theme.of(context).colorScheme;
    final iconColor = scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // LIKE
          _EngagementAction(
            icon: currentPost.hasLiked ? Icons.favorite : Icons.favorite_border,
            color: currentPost.hasLiked ? Colors.red : iconColor,
            count: currentPost.likeCount,
            onPressed: engagement.isProcessing ? null : engagement.toggleLike,
            onCountTap: null,
          ),

          // REPLY
          _EngagementAction(
            icon: Icons.chat_bubble_outline,
            color: iconColor,
            count: currentPost.replyCount,
            onPressed: () => _navigateToReply(context, currentPost),
            onCountTap: currentPost.replyCount > 0
                ? () => _navigateToRepliesList(context, currentPost)
                : null,
          ),

          // QUOTE
          _EngagementAction(
            icon: Icons.format_quote_rounded,
            color: iconColor,
            count: currentPost.quoteReplyCount,
            onPressed: () => _navigateToQuote(context, currentPost),
            onCountTap: currentPost.quoteReplyCount > 0
                ? () => _showEngagementLists(context, currentPost)
                : null,
          ),

          // REPIC - ✅ UPDATED: Count tap shows engagement lists
          _EngagementAction(
            icon: Icons.repeat,
            color: currentPost.hasRepicced ? Colors.green : iconColor,
            count: currentPost.repicCount,
            onPressed: engagement.isProcessing ? null : engagement.toggleRepic,
            onCountTap: currentPost.repicCount > 0
                ? () => _showEngagementLists(context, currentPost)
                : null,
          ),

          // SAVE
          _EngagementAction(
            icon: currentPost.hasSaved ? Icons.bookmark : Icons.bookmark_border,
            color: currentPost.hasSaved ? Colors.amber : iconColor,
            count: currentPost.saveCount,
            onPressed: engagement.isProcessing ? null : engagement.toggleSave,
            onCountTap: null,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // NAVIGATION HELPERS
  // -------------------------------------------------------------------------

  void _navigateToReply(BuildContext context, PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReplyScreen(postId: post.postId)),
    ).then((_) {
      if (context.mounted) {
        context.read<EngagementController>().incrementReply();
      }
    });
  }

  void _navigateToRepliesList(BuildContext context, PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RepliesListScreen(post: post)),
    );
  }

  void _navigateToQuote(BuildContext context, PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuotePostScreen(postId: post.postId)),
    ).then((result) {
      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Quote posted!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _navigateToQuotesList(BuildContext context, PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuotesListScreen(
          postId: post.postId,
          postAuthorName: post.authorName,
        ),
      ),
    );
  }

  // ✅ NEW: Show engagement lists sheet
  void _showEngagementLists(BuildContext context, PostModel post) {
    EngagementListsSheet.show(
      context,
      postId: post.postId,
      repicCount: post.repicCount,
      quoteCount: post.quoteReplyCount,
      likeCount: post.likeCount,
    );
  }
}

/// ===========================================================================
/// ENGAGEMENT ACTION
/// ===========================================================================
class _EngagementAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback? onPressed;
  final VoidCallback? onCountTap;

  const _EngagementAction({
    required this.icon,
    required this.color,
    required this.count,
    this.onPressed,
    this.onCountTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
        if (count > 0)
          GestureDetector(
            onTap: onCountTap,
            child: Padding(
              padding: const EdgeInsets.only(left: 2, right: 4),
              child: Text(
                _formatCount(count),
                style: TextStyle(
                  color: onCountTap != null ? color : color.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
