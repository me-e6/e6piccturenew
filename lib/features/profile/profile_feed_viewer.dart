import 'package:flutter/material.dart';

import '../post/create/post_model.dart';
import '../feed/day_album_viewer_screen.dart';

/// ============================================================================
/// PROFILE FEED VIEWER
/// ============================================================================
/// Opens posts from a user's profile in the immersive viewer.
/// 
/// This is a thin wrapper around DayAlbumViewerScreen that:
/// - Passes posts from profile grids to the viewer
/// - Supports Hero animations for smooth transitions
/// - All engagement, repic support, swipe gestures are handled by DayAlbumViewerScreen
/// 
/// USAGE:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => ProfileFeedViewer(
///       posts: userPosts,
///       initialIndex: tappedIndex,
///     ),
///   ),
/// );
/// ```
/// ============================================================================
class ProfileFeedViewer extends StatelessWidget {
  /// List of posts to display
  final List<PostModel> posts;
  
  /// Index of the post to show first
  final int initialIndex;

  const ProfileFeedViewer({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Validate inputs
    if (posts.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No posts to display',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Clamp initial index to valid range
    final safeIndex = initialIndex.clamp(0, posts.length - 1);

    // DayAlbumViewerScreen handles everything:
    // - Engagement actions (like, save, repic, quote, reply)
    // - Repic post support (shows RepicHeader, original content)
    // - Swipe down for engagement lists
    // - Swipe down to dismiss
    // - Image carousel with auto-advance
    // - Theme-aware design
    return DayAlbumViewerScreen(
      posts: posts,
      initialIndex: safeIndex,
      sessionStartedAt: DateTime.now(),
    );
  }
}

/// ============================================================================
/// PROFILE FEED VIEWER WITH HERO (Optional)
/// ============================================================================
/// Use this if you want Hero animation from grid thumbnails.
/// 
/// USAGE:
/// ```dart
/// // In your grid item:
/// Hero(
///   tag: 'post_${post.postId}',
///   child: Image.network(post.imageUrls.first),
/// )
/// 
/// // When tapped:
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => ProfileFeedViewerWithHero(
///       posts: userPosts,
///       initialIndex: tappedIndex,
///     ),
///   ),
/// );
/// ```
/// ============================================================================
class ProfileFeedViewerWithHero extends StatefulWidget {
  final List<PostModel> posts;
  final int initialIndex;

  const ProfileFeedViewerWithHero({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<ProfileFeedViewerWithHero> createState() => _ProfileFeedViewerWithHeroState();
}

class _ProfileFeedViewerWithHeroState extends State<ProfileFeedViewerWithHero> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.posts.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) {
      return const ProfileFeedViewer(posts: [], initialIndex: 0);
    }

    final currentPost = widget.posts[_currentIndex];

    // Wrap in Hero for animation
    return Hero(
      tag: 'post_${currentPost.postId}',
      child: DayAlbumViewerScreen(
        posts: widget.posts,
        initialIndex: _currentIndex,
        sessionStartedAt: DateTime.now(),
      ),
    );
  }
}
