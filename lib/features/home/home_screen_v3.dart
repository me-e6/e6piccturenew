import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../feed/day_feed_controller.dart';
import '../feed/day_album_viewer_screen.dart';
import '../feed/day_album_tracker.dart';

import '../post/create/post_model.dart';

import '../engagement/engagement_controller.dart';
import '../engagement/widgets/repic_header_widget.dart'; // ✅ FIXED: widgets/ not widget/

import '../follow/follow_controller.dart';

import '../profile/profile_entry.dart';

import '../search/search_screen.dart';
import '../search/search_controllers.dart';

import '../user/user_avatar_controller.dart';

import '../../core/theme/theme_controller.dart';

import '../auth/auth_gate.dart';
import '../auth/auth_service.dart';

// ✅ Quote System
import '../post/quote/quote_post_screen.dart';
import '../post/quote/quotes_list_screen.dart';

// ✅ Reply System
import '../post/reply/reply_screen.dart';
import '../post/reply/replies_list_screen.dart';

// ✅ NEW: Engagement Lists (for Repics/Quotes)
import '../engagement/engagement_lists_sheet.dart';

// ============================================================================
// CONSTANTS
// ============================================================================

class _HomeScreenConstants {
  static const Color brandAccent = Color(0xFF8B7355);

  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 8.0;
  static const double cardMarginHorizontal = 6.0;
  static const double headerPaddingHorizontal = 12.0;
  static const double headerPaddingVertical = 8.0;
  static const double engagementBarPaddingVertical = 6.0;
  static const double engagementBarPaddingHorizontal = 8.0;
  static const double iconButtonPaddingHorizontal = 8.0;
  static const double iconButtonPaddingVertical = 4.0;

  static const double appBarIconSize = 26.0;
  static const double searchIconSize = 25.0;
  static const double pillIconSize = 14.0;
  static const double engagementIconSize = 22.0;
  static const double avatarRadius = 16.0;
  static const double avatarIconSize = 16.0;
  static const double carouselHeight = 520.0;
  static const double suggestedUsersHeight = 120.0;
  static const double sheetHeightFraction = 0.75;

  static const double pillBorderRadius = 20.0;
  static const double cardBorderRadius = 12.0;
  static const double iconButtonBorderRadius = 20.0;
  static const double sheetBorderRadius = 24.0;

  static const double pillBorderWidth = 0.5;

  static const double pageViewportFraction = 0.94;

  static const int maxCacheSize = 2048;
  static const int minCacheSize = 400;
  static const int defaultCacheSize = 400;
  static const int avatarCacheSize = 200;

  static const double progressIndicatorStrokeWidth = 2.0;

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
// HOME SCREEN V3
// ============================================================================

class HomeScreenV3 extends StatelessWidget {
  const HomeScreenV3({super.key});

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<DayFeedController>();
    final state = feed.state;
    final albumStatus = state.albumStatus;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: _buildAppBar(context, scheme),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: feed.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (albumStatus != null && albumStatus.hasUnseen)
                SliverToBoxAdapter(
                  child: _XStyleDayAlbumPill(
                    status: albumStatus,
                    onTap: feed.dismissAlbumPill,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              SliverToBoxAdapter(
                child: _PostCarousel(
                  posts: state.posts,
                  isLoading: state.isLoading,
                  errorMessage: state.errorMessage,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              const SliverToBoxAdapter(child: _SuggestedUsersSection()),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ColorScheme scheme) {
    return AppBar(
      elevation: 0,
      backgroundColor: scheme.surface,
      leading: IconButton(
        icon: Icon(
          Icons.menu_rounded,
          size: _HomeScreenConstants.appBarIconSize,
          color: scheme.onSurface,
        ),
        onPressed: () => _showProfileSheet(context),
      ),
      title: Text(
        'PICCTURE',
        style: TextStyle(
          fontWeight: _HomeScreenConstants.appBarFontWeight,
          fontSize: _HomeScreenConstants.appBarTitleSize,
          letterSpacing: _HomeScreenConstants.appBarLetterSpacing,
          color: scheme.onSurface,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Icons.search_rounded,
            size: _HomeScreenConstants.searchIconSize,
            color: scheme.onSurface,
          ),
          onPressed: () => _openSearch(context),
        ),
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            size: _HomeScreenConstants.searchIconSize,
            color: scheme.onSurface,
          ),
          onPressed: () {
            // TODO: Implement notifications
          },
        ),
        const SizedBox(width: 6),
      ],
    );
  }

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
// DAY ALBUM PILL
// ============================================================================

class _XStyleDayAlbumPill extends StatelessWidget {
  final DayAlbumStatus status;
  final VoidCallback onTap;

