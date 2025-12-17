import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';

/// ---------------------------------------------------------------------------
/// DAY ALBUM / MEMORY VIEWER
/// ---------------------------------------------------------------------------
/// - Read-only viewer for a Day Feed session
/// - Supports entry from banner (index 0)
/// - Supports entry from long-press (specific index)
/// - Swipe-down to dismiss
/// - Timeline dots indicate progress through posts
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
  late final PageController _pageController;
  int _currentIndex = 0;

  double _dragOffset = 0;
  static const double _dismissThreshold = 160;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 0) {
              setState(() => _dragOffset += details.delta.dy);
            }
          },
          onVerticalDragEnd: (_) {
            if (_dragOffset > _dismissThreshold) {
              Navigator.pop(context);
            } else {
              setState(() => _dragOffset = 0);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, _dragOffset, 0),
            child: Opacity(
              opacity: 1 - (_dragOffset / 300).clamp(0.0, 0.4),
              child: Stack(
                children: [
                  /// MAIN PAGE VIEW (POST LEVEL)
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.posts.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return ChangeNotifierProvider(
                        create: (_) => EngagementController(),
                        child: _MemoryPost(post: widget.posts[index]),
                      );
                    },
                  ),

                  /// TOP OVERLAY (INDEX + CLOSE)
                  _TopOverlay(
                    current: _currentIndex + 1,
                    total: widget.posts.length,
                    onClose: () => Navigator.pop(context),
                  ),

                  /// TIMELINE DOTS
                  _TimelineDots(
                    count: widget.posts.length,
                    activeIndex: _currentIndex,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// SINGLE MEMORY POST
/// ---------------------------------------------------------------------------
class _MemoryPost extends StatelessWidget {
  final PostModel post;

  const _MemoryPost({required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            itemCount: post.imageUrls.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Image.network(
                  post.imageUrls[index],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (_, __, ___) {
                    return const Center(
                      child: Icon(Icons.broken_image, color: Colors.white),
                    );
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        _MemoryEngagementBar(post: post),

        const SizedBox(height: 12),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// TOP OVERLAY (INDEX + CLOSE)
/// ---------------------------------------------------------------------------
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
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$current / $total',
            style: const TextStyle(color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// TIMELINE DOTS (POST-LEVEL)
/// ---------------------------------------------------------------------------
class _TimelineDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _TimelineDots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
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
              color: isActive ? Colors.white : Colors.white54,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// ENGAGEMENT BAR (MEMORY VIEW)
/// ---------------------------------------------------------------------------
class _MemoryEngagementBar extends StatelessWidget {
  final PostModel post;

  const _MemoryEngagementBar({required this.post});

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            post.hasLiked ? Icons.favorite : Icons.favorite_border,
            color: post.hasLiked ? Colors.red : Colors.white,
          ),
          onPressed: () {
            post.hasLiked
                ? engagement.dislikePost(post)
                : engagement.likePost(post);
          },
        ),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(
            post.hasSaved ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.white,
          ),
          onPressed: () => engagement.savePost(post),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white),
          onPressed: () => engagement.sharePost(post),
        ),
      ],
    );
  }
}
