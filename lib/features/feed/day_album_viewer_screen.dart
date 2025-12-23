import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';

/// ---------------------------------------------------------------------------
/// DAY ALBUM / MEMORY VIEWER
/// ---------------------------------------------------------------------------
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

  static const double _dismissThreshold = 160.0;
  static const double _maxDrag = 300.0;

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

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 - (_dragProgress * 0.05);
    final backgroundOpacity = 1.0 - (_dragProgress * 0.35);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: backgroundOpacity),
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
                    setState(() => _currentPostIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return ChangeNotifierProvider(
                      create: (_) => EngagementController(
                        postId: widget.posts[index].postId,
                        initialPost: widget.posts[index],
                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// MEMORY POST (IMAGE-LEVEL NAVIGATION)
/// ---------------------------------------------------------------------------
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

    if (widget.post.imageUrls.length <= 1) return;

    _autoAdvanceTimer = Timer.periodic(_autoAdvanceInterval, (_) {
      if (_isUserInteracting) return;

      if (_currentImageIndex < widget.post.imageUrls.length - 1) {
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
    if (widget.post.imageUrls.length <= 1) return;

    final width = MediaQuery.of(context).size.width;
    final dx = details.localPosition.dx;

    _pauseAutoAdvance();

    if (dx < width * 0.3 && _currentImageIndex > 0) {
      _imageController.previousPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else if (dx > width * 0.7 &&
        _currentImageIndex < widget.post.imageUrls.length - 1) {
      _imageController.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.post.imageUrls;

    return Column(
      children: [
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
                  return Image.network(
                    images[index],
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
}

/// ---------------------------------------------------------------------------
/// IMAGE DOTS
/// ---------------------------------------------------------------------------
class _ImageDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _ImageDots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 8 : 5,
          height: isActive ? 8 : 5,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white38,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

/// ---------------------------------------------------------------------------
/// TOP OVERLAY
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
/// POST-LEVEL TIMELINE DOTS
/// ---------------------------------------------------------------------------
class _PostTimelineDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _PostTimelineDots({required this.count, required this.activeIndex});

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
/// ENGAGEMENT BAR
/// ---------------------------------------------------------------------------
class _MemoryEngagementBar extends StatelessWidget {
  final PostModel post;

  const _MemoryEngagementBar({required this.post});

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementController>();
    final post = engagement.post;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // LIKE
        IconButton(
          icon: Icon(
            post.hasLiked ? Icons.favorite : Icons.favorite_border,
            color: post.hasLiked ? Colors.red : Colors.white,
          ),
          onPressed: engagement.isProcessing ? null : engagement.toggleLike,
        ),

        // SAVE
        IconButton(
          icon: Icon(
            post.hasSaved ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.white,
          ),
          onPressed: engagement.isProcessing ? null : engagement.toggleSave,
        ),

        // REPIC / SHARE
        IconButton(
          icon: const Icon(Icons.repeat, color: Colors.white),
          onPressed: engagement.isProcessing ? null : engagement.toggleRepic,
        ),
      ],
    );
  }
}