  const _XStyleDayAlbumPill({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
            color: scheme.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(
              _HomeScreenConstants.pillBorderRadius,
            ),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.3),
              width: _HomeScreenConstants.pillBorderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: _HomeScreenConstants.pillIconSize,
                color: scheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                status.message ?? 'New Picctures available',
                style: TextStyle(
                  fontSize: _HomeScreenConstants.pillTextSize,
                  fontWeight: _HomeScreenConstants.pillFontWeight,
                  color: scheme.onPrimaryContainer,
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
// POST CAROUSEL
// ============================================================================

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
    final scheme = Theme.of(context).colorScheme;

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

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: scheme.error),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(color: scheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No pictures yet today',
                style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back soon for new posts!',
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: _HomeScreenConstants.carouselHeight,
      child: PageView.builder(
        controller: PageController(
          viewportFraction: _HomeScreenConstants.pageViewportFraction,
        ),
        itemCount: posts.length,
        itemBuilder: (_, i) =>
            _PostCard(post: posts[i], allPosts: posts, postIndex: i),
      ),
    );
  }
}

// ============================================================================
// POST CARD - ✅ UPDATED: Supports Repic Posts
// ============================================================================

class _PostCard extends StatelessWidget {
  final PostModel post;
  final List<PostModel> allPosts;
  final int postIndex;

  const _PostCard({
    required this.post,
    required this.allPosts,
    required this.postIndex,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider(
      create: (_) {
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
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            _HomeScreenConstants.cardBorderRadius,
          ),
        ),
        child: Column(
          children: [
            // ✅ NEW: Repic Header (shows "User repicced" for repic posts)
            if (post.isRepic && post.repicAuthorId != null)
              RepicHeader(
                repicAuthorId: post.repicAuthorId!,
                repicAuthorName: post.repicAuthorName ?? 'User',
                repicAuthorHandle: post.repicAuthorHandle,
                repicAuthorAvatarUrl: post.repicAuthorAvatarUrl,
                repicAuthorIsVerified: post.repicAuthorIsVerified,
              ),

            // Post header (shows ORIGINAL author for repic posts)
            _PostHeader(post: post),

            // Main image (uses ORIGINAL images for repic posts)
            Expanded(child: _buildTappableImage(context, post)),

            // Engagement controls
            _EngagementBar(post: post),
          ],
        ),
      ),
    );
  }

  /// Builds tappable image - ✅ UPDATED: Uses original content for repic posts
  Widget _buildTappableImage(BuildContext context, PostModel post) {
    // ✅ For repic posts, use original post's images
    final imageUrls = post.isRepic && post.originalImageUrls.isNotEmpty
        ? post.originalImageUrls
        : post.imageUrls;

    if (imageUrls.isEmpty) {
      return _buildNoImagePlaceholder(context);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DayAlbumViewerScreen(
              posts: allPosts,
              sessionStartedAt: DateTime.now(),
              initialIndex: postIndex,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          _HomeScreenConstants.cardBorderRadius,
        ),
        child: _buildOptimizedImage(context, imageUrls.first),
      ),
    );
  }

  Widget _buildNoImagePlaceholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final isQuote =
        post.isQuote || post.quotedPostId != null || post.quotedPreview != null;

    if (isQuote) {
      return _buildQuotePostContent(context, scheme);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DayAlbumViewerScreen(
              posts: allPosts,
              sessionStartedAt: DateTime.now(),
              initialIndex: postIndex,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(
            _HomeScreenConstants.cardBorderRadius,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No image',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotePostContent(BuildContext context, ColorScheme scheme) {
    final quotedPreview = post.quotedPreview;
    final commentary = post.commentary;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DayAlbumViewerScreen(
              posts: allPosts,
              sessionStartedAt: DateTime.now(),
              initialIndex: postIndex,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(
            _HomeScreenConstants.cardBorderRadius,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (commentary != null && commentary.isNotEmpty) ...[
              Text(
                commentary,
                style: TextStyle(
                  fontSize: 15,
                  color: scheme.onSurface,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: _buildQuotedPreviewCard(context, scheme, quotedPreview),
            ),
          ],
        ),
      ),
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
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            'Original post unavailable',
            style: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
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
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            if (thumbnailUrl != null)
              SizedBox(
                width: 120,
                child: Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  cacheWidth: 240,
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
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (authorAvatarUrl != null)
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: NetworkImage(authorAvatarUrl),
                            backgroundColor: scheme.surfaceContainerHighest,
                          )
                        else
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: scheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.person,
                              size: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            authorName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified, size: 14, color: scheme.primary),
                        ],
                      ],
                    ),
                    if (authorHandle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$authorHandle',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (previewText != null && previewText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        previewText,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (thumbnailUrl == null &&
                        (previewText == null || previewText.isEmpty)) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 14,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Photo',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildOptimizedImage(BuildContext context, String imageUrl) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelRatio = MediaQuery.of(context).devicePixelRatio;
        final width = constraints.maxWidth > 0
            ? constraints.maxWidth
            : _HomeScreenConstants.defaultCacheSize.toDouble();

