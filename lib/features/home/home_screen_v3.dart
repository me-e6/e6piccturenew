import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../feed/day_feed_controller.dart';
import '../feed/day_album_viewer_screen.dart';
import '../feed/day_album_tracker.dart';

import '../post/create/post_model.dart';

import '../engagement/engagement_controller.dart';

import '../follow/follow_controller.dart';

import '../profile/profile_entry.dart';

import '../search/search_screen.dart';
import '../search/search_controllers.dart';

import '../user/user_avatar_controller.dart';

import '../../core/theme/theme_controller.dart';
import '../post/reply/quote_reply_screen.dart';

import '../auth/auth_gate.dart';
import '../auth/auth_service.dart';

// ============================================================================
// CONSTANTS
// ============================================================================

/// UI constants for consistent design and performance optimization
class _HomeScreenConstants {
  // Colors
  static const Color backgroundColor = Color(0xFFF6F4EF);
  static const Color textColor = Color(0xFF3D3D3D);
  static const Color pillBackgroundColor = Color(0xFFE8E3D6);
  static const Color pillBorderColor = Color(0xFFD0C9B8);
  static const Color pillIconColor = Color(0xFF8B7355);
  static const Color pillTextColor = Color(0xFF4A4A4A);

  // Spacing & Padding
  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 8.0;
  static const double cardMarginHorizontal = 6.0;
  static const double headerPaddingHorizontal = 12.0;
  static const double headerPaddingVertical = 8.0;
  static const double engagementBarPaddingVertical = 6.0;
  static const double iconButtonPaddingHorizontal = 8.0;
  static const double iconButtonPaddingVertical = 4.0;

  // Sizing
  static const double appBarIconSize = 26.0;
  static const double searchIconSize = 25.0;
  static const double pillIconSize = 14.0;
  static const double engagementIconSize = 22.0;
  static const double avatarRadius = 16.0;
  static const double avatarIconSize = 16.0;
  static const double carouselHeight = 520.0;
  static const double suggestedUsersHeight = 120.0;
  static const double sheetHeightFraction = 0.75;

  // Border Radius
  static const double pillBorderRadius = 20.0;
  static const double cardBorderRadius = 12.0;
  static const double iconButtonBorderRadius = 20.0;
  static const double sheetBorderRadius = 24.0;

  // Border Width
  static const double pillBorderWidth = 0.5;

  // Page View
  static const double pageViewportFraction = 0.94;

  // Image Caching
  static const int maxCacheSize = 2048;
  static const int minCacheSize = 400;
  static const int defaultCacheSize = 400;
  static const int avatarCacheSize = 200; // Small size for avatars

  // Loading
  static const double progressIndicatorStrokeWidth = 2.0;

  // Typography
  static const double appBarTitleSize = 20.0;
  static const double appBarLetterSpacing = 1.5;
  static const FontWeight appBarFontWeight = FontWeight.w800;
  static const double pillTextSize = 12.5;
  static const double engagementCountSize = 12.0;
  static const FontWeight pillFontWeight = FontWeight.w600;
  static const FontWeight headerFontWeight = FontWeight.w600;
  static const FontWeight engagementCountFontWeight = FontWeight.w600;
}

// ============================================================================
// HOME SCREEN V3 - Main Screen
// ============================================================================

/// Main home screen displaying daily feed with posts
///
/// Features:
/// - Day Album notification pill
/// - Horizontal scrolling post carousel
/// - Suggested users section
/// - Search and notifications
/// - Profile sheet with settings
class HomeScreenV3 extends StatelessWidget {
  const HomeScreenV3({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch feed controller for state changes
    final feed = context.watch<DayFeedController>();
    final state = feed.state;
    final albumStatus = state.albumStatus;

    return Scaffold(
      backgroundColor: _HomeScreenConstants.backgroundColor,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: feed.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Day Album notification pill (shows when new posts available)
              if (albumStatus != null && albumStatus.hasUnseen)
                SliverToBoxAdapter(
                  child: _XStyleDayAlbumPill(
                    status: albumStatus,
                    onTap: feed.dismissAlbumPill,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Main post carousel
              SliverToBoxAdapter(
                child: _PostCarousel(
                  posts: state.posts,
                  isLoading: state.isLoading,
                  errorMessage: state.errorMessage,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Suggested users section (placeholder)
              const SliverToBoxAdapter(child: _SuggestedUsersSection()),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds app bar with menu, title, search, and notifications
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: _HomeScreenConstants.backgroundColor,

      // Menu button (opens profile sheet)
      leading: IconButton(
        icon: const Icon(
          Icons.menu_rounded,
          size: _HomeScreenConstants.appBarIconSize,
          color: _HomeScreenConstants.textColor,
        ),
        onPressed: () => _showProfileSheet(context),
      ),

      // App title
      title: const Text(
        'PICCTURE',
        style: TextStyle(
          fontWeight: _HomeScreenConstants.appBarFontWeight,
          fontSize: _HomeScreenConstants.appBarTitleSize,
          letterSpacing: _HomeScreenConstants.appBarLetterSpacing,
          color: _HomeScreenConstants.textColor,
        ),
      ),
      centerTitle: true,

      // Action buttons (search, notifications)
      actions: [
        // Search button
        IconButton(
          icon: const Icon(
            Icons.search_rounded,
            size: _HomeScreenConstants.searchIconSize,
            color: _HomeScreenConstants.textColor,
          ),
          onPressed: () => _openSearch(context),
        ),

        // Notifications button (placeholder)
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            size: _HomeScreenConstants.searchIconSize,
          ),
          onPressed: () {
            // TODO: Implement notifications
          },
        ),

        const SizedBox(width: 6),
      ],
    );
  }

  /// Opens search screen with dedicated controller
  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => SearchControllers(),
          child: const SearchScreen(),
        ),
      ),
    );
  }

  /// Shows bottom sheet with profile options and settings
  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ProfileBottomSheet(),
    );
  }
}

