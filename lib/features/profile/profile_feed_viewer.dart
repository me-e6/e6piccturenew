import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';
import '../feed/day_album_viewer_screen.dart';

class ProfileFeedViewer extends StatefulWidget {
  final List<PostModel> posts;
  final int initialIndex;

  const ProfileFeedViewer({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<ProfileFeedViewer> createState() => _ProfileFeedViewerState();
}

class _ProfileFeedViewerState extends State<ProfileFeedViewer> {
  late final PageController _pageController;
  double _dragOffset = 0;
  int _currentIndex = 0;
  bool _showAuthorOverlay = true;

  // -----------------------------
  // DISMISS THRESHOLDS
  // -----------------------------
  static const double _dismissThreshold = 140;
  static const double _dismissVelocity = 1200; // px/sec

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0) {
      setState(() {
        _dragOffset += details.delta.dy;
      });
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (_dragOffset > _dismissThreshold || velocity > _dismissVelocity) {
      Navigator.pop(context);
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: _handleVerticalDragUpdate,
        onVerticalDragEnd: _handleVerticalDragEnd,
        child: Stack(
          children: [
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _showAuthorOverlay = true;
                  });

                  Future.delayed(const Duration(milliseconds: 1600), () {
                    if (mounted) {
                      setState(() {
                        _showAuthorOverlay = false;
                      });
                    }
                  });
                },
                itemCount: widget.posts.length,
                itemBuilder: (context, index) {
                  final post = widget.posts[index];

                  return ChangeNotifierProvider(
                    create: (_) => EngagementController(
                      postId: post.postId,
                      initialPost: post,
                    ),
                    child: Hero(
                      tag: 'post_${post.postId}',
                      child: DayAlbumViewerScreen(
                        posts: widget.posts,
                        initialIndex: index,
                        sessionStartedAt: DateTime.now(),
                      ),
                    ),
                  );
                },
              ),
            ),

            /// PAGE COUNTER (TOP-RIGHT)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.posts.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            /// AUTHOR OVERLAY (TOP-LEFT)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showAuthorOverlay ? 1.0 : 0.0,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage:
                          widget.posts[_currentIndex].authorAvatarUrl != null
                          ? NetworkImage(
                              widget.posts[_currentIndex].authorAvatarUrl!,
                            )
                          : null,
                      child: widget.posts[_currentIndex].authorAvatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.posts[_currentIndex].authorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (widget.posts[_currentIndex].isVerifiedOwner) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