        var cacheWidth = (width * pixelRatio).toInt();

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
          cacheWidth: cacheWidth,
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
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Image load error: $error');

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 48,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
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
// POST HEADER - ✅ UPDATED: Shows original author for repic posts
// ============================================================================

class _PostHeader extends StatelessWidget {
  final PostModel post;

  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // ✅ For repic posts, the authorId is already the original author
    // (RepicService stores original author in authorId field)
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
                    _buildAuthorAvatar(context),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  post.authorName.isNotEmpty
                                      ? post.authorName
                                      : 'Unknown',
                                  style: TextStyle(
                                    fontWeight:
                                        _HomeScreenConstants.headerFontWeight,
                                    fontSize: 14,
                                    color: scheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (post.authorIsVerified) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: scheme.primary,
                                ),
                              ],
                            ],
                          ),
                          if (post.authorHandle != null &&
                              post.authorHandle!.isNotEmpty)
                            Text(
                              '@${post.authorHandle}',
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
              ),
            ),

            // Follow button (hidden for own posts)
            if (!isOwner) _buildFollowButton(context, scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorAvatar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider(
      create: (_) => UserAvatarController(post.authorId),
      child: Consumer<UserAvatarController>(
        builder: (context, controller, _) {
          final avatarUrl = controller.avatarUrl ?? post.authorAvatarUrl;

          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            return CircleAvatar(
              radius: _HomeScreenConstants.avatarRadius,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: scheme.surfaceContainerHighest,
            );
          }

          return CircleAvatar(
            radius: _HomeScreenConstants.avatarRadius,
            backgroundColor: scheme.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              size: _HomeScreenConstants.avatarIconSize,
              color: scheme.onSurfaceVariant,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context, ColorScheme scheme) {
    return Consumer<FollowController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const SizedBox(
            width: 70,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final isFollowing = controller.isFollowing;

        return TextButton(
          onPressed: () {
            if (isFollowing) {
              controller.unfollow(post.authorId);
            } else {
              controller.follow(post.authorId);
            }
          },
          style: TextButton.styleFrom(
            backgroundColor: isFollowing
                ? scheme.surfaceContainerHighest
                : scheme.primary,
            foregroundColor: isFollowing
                ? scheme.onSurfaceVariant
                : scheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}

// ============================================================================
// ENGAGEMENT BAR - ✅ UPDATED: Shows Repics/Quotes list on count tap
// ============================================================================

class _EngagementBar extends StatelessWidget {
  final PostModel post;

  const _EngagementBar({required this.post});

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementController>();
    final currentPost = engagement.post;
    final scheme = Theme.of(context).colorScheme;
    final iconColor = scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: _HomeScreenConstants.engagementBarPaddingVertical,
        horizontal: _HomeScreenConstants.engagementBarPaddingHorizontal,
      ),
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

  // ✅ NEW: Show Engagement Lists Sheet (Repics + Quotes)
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

// ============================================================================
// ENGAGEMENT ACTION
// ============================================================================

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
          borderRadius: BorderRadius.circular(
            _HomeScreenConstants.iconButtonBorderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              color: color,
              size: _HomeScreenConstants.engagementIconSize,
            ),
          ),
        ),
        if (count > 0)
          GestureDetector(
            onTap: onCountTap,
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                _formatCount(count),
                style: TextStyle(
                  fontSize: _HomeScreenConstants.engagementCountSize,
                  fontWeight: _HomeScreenConstants.engagementCountFontWeight,
                  color: color,
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

// ============================================================================
// SUGGESTED USERS
// ============================================================================

class _SuggestedUsersSection extends StatelessWidget {
  const _SuggestedUsersSection();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: _HomeScreenConstants.suggestedUsersHeight,
      child: Center(
        child: Text(
          'Suggested users coming soon',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

// ============================================================================
// PROFILE BOTTOM SHEET
// ============================================================================

class _ProfileBottomSheet extends StatelessWidget {
  const _ProfileBottomSheet();

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height:
          MediaQuery.of(context).size.height *
          _HomeScreenConstants.sheetHeightFraction,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_HomeScreenConstants.sheetBorderRadius),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            value: themeController.isDarkMode,
            onChanged: (_) => themeController.toggleTheme(),
            title: Text('Dark Mode', style: TextStyle(color: scheme.onSurface)),
            secondary: Icon(
              themeController.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: scheme.error),
            title: Text('Logout', style: TextStyle(color: scheme.error)),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LOGOUT HANDLER
// ============================================================================

Future<void> _handleLogout(BuildContext context) async {
  final scheme = Theme.of(context).colorScheme;

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
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          child: const Text('Logout'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  await AuthService().logout();

  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }
}