// ============================================================================
// DAY ALBUM PILL - Notification Banner
// ============================================================================

/// X/Twitter-style notification pill for new Day Album posts
///
/// Features:
/// - Dismissible on tap
/// - Shows unseen post count
/// - Styled to match app theme
class _XStyleDayAlbumPill extends StatelessWidget {
  final DayAlbumStatus status;
  final VoidCallback onTap;

  const _XStyleDayAlbumPill({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _HomeScreenConstants.horizontalPadding,
        vertical: _HomeScreenConstants.verticalPadding,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          _HomeScreenConstants.pillBorderRadius,
        ),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: _HomeScreenConstants.pillIconSize,
            vertical: _HomeScreenConstants.verticalPadding,
          ),
          decoration: BoxDecoration(
            color: _HomeScreenConstants.pillBackgroundColor,
            borderRadius: BorderRadius.circular(
              _HomeScreenConstants.pillBorderRadius,
            ),
            border: Border.all(
              color: _HomeScreenConstants.pillBorderColor,
              width: _HomeScreenConstants.pillBorderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Up arrow icon
              const Icon(
                Icons.arrow_upward_rounded,
                size: _HomeScreenConstants.pillIconSize,
                color: _HomeScreenConstants.pillIconColor,
              ),
              const SizedBox(width: 6),

              // Message text
              Text(
                status.message ?? 'New Picctures available',
                style: const TextStyle(
                  fontSize: _HomeScreenConstants.pillTextSize,
                  fontWeight: _HomeScreenConstants.pillFontWeight,
                  color: _HomeScreenConstants.pillTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// POST CAROUSEL - Horizontal Scrolling Posts
// ============================================================================

/// Horizontal carousel displaying posts
///
/// States:
/// - Loading: Shows progress indicator
/// - Error: Shows error message
/// - Empty: Shows empty state message
/// - Success: Shows post cards in PageView
class _PostCarousel extends StatelessWidget {
  final List<PostModel> posts;
  final bool isLoading;
  final String? errorMessage;

  const _PostCarousel({
    required this.posts,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: _HomeScreenConstants.progressIndicatorStrokeWidth,
          ),
        ),
      );
    }

    // Error state
    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No pictures yet today',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Check back soon for new posts!',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Success state: Display posts in carousel
    return SizedBox(
      height: _HomeScreenConstants.carouselHeight,
      child: PageView.builder(
        controller: PageController(
          viewportFraction: _HomeScreenConstants.pageViewportFraction,
        ),
        itemCount: posts.length,
        itemBuilder: (_, i) => _PostCard(post: posts[i]),
      ),
    );
  }
}

// ============================================================================
// POST CARD - Individual Post Display
// ============================================================================

/// Card displaying a single post with image and engagement controls
///
/// Features:
/// - Optimized image caching
/// - Tap to open full-screen viewer
/// - Post header with author info and follow button
/// - Engagement bar (like, repic, save, quote)
class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        // Create engagement controller and load engagement data
        final controller = EngagementController(
          postId: post.postId,
          initialPost: post,
        );
        controller.hydrate();
        return controller;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: _HomeScreenConstants.cardMarginHorizontal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            _HomeScreenConstants.cardBorderRadius,
          ),
        ),
        child: Column(
          children: [
            // Post header (author, follow button)
            _PostHeader(post: post),

            // Main image (tappable to open viewer)
            Expanded(child: _buildTappableImage(context, post)),

            // Engagement controls
            const _EngagementBar(),
          ],
        ),
      ),
    );
  }

  /// Builds tappable image that opens full-screen Day Album viewer
  Widget _buildTappableImage(BuildContext context, PostModel post) {
    return GestureDetector(
      // Open full-screen viewer on tap
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DayAlbumViewerScreen(
              posts: [post],
              sessionStartedAt: DateTime.now(),
            ),
          ),
        );
      },

      // Image with rounded corners and optimized caching
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          _HomeScreenConstants.cardBorderRadius,
        ),
        child: _buildOptimizedImage(post.imageUrls.first),
      ),
    );
  }

  /// Builds network image with optimal caching
  ///
  /// Features:
  /// - Dynamic cache sizing based on screen dimensions
  /// - Retina display support (pixel ratio)
  /// - Safety caps (min: 400px, max: 2048px)
  /// - Maintains aspect ratio (no distortion)
  /// - Loading progress indicator
  /// - Error fallback UI
  Widget _buildOptimizedImage(String imageUrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal cache size
        final pixelRatio = MediaQuery.of(context).devicePixelRatio;
        final width = constraints.maxWidth > 0
            ? constraints.maxWidth
            : _HomeScreenConstants.defaultCacheSize.toDouble();

        var cacheWidth = (width * pixelRatio).toInt();

        // Apply safety caps to prevent memory issues
        if (cacheWidth > _HomeScreenConstants.maxCacheSize) {
          cacheWidth = _HomeScreenConstants.maxCacheSize;
        }
        if (cacheWidth < _HomeScreenConstants.minCacheSize) {
          cacheWidth = _HomeScreenConstants.minCacheSize;
        }

        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          cacheWidth: cacheWidth, // Only width - maintains aspect ratio!
          // Loading state: Show progress indicator
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            return Center(
              child: CircularProgressIndicator(
                strokeWidth: _HomeScreenConstants.progressIndicatorStrokeWidth,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },

          // Error state: Show broken image icon
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Image load error: $error');

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.grey),
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
}

