/* import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'day_feed_controller.dart';
import 'day_feed_service.dart';
import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';

/// ----------------------------------
/// DayFeedScreen
/// ----------------------------------
class DayFeedScreen extends StatefulWidget {
  const DayFeedScreen({super.key});

  @override
  State<DayFeedScreen> createState() => _DayFeedScreenState();
}

class _DayFeedScreenState extends State<DayFeedScreen> {
  late final DayFeedController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DayFeedController(DayFeedService());
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DayFeedController>.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(title: const Text('PICCTURE')),
        body: const _DayFeedBody(),
      ),
    );
  }
}

/// ----------------------------------
/// _DayFeedBody
/// ----------------------------------
class _DayFeedBody extends StatelessWidget {
  const _DayFeedBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<DayFeedController>(
      builder: (context, controller, _) {
        final state = controller.state;

        return Column(
          children: [
            _DayAlbumBanner(
              hasNewPosts: state.hasNewPosts,
              postCount: state.posts.length,
              onTap: () async {
                controller.markBannerSeen();
                await controller.refresh();
              },
            ),
            Expanded(child: _FeedContent()),
          ],
        );
      },
    );
  }
}

/// ----------------------------------
/// Day Album Banner
/// ----------------------------------
class _DayAlbumBanner extends StatelessWidget {
  final bool hasNewPosts;
  final int postCount;
  final VoidCallback onTap;

  const _DayAlbumBanner({
    required this.hasNewPosts,
    required this.postCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String text = hasNewPosts
        ? 'New posts available — tap to refresh'
        : 'You have $postCount pictures to review today';

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasNewPosts
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.08),
          border: Border(
            bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasNewPosts ? Icons.refresh : Icons.photo_library_outlined,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------------
/// Feed Content
/// ----------------------------------
class _FeedContent extends StatelessWidget {
  // final PageController _pageController = PageController(viewportFraction: 0.92);
  @override
  Widget build(BuildContext context) {
    return Consumer<DayFeedController>(
      builder: (context, controller, _) {
        final state = controller.state;

        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null) {
          return Center(
            child: Text(
              state.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (state.posts.isEmpty) {
          return const Center(child: Text('No pictures to review today'));
        }

        return PageView.builder(
          itemCount: state.posts.length,
          itemBuilder: (context, index) {
            final post = state.posts[index];

            return ChangeNotifierProvider(
              create: (_) =>
                  EngagementController(postId: post.postId, initialPost: post),
              child: _PostCard(post: post),
            );
          },
        );
      },
    );
  }
}

/// ----------------------------------
/// _PostCard
/// ----------------------------------
class _PostCard extends StatefulWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.post.imageUrls;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Stack(
                  children: [
                    _buildImageCarousel(images),
                    if (images.length > 1) _buildImageIndicator(images.length),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _EngagementBar(post: widget.post),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) {
      return const Center(child: Text('No image available'));
    }

    if (images.length == 1) {
      return _buildImage(images.first);
    }

    return PageView.builder(
      itemCount: images.length,
      onPageChanged: (index) {
        setState(() => _currentImageIndex = index);
      },
      itemBuilder: (context, index) {
        return _buildImage(images[index]);
      },
    );
  }

  Widget _buildImage(String imageUrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get device pixel ratio for retina displays
        final pixelRatio = MediaQuery.of(context).devicePixelRatio;

        // Calculate cache width (maintain aspect ratio)
        final width = constraints.maxWidth > 0 ? constraints.maxWidth : 400;
        var cacheWidth = (width * pixelRatio).toInt();

        // Safety caps: prevent excessive memory usage
        if (cacheWidth > 2048) cacheWidth = 2048;
        if (cacheWidth < 400) cacheWidth = 400;

        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          cacheWidth: cacheWidth, // ← Optimized caching!
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (_, __, ___) {
            return const Center(child: Icon(Icons.broken_image, size: 48));
          },
        );
      },
    );
  }

  Widget _buildImageIndicator(int total) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${_currentImageIndex + 1} / $total',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

/// ----------------------------------
/// Engagement Bar
/// ----------------------------------
class _EngagementBar extends StatelessWidget {
  final PostModel post;

  const _EngagementBar({required this.post});

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementController>();
    final post = engagement.post;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // LIKE
        IconButton(
          icon: Icon(
            post.hasLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
          ),
          onPressed: engagement.isProcessing ? null : engagement.toggleLike,
        ),

        // REPIC
        IconButton(
          icon: const Icon(Icons.repeat),
          onPressed: engagement.isProcessing ? null : engagement.toggleRepic,
        ),

        // SAVE
        IconButton(
          icon: Icon(post.hasSaved ? Icons.bookmark : Icons.bookmark_border),
          onPressed: engagement.isProcessing ? null : engagement.toggleSave,
        ),

        // MORE
        IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
      ],
    );
  }
}
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'day_feed_controller.dart';
import 'day_feed_service.dart';
import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';

// ============================================================================
// CONSTANTS
// ============================================================================

/// UI spacing and sizing constants for consistent design
class _Constants {
  // Spacing
  static const double bannerPaddingHorizontal = 16.0;
  static const double bannerPaddingVertical = 12.0;
  static const double cardPaddingVertical = 12.0;
  static const double cardPaddingHorizontal = 8.0;
  static const double contentSpacing = 8.0;

  // Sizing
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 16.0;
  static const double iconSize = 20.0;
  static const double brokenImageIconSize = 48.0;
  static const double indicatorBorderRadius = 12.0;
  static const double indicatorPaddingHorizontal = 8.0;
  static const double indicatorPaddingVertical = 4.0;

  // Image caching
  static const int maxCacheSize = 2048;
  static const int minCacheSize = 400;
  static const int defaultCacheSize = 400;

  // Aspect ratios
  static const double postImageAspectRatio = 4 / 5; // Instagram-style

  // Opacity
  static const double bannerNewPostsOpacity = 0.1;
  static const double bannerDefaultOpacity = 0.08;
  static const double bannerBorderOpacity = 0.2;
  static const double indicatorBackgroundOpacity = 0.6;

  // Animations
  static const double progressIndicatorStrokeWidth = 2.0;
}

// ============================================================================
// DAY FEED SCREEN - Main Entry Point
// ============================================================================

/// Main screen displaying a feed of posts from the last 24 hours
///
/// Features:
/// - Banner showing new post notifications
/// - PageView for Instagram-style post browsing
/// - Real-time engagement (likes, saves, repics)
/// - Optimized image caching for performance
class DayFeedScreen extends StatefulWidget {
  const DayFeedScreen({super.key});

  @override
  State<DayFeedScreen> createState() => _DayFeedScreenState();
}

class _DayFeedScreenState extends State<DayFeedScreen> {
  late final DayFeedController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller with service
    _controller = DayFeedController(DayFeedService());
    _controller.init();
  }

  @override
  void dispose() {
    // Clean up controller to prevent memory leaks
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DayFeedController>.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(title: const Text('PICCTURE')),
        body: const _DayFeedBody(),
      ),
    );
  }
}

// ============================================================================
// DAY FEED BODY - Main Content Area
// ============================================================================

/// Body widget containing banner and feed content
/// Listens to controller state changes via Consumer
class _DayFeedBody extends StatelessWidget {
  const _DayFeedBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<DayFeedController>(
      builder: (context, controller, _) {
        final state = controller.state;

        return Column(
          children: [
            // Top banner showing notification status
            _DayAlbumBanner(
              hasNewPosts: state.hasNewPosts,
              postCount: state.posts.length,
              onTap: () async {
                // Mark banner as seen and refresh feed
                controller.markBannerSeen();
                await controller.refresh();
              },
            ),

            // Main feed content (expands to fill remaining space)
            Expanded(child: _FeedContent()),
          ],
        );
      },
    );
  }
}

// ============================================================================
// DAY ALBUM BANNER - Notification Bar
// ============================================================================

/// Banner displaying post count and new post notifications
///
/// States:
/// - Has new posts: Blue background with refresh prompt
/// - No new posts: Gray background with review count
class _DayAlbumBanner extends StatelessWidget {
  final bool hasNewPosts;
  final int postCount;
  final VoidCallback onTap;

  const _DayAlbumBanner({
    required this.hasNewPosts,
    required this.postCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic text based on state
    final String text = hasNewPosts
        ? 'New posts available — tap to refresh'
        : 'You have $postCount pictures to review today';

    // Dynamic icon based on state
    final IconData icon = hasNewPosts
        ? Icons.refresh
        : Icons.photo_library_outlined;

    // Dynamic color based on state
    final Color backgroundColor = hasNewPosts
        ? Colors.blue.withValues(alpha: _Constants.bannerNewPostsOpacity)
        : Colors.grey.withValues(alpha: _Constants.bannerDefaultOpacity);

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: _Constants.bannerPaddingHorizontal,
          vertical: _Constants.bannerPaddingVertical,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withValues(
                alpha: _Constants.bannerBorderOpacity,
              ),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: _Constants.iconSize),
            const SizedBox(width: _Constants.contentSpacing),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// FEED CONTENT - Post List/Grid
// ============================================================================

/// Main feed content displaying posts in a PageView
///
/// Handles three states:
/// 1. Loading: Shows progress indicator
/// 2. Error: Shows error message
/// 3. Success: Shows posts or empty state
class _FeedContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DayFeedController>(
      builder: (context, controller, _) {
        final state = controller.state;

        // Loading state
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state
        if (state.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Empty state
        if (state.posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No pictures to review today',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Check back tomorrow for new posts!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Success state: Display posts in PageView
        return PageView.builder(
          itemCount: state.posts.length,
          // Accessibility: Announce page changes
          onPageChanged: (index) {
            // Could add analytics tracking here
            debugPrint('Viewing post ${index + 1} of ${state.posts.length}');
          },
          itemBuilder: (context, index) {
            final post = state.posts[index];

            // Each post gets its own EngagementController
            return ChangeNotifierProvider(
              create: (_) =>
                  EngagementController(postId: post.postId, initialPost: post),
              child: _PostCard(post: post),
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// POST CARD - Individual Post Display
// ============================================================================

/// Card displaying a single post with images and engagement controls
///
/// Features:
/// - Image carousel for multiple photos
/// - Image indicator showing current position
/// - Engagement bar (like, repic, save)
/// - Optimized image caching
class _PostCard extends StatefulWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  // Track current image in carousel
  int _currentImageIndex = 0;

  // PageController for image carousel (if multiple images)
  PageController? _imagePageController;

  @override
  void initState() {
    super.initState();
    // Only create PageController if there are multiple images
    if (widget.post.imageUrls.length > 1) {
      _imagePageController = PageController();
    }
  }

  @override
  void dispose() {
    // IMPORTANT: Dispose PageController to prevent memory leaks
    _imagePageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.post.imageUrls;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: _Constants.cardPaddingVertical,
        horizontal: _Constants.cardPaddingHorizontal,
      ),
      child: Card(
        elevation: _Constants.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Constants.cardBorderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image area with rounded top corners
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_Constants.cardBorderRadius),
              ),
              child: AspectRatio(
                aspectRatio: _Constants.postImageAspectRatio,
                child: Stack(
                  children: [
                    // Main image carousel
                    _buildImageCarousel(images),

                    // Image counter indicator (only if multiple images)
                    if (images.length > 1) _buildImageIndicator(images.length),
                  ],
                ),
              ),
            ),

            const SizedBox(height: _Constants.contentSpacing),

            // Engagement controls (like, repic, save, more)
            _EngagementBar(post: widget.post),

            const SizedBox(height: _Constants.contentSpacing),
          ],
        ),
      ),
    );
  }

  /// Builds image carousel based on number of images
  ///
  /// - Single image: Shows static image
  /// - Multiple images: Shows PageView for swiping
  Widget _buildImageCarousel(List<String> images) {
    // Edge case: No images
    if (images.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('No image available', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Single image: No carousel needed
    if (images.length == 1) {
      return _buildImage(images.first);
    }

    // Multiple images: Use PageView for swipe navigation
    return PageView.builder(
      controller: _imagePageController,
      itemCount: images.length,
      onPageChanged: (index) {
        // Update current index for indicator
        setState(() => _currentImageIndex = index);
      },
      itemBuilder: (context, index) {
        return _buildImage(images[index]);
      },
    );
  }

  /// Builds optimized network image with caching
  ///
  /// Features:
  /// - Dynamic cache sizing based on screen
  /// - Retina display support (pixel ratio)
  /// - Safety caps (min: 400px, max: 2048px)
  /// - Maintains aspect ratio (no distortion)
  /// - Loading and error states
  Widget _buildImage(String imageUrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal cache size
        final pixelRatio = MediaQuery.of(context).devicePixelRatio;
        final width = constraints.maxWidth > 0
            ? constraints.maxWidth
            : _Constants.defaultCacheSize.toDouble();

        var cacheWidth = (width * pixelRatio).toInt();

        // Apply safety caps to prevent memory issues
        if (cacheWidth > _Constants.maxCacheSize) {
          cacheWidth = _Constants.maxCacheSize;
        }
        if (cacheWidth < _Constants.minCacheSize) {
          cacheWidth = _Constants.minCacheSize;
        }

        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          cacheWidth: cacheWidth, // Only width - maintains aspect ratio!
          // Loading state
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            // Show progress indicator while loading
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: _Constants.progressIndicatorStrokeWidth,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },

          // Error state
          errorBuilder: (context, error, stackTrace) {
            // Log error for debugging
            debugPrint('Image load error: $error');

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: _Constants.brokenImageIconSize,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Builds image position indicator (e.g., "2 / 5")
  ///
  /// Displays as a pill in top-right corner
  Widget _buildImageIndicator(int total) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _Constants.indicatorPaddingHorizontal,
          vertical: _Constants.indicatorPaddingVertical,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(
            alpha: _Constants.indicatorBackgroundOpacity,
          ),
          borderRadius: BorderRadius.circular(_Constants.indicatorBorderRadius),
        ),
        child: Text(
          '${_currentImageIndex + 1} / $total',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ENGAGEMENT BAR - Like, Repic, Save Controls
// ============================================================================

/// Bottom bar with engagement actions
///
/// Actions:
/// - Like/Unlike: Toggle like status
/// - Repic: Repost to own feed
/// - Save: Bookmark for later
/// - More: Additional options menu
class _EngagementBar extends StatelessWidget {
  final PostModel post;

  const _EngagementBar({required this.post});

  @override
  Widget build(BuildContext context) {
    // Watch engagement controller for state changes
    final engagement = context.watch<EngagementController>();
    final post = engagement.post;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // LIKE BUTTON
        _EngagementButton(
          icon: post.hasLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
          label: 'Like',
          count: post.likeCount,
          isActive: post.hasLiked,
          isLoading: engagement.isProcessing,
          onPressed: engagement.isProcessing ? null : engagement.toggleLike,
        ),

        // REPIC BUTTON (Repost)
        _EngagementButton(
          icon: Icons.repeat,
          label: 'Repic',
          count: post.repicCount,
          isActive: post.hasRepicced,
          isLoading: engagement.isProcessing,
          onPressed: engagement.isProcessing ? null : engagement.toggleRepic,
        ),

        // SAVE BUTTON (Bookmark)
        _EngagementButton(
          icon: post.hasSaved ? Icons.bookmark : Icons.bookmark_border,
          label: 'Save',
          count: post.saveCount,
          isActive: post.hasSaved,
          isLoading: engagement.isProcessing,
          onPressed: engagement.isProcessing ? null : engagement.toggleSave,
        ),

        // MORE OPTIONS
        IconButton(
          icon: const Icon(Icons.more_horiz),
          tooltip: 'More options',
          onPressed: () {
            // Show bottom sheet with more options
            _showMoreOptions(context, post);
          },
        ),
      ],
    );
  }

  /// Shows bottom sheet with additional post options
  void _showMoreOptions(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // Implement share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                // Implement report functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block user'),
              onTap: () {
                Navigator.pop(context);
                // Implement block functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ENGAGEMENT BUTTON - Reusable Engagement Action
// ============================================================================

/// Reusable button for engagement actions (like, repic, save)
///
/// Features:
/// - Shows icon (changes based on active state)
/// - Shows count (if > 0)
/// - Disabled state when loading
/// - Accessibility labels
class _EngagementButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool isActive;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _EngagementButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.isActive,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: isActive ? Theme.of(context).primaryColor : null,
          ),
          tooltip: label,
          onPressed: onPressed,
        ),

        // Show count if greater than 0
        if (count > 0)
          Text(
            _formatCount(count),
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Theme.of(context).primaryColor : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
      ],
    );
  }

  /// Formats large numbers (e.g., 1000 → 1K)
  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