// ============================================================================
// POST HEADER - Author Info & Follow Button
// ============================================================================

/// Post header displaying author info and follow button
///
/// Features:
/// - Author avatar (optimized caching)
/// - Author name and handle (tappable to view profile)
/// - Follow/Following button (hidden for own posts)
/// - Real-time follow status updates
class _PostHeader extends StatelessWidget {
  final PostModel post;

  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    // Check if current user is the post author
    final isOwner = FirebaseAuth.instance.currentUser?.uid == post.authorId;

    return ChangeNotifierProvider(
      create: (_) =>
          FollowController()..loadFollower(targetUserId: post.authorId),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _HomeScreenConstants.headerPaddingHorizontal,
          vertical: _HomeScreenConstants.headerPaddingVertical,
        ),
        child: Row(
          children: [
            // Author info (avatar + name + handle) - tappable to view profile
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileEntry(userId: post.authorId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    // Author avatar with optimized caching
                    _buildAuthorAvatar(),

                    const SizedBox(width: 8),

                    // Author name and handle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Display name
                          Text(
                            post.authorName.isNotEmpty
                                ? post.authorName
                                : 'Unknown',
                            style: const TextStyle(
                              fontWeight: _HomeScreenConstants.headerFontWeight,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Handle (if available)
                          if (post.authorHandle != null &&
                              post.authorHandle!.isNotEmpty)
                            Text(
                              '@${post.authorHandle}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Follow button (hidden for own posts)
            if (!isOwner)
              Consumer<FollowController>(
                builder: (_, follow, __) => OutlinedButton(
                  onPressed: follow.isProcessing ? null : follow.toggle,
                  child: Text(follow.isFollowing ? 'Following' : 'Follow'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds author avatar with optimized caching
  ///
  /// Features:
  /// - Small cache size for performance (200px)
  /// - Fallback to person icon if no avatar
  /// - Real-time updates via UserAvatarController
  Widget _buildAuthorAvatar() {
    return ChangeNotifierProvider(
      create: (_) => UserAvatarController(post.authorId),
      child: Consumer<UserAvatarController>(
        builder: (_, avatar, __) {
          // If no avatar URL, show icon
          if (post.authorAvatarUrl == null) {
            return CircleAvatar(
              radius: _HomeScreenConstants.avatarRadius,
              child: const Icon(
                Icons.person,
                size: _HomeScreenConstants.avatarIconSize,
              ),
            );
          }

          // Show cached avatar image
          return CircleAvatar(
            radius: _HomeScreenConstants.avatarRadius,
            backgroundColor: Colors.grey[200],
            child: ClipOval(
              child: Image.network(
                post.authorAvatarUrl!,
                width: _HomeScreenConstants.avatarRadius * 2,
                height: _HomeScreenConstants.avatarRadius * 2,
                fit: BoxFit.cover,
                cacheWidth: _HomeScreenConstants.avatarCacheSize,

                // Loading state
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;

                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  );
                },

                // Error state: Fallback to icon
                errorBuilder: (_, __, ___) {
                  return const Icon(
                    Icons.person,
                    size: _HomeScreenConstants.avatarIconSize,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// ENGAGEMENT BAR - Like, Repic, Save, Quote
// ============================================================================

/// Engagement bar with interactive controls
///
/// Actions:
/// - Like: Toggle like status (heart icon)
/// - Repic: Repost to own feed (repeat icon)
/// - Save: Bookmark for later (bookmark icon)
/// - Quote: Open quote reply screen (chat icon)
///
/// Features:
/// - Real-time count updates
/// - Visual feedback (colors, icons)
/// - Disabled state during processing
class _EngagementBar extends StatelessWidget {
  const _EngagementBar();

  @override
  Widget build(BuildContext context) {
    // Watch engagement controller for state changes
    final engagement = context.watch<EngagementController>();
    final post = engagement.post;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: _HomeScreenConstants.engagementBarPaddingVertical,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // LIKE BUTTON
          _IconWithCount(
            icon: post.hasLiked ? Icons.favorite : Icons.favorite_border,
            color: post.hasLiked ? Colors.red : Colors.black,
            count: post.likeCount,
            onTap: engagement.isProcessing ? null : engagement.toggleLike,
          ),

          // REPIC BUTTON (Repost)
          _IconWithCount(
            icon: Icons.repeat,
            color: Colors.black,
            count: post.repicCount,
            onTap: engagement.isProcessing ? null : engagement.toggleRepic,
          ),

          // SAVE BUTTON (Bookmark)
          _IconWithCount(
            icon: post.hasSaved ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.black,
            count: post.saveCount,
            onTap: engagement.isProcessing ? null : engagement.toggleSave,
          ),

          // QUOTE BUTTON (Opens quote reply screen)
          _IconWithCount(
            icon: Icons.chat_bubble_outline,
            color: Colors.black,
            count: post.quoteReplyCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<EngagementController>(),
                    child: QuoteReplyScreen(postId: post.postId),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ICON WITH COUNT - Reusable Engagement Button
// ============================================================================

/// Reusable button for engagement actions
///
/// Features:
/// - Icon with count below
/// - Tap ripple effect
/// - Disabled state support
/// - Color customization
class _IconWithCount extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  const _IconWithCount({
    required this.icon,
    required this.count,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        _HomeScreenConstants.iconButtonBorderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _HomeScreenConstants.iconButtonPaddingHorizontal,
          vertical: _HomeScreenConstants.iconButtonPaddingVertical,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              icon,
              color: color,
              size: _HomeScreenConstants.engagementIconSize,
            ),

            const SizedBox(height: 2),

            // Count
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: _HomeScreenConstants.engagementCountSize,
                fontWeight: _HomeScreenConstants.engagementCountFontWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SUGGESTED USERS - Placeholder Section
// ============================================================================

/// Placeholder section for suggested users feature
///
/// TODO: Implement suggested users algorithm and UI
class _SuggestedUsersSection extends StatelessWidget {
  const _SuggestedUsersSection();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: _HomeScreenConstants.suggestedUsersHeight,
      child: Center(
        child: Text(
          'Suggested users coming soon',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

// ============================================================================
// PROFILE BOTTOM SHEET - Settings & Logout
// ============================================================================

/// Bottom sheet displaying profile options and settings
///
/// Features:
/// - Theme toggle (day/night mode)
/// - Logout with confirmation
/// - Future: Profile settings, account management
class _ProfileBottomSheet extends StatelessWidget {
  const _ProfileBottomSheet();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();

    return Container(
      height:
          MediaQuery.of(context).size.height *
          _HomeScreenConstants.sheetHeightFraction,
      decoration: const BoxDecoration(
        color: _HomeScreenConstants.backgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_HomeScreenConstants.sheetBorderRadius),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Theme toggle
          SwitchListTile(
            value: theme.isDarkMode,
            onChanged: (_) => theme.toggleTheme(),
            title: const Text('Day / Night Mode'),
          ),

          // Logout button
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _handleLogout(context),
          ),

          // TODO: Add more settings options
          // - Edit Profile
          // - Privacy Settings
          // - Notifications
          // - Help & Support
        ],
      ),
    );
  }
}

// ============================================================================
// LOGOUT HANDLER - Confirmation & Navigation
// ============================================================================

/// Handles logout process with confirmation dialog
///
/// Steps:
/// 1. Show confirmation dialog
/// 2. If confirmed, call AuthService.logout()
/// 3. Navigate to AuthGate (login screen)
/// 4. Clear navigation stack
Future<void> _handleLogout(BuildContext context) async {
  // Show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Logout'),
        ),
      ],
    ),
  );

  // User cancelled
  if (confirmed != true) return;

  // Perform logout
  await AuthService().logout();

  // Navigate to auth gate and clear stack
  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }
}
