// ignore_for_file: use_build_context_synchronously

// ============================================================================
// HOME SCREEN V3 - REFACTORED (Industry Standard)
// ============================================================================
// Version: 3.1.0
// Last Updated: December 27, 2024
//
// FEATURES:
// ✅ Industry-standard variable organization
// ✅ Gazetteer/Verified badges in post headers
// ✅ Mutual badge support
// ✅ Multi-image carousel with vertical scrolling
// ✅ Quote posts with visual overlay design
// ✅ Repic posts with header attribution
// ✅ Real-time engagement (like, save, repic, quote, reply)
// ✅ Notification bell with badge in AppBar
// ============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 1: DART/FLUTTER IMPORTS
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 2: FIREBASE IMPORTS
// ─────────────────────────────────────────────────────────────────────────────
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 3: THIRD-PARTY PACKAGE IMPORTS
// ─────────────────────────────────────────────────────────────────────────────
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 4: CORE/SHARED IMPORTS
// ─────────────────────────────────────────────────────────────────────────────
import '../../core/theme/theme_controller.dart';
import 'package:e6piccturenew/features/common/widgets/gazetteer_badge.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 5: FEATURE IMPORTS - AUTH
// ─────────────────────────────────────────────────────────────────────────────
import '../auth/auth_gate.dart';
import '../auth/auth_service.dart';
import 'package:e6piccturenew/features/common/widgets/gazetteer_badge.dart';
import '../common/widgets/badges_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 6: FEATURE IMPORTS - FEED
// ─────────────────────────────────────────────────────────────────────────────
import '../feed/day_feed_controller.dart';
import '../feed/day_album_viewer_screen.dart';
import '../feed/day_album_tracker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 7: FEATURE IMPORTS - POST
// ─────────────────────────────────────────────────────────────────────────────
import '../post/create/post_model.dart';
import '../post/quote/quote_post_screen.dart';
import '../post/reply/reply_screen.dart';
import '../post/reply/replies_list_screen.dart';
import '../post/widgets/share_post_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 8: FEATURE IMPORTS - ENGAGEMENT
// ─────────────────────────────────────────────────────────────────────────────
import '../engagement/engagement_controller.dart';
import '../engagement/widgets/repic_header_widget.dart';
import '../engagement/engagement_lists_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 9: FEATURE IMPORTS - USER/PROFILE
// ─────────────────────────────────────────────────────────────────────────────
import '../user/user_avatar_controller.dart';
import '../profile/profile_entry.dart';
import '../follow/follow_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 10: FEATURE IMPORTS - NAVIGATION
// ─────────────────────────────────────────────────────────────────────────────
import '../search/search_screen.dart';
import '../search/search_controllers.dart';
import '../notifications/notifications_screen.dart';

// ============================================================================
// SECTION 11: CONSTANTS - ORGANIZED BY CATEGORY
// ============================================================================

/// Application-wide constants for HomeScreen and related widgets.
/// Organized by category for maintainability.
abstract class HomeScreenConstants {
  // ─────────────────────────────────────────────────────────────────────────
  // BRAND COLORS
  // ─────────────────────────────────────────────────────────────────────────
  static const Color brandAccent = Color(0xFF8B7355);
  static const Color verifiedBadgeColor = Color(0xFF1DA1F2);
  static const Color gazetteerBadgeColor = Color(0xFF2196F3);
  static const Color mutualBadgeColor = Color(0xFF4CAF50);

  // ─────────────────────────────────────────────────────────────────────────
  // PADDING VALUES
  // ─────────────────────────────────────────────────────────────────────────
  static const double paddingXS = 4.0;
  static const double paddingSM = 6.0;
  static const double paddingMD = 8.0;
  static const double paddingLG = 12.0;
  static const double paddingXL = 16.0;

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT-SPECIFIC PADDING
  // ─────────────────────────────────────────────────────────────────────────
  static const double cardMarginHorizontal = 6.0;
  static const double headerPaddingHorizontal = 12.0;
  static const double headerPaddingVertical = 8.0;
  static const double engagementBarPaddingVertical = 6.0;
  static const double engagementBarPaddingHorizontal = 8.0;

  // ─────────────────────────────────────────────────────────────────────────
  // ICON SIZES
  // ─────────────────────────────────────────────────────────────────────────
  static const double iconXS = 12.0;
  static const double iconSM = 14.0;
  static const double iconMD = 16.0;
  static const double iconLG = 22.0;
  static const double iconXL = 25.0;
  static const double iconXXL = 26.0;

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT-SPECIFIC ICON SIZES
  // ─────────────────────────────────────────────────────────────────────────
  static const double appBarIconSize = 26.0;
  static const double searchIconSize = 25.0;
  static const double pillIconSize = 14.0;
  static const double engagementIconSize = 22.0;
  static const double badgeIconSize = 14.0;
  static const double verifiedIconSize = 16.0;

  // ─────────────────────────────────────────────────────────────────────────
  // AVATAR SIZES
  // ─────────────────────────────────────────────────────────────────────────
  static const double avatarRadiusSM = 12.0;
  static const double avatarRadiusMD = 16.0;
  static const double avatarRadiusLG = 20.0;
  static const double avatarRadius = 16.0;
  static const double avatarIconSize = 16.0;

  // ─────────────────────────────────────────────────────────────────────────
  // LAYOUT DIMENSIONS
  // ─────────────────────────────────────────────────────────────────────────
  static const double carouselHeight = 520.0;
  static const double suggestedUsersHeight = 120.0;
  static const double sheetHeightFraction = 0.75;

  // ─────────────────────────────────────────────────────────────────────────
  // BORDER RADIUS VALUES
  // ─────────────────────────────────────────────────────────────────────────
  static const double borderRadiusSM = 8.0;
  static const double borderRadiusMD = 12.0;
  static const double borderRadiusLG = 16.0;
  static const double borderRadiusXL = 20.0;
  static const double borderRadiusXXL = 24.0;

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT-SPECIFIC BORDER RADIUS
  // ─────────────────────────────────────────────────────────────────────────
  static const double pillBorderRadius = 20.0;
  static const double cardBorderRadius = 12.0;
  static const double iconButtonBorderRadius = 20.0;
  static const double sheetBorderRadius = 24.0;
  static const double badgeBorderRadius = 12.0;

  // ─────────────────────────────────────────────────────────────────────────
  // BORDER WIDTHS
  // ─────────────────────────────────────────────────────────────────────────
  static const double pillBorderWidth = 0.5;
  static const double badgeBorderWidth = 1.0;

  // ─────────────────────────────────────────────────────────────────────────
  // VIEWPORT/SCROLL VALUES
  // ─────────────────────────────────────────────────────────────────────────
  static const double pageViewportFraction = 0.94;

  // ─────────────────────────────────────────────────────────────────────────
  // IMAGE CACHE SIZES
  // ─────────────────────────────────────────────────────────────────────────
  static const int maxCacheSize = 2048;
  static const int minCacheSize = 400;
  static const int defaultCacheSize = 400;
  static const int avatarCacheSize = 200;

  // ─────────────────────────────────────────────────────────────────────────
  // LOADING INDICATOR
  // ─────────────────────────────────────────────────────────────────────────
  static const double progressIndicatorStrokeWidth = 2.0;

  // ─────────────────────────────────────────────────────────────────────────
  // TYPOGRAPHY - SIZES
  // ─────────────────────────────────────────────────────────────────────────
  static const double fontSizeXS = 10.0;
  static const double fontSizeSM = 12.0;
  static const double fontSizeMD = 13.0;
  static const double fontSizeLG = 14.0;
  static const double fontSizeXL = 16.0;
  static const double fontSizeXXL = 20.0;

  // ─────────────────────────────────────────────────────────────────────────
  // TYPOGRAPHY - COMPONENT SPECIFIC
  // ─────────────────────────────────────────────────────────────────────────
  static const double appBarTitleSize = 20.0;
  static const double appBarLetterSpacing = 1.5;
  static const double pillTextSize = 12.5;
  static const double engagementCountSize = 12.0;
  static const double badgeTextSize = 10.0;

  // ─────────────────────────────────────────────────────────────────────────
  // TYPOGRAPHY - WEIGHTS
  // ─────────────────────────────────────────────────────────────────────────
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT-SPECIFIC FONT WEIGHTS
  // ─────────────────────────────────────────────────────────────────────────
  static const FontWeight appBarFontWeight = FontWeight.w800;
  static const FontWeight pillFontWeight = FontWeight.w600;
  static const FontWeight headerFontWeight = FontWeight.w600;
  static const FontWeight engagementCountFontWeight = FontWeight.w600;

  // ─────────────────────────────────────────────────────────────────────────
  // OPACITY VALUES
  // ─────────────────────────────────────────────────────────────────────────
  static const double opacityDisabled = 0.3;
  static const double opacityLight = 0.5;
  static const double opacityMedium = 0.7;
  static const double opacityHigh = 0.9;
}

// ============================================================================
// SECTION 12: BADGE WIDGETS
// ============================================================================

/// Verified badge (blue checkmark) for verified users
class VerifiedBadge extends StatelessWidget {
  final double size;

  const VerifiedBadge({
    super.key,
    this.size = HomeScreenConstants.verifiedIconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      size: size,
      color: HomeScreenConstants.verifiedBadgeColor,
    );
  }
}

/// ============================================================================
/// GAZETTEER STAMP BADGE LARGE - For profile pages
/// ============================================================================
class GazetteerStampBadgeLarge extends StatelessWidget {
  const GazetteerStampBadgeLarge({super.key});

  @override
  Widget build(BuildContext context) {
    const stampColor = Color(0xFF1565C0); // Deep blue ink

    return Transform.rotate(
      angle: -0.05, // Slight tilt like a real stamp
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: stampColor, width: 2.5),
          boxShadow: [
            // Ink bleed effect
            BoxShadow(
              color: stampColor.withValues(alpha: 0.15),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top decorative line
              Container(
                height: 1.5,
                color: stampColor,
                margin: const EdgeInsets.only(bottom: 4),
              ),

              // Main text with stars
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Left star
                  Icon(Icons.star, size: 10, color: stampColor),
                  const SizedBox(width: 6),

                  // GAZETTEER text
                  Text(
                    'GAZETTEER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: stampColor,
                      letterSpacing: 2.0,
                      fontFamily: 'monospace',
                    ),
                  ),

                  const SizedBox(width: 6),
                  // Right star
                  Icon(Icons.star, size: 10, color: stampColor),
                ],
              ),

              // "VERIFIED" subtitle
              Text(
                'VERIFIED',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  color: stampColor,
                  letterSpacing: 3.0,
                ),
              ),

              // Bottom decorative line
              Container(
                height: 1.5,
                color: stampColor,
                margin: const EdgeInsets.only(top: 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mutual badge for users who follow each other
class MutualBadge extends StatelessWidget {
  final double fontSize;

  const MutualBadge({
    super.key,
    this.fontSize = HomeScreenConstants.fontSizeSM,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '· Mutual',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: HomeScreenConstants.fontWeightMedium,
        color: HomeScreenConstants.mutualBadgeColor,
      ),
    );
  }
}

/// Row of user badges (Verified + Gazetteer)
/* class UserBadgeRow extends StatelessWidget {
  final bool isVerified;

  const UserBadgeRow({super.key, required this.isVerified});

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: HomeScreenConstants.paddingXS),
        const VerifiedBadge(size: HomeScreenConstants.verifiedIconSize),
      ],
    );
  }
} */

// ============================================================================
// SECTION 13: HOME SCREEN V3 MAIN WIDGET
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
              // Day Album Pill (X-style)
              if (albumStatus != null && albumStatus.hasUnseen)
                SliverToBoxAdapter(
                  child: _XStyleDayAlbumPill(
                    status: albumStatus,
                    onTap: feed.dismissAlbumPill,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Post Carousel
              SliverToBoxAdapter(
                child: _PostCarousel(
                  posts: state.posts,
                  isLoading: state.isLoading,
                  errorMessage: state.errorMessage,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Suggested Users
              const SliverToBoxAdapter(child: _SuggestedUsersSection()),

              // Extra padding for floating nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // APP BAR WITH NOTIFICATION BELL
  // ──────────────────────────────────────────────────────────────────────────
  AppBar _buildAppBar(BuildContext context, ColorScheme scheme) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return AppBar(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,

      // Leading: User Avatar
      leading: IconButton(
        icon: Icon(Icons.menu, color: scheme.onSurface),
        padding: const EdgeInsets.all(HomeScreenConstants.paddingLG),
        onPressed: () => _showProfileSheet(context),
      ),

      /*  leading: GestureDetector(
        onTap: () => _showProfileSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(HomeScreenConstants.paddingLG),
          child: uid != null
              ? ChangeNotifierProvider(
                  create: (_) => UserAvatarController(uid),
                  child: Consumer<UserAvatarController>(
                    builder: (_, controller, __) => CircleAvatar(
                      radius: HomeScreenConstants.avatarRadius,
                      backgroundColor: scheme.surfaceContainerHighest,
                      backgroundImage: controller.avatarUrl != null
                          ? NetworkImage(controller.avatarUrl!)
                          : null,
                      child: controller.avatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: HomeScreenConstants.avatarRadius,
                              color: scheme.onSurfaceVariant,
                            )
                          : null,
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: HomeScreenConstants.avatarRadius,
                  backgroundColor: scheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.person,
                    size: HomeScreenConstants.avatarRadius,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
        ),
      ), */

      // Title
      title: Text(
        'PICCTURE',
        style: TextStyle(
          fontWeight: HomeScreenConstants.appBarFontWeight,
          fontSize: HomeScreenConstants.appBarTitleSize,
          letterSpacing: HomeScreenConstants.appBarLetterSpacing,
          color: scheme.onSurface,
        ),
      ),
      centerTitle: true,

      // Actions: Search + Notifications
      actions: [
        // Search Icon
        IconButton(
          icon: Icon(
            Icons.search_rounded,
            size: HomeScreenConstants.searchIconSize,
            color: scheme.onSurface,
          ),
          onPressed: () => _openSearch(context),
        ),

        // Notification Bell with Badge
        if (uid != null)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('notifications')
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      unreadCount > 0
                          ? Icons.notifications
                          : Icons.notifications_outlined,
                      size: HomeScreenConstants.searchIconSize,
                      color: scheme.onSurface,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  // Badge
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        else
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              size: HomeScreenConstants.searchIconSize,
              color: scheme.onSurface,
            ),
            onPressed: () {},
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
// SECTION 14: DAY ALBUM PILL (X-Style)
// ============================================================================

class _XStyleDayAlbumPill extends StatelessWidget {
  final DayAlbumStatus status;
  final VoidCallback onTap;

  const _XStyleDayAlbumPill({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = HomeScreenConstants.brandAccent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: HomeScreenConstants.paddingXL,
          vertical: HomeScreenConstants.paddingMD,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: HomeScreenConstants.paddingLG,
          vertical: HomeScreenConstants.paddingMD,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            HomeScreenConstants.pillBorderRadius,
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: HomeScreenConstants.pillBorderWidth,
          ),
          color: color.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: HomeScreenConstants.pillIconSize,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              "${status.unseenCount} new today",
              style: TextStyle(
                color: color,
                fontSize: HomeScreenConstants.pillTextSize,
                fontWeight: HomeScreenConstants.pillFontWeight,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, size: 12, color: color),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION 15: POST CAROUSEL
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
            strokeWidth: HomeScreenConstants.progressIndicatorStrokeWidth,
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
                color: scheme.onSurfaceVariant.withValues(
                  alpha: HomeScreenConstants.opacityLight,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No pictures yet today',
                style: TextStyle(
                  fontSize: HomeScreenConstants.fontSizeXL,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back soon for new posts!',
                style: TextStyle(
                  fontSize: HomeScreenConstants.fontSizeLG,
                  color: scheme.onSurfaceVariant.withValues(
                    alpha: HomeScreenConstants.opacityMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: HomeScreenConstants.carouselHeight,
      child: PageView.builder(
        controller: PageController(
          viewportFraction: HomeScreenConstants.pageViewportFraction,
        ),
        itemCount: posts.length,
        itemBuilder: (_, i) =>
            _PostCard(post: posts[i], allPosts: posts, postIndex: i),
      ),
    );
  }
}

// ============================================================================
// SECTION 16: POST CARD
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
          horizontal: HomeScreenConstants.cardMarginHorizontal,
        ),
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            HomeScreenConstants.cardBorderRadius,
          ),
        ),
        child: Column(
          children: [
            // Repic Header (shows "User repicced" for repic posts)
            if (post.isRepic && post.repicAuthorId != null)
              RepicHeader(
                repicAuthorId: post.repicAuthorId!,
                repicAuthorName: post.repicAuthorName ?? 'User',
                repicAuthorHandle: post.repicAuthorHandle,
                repicAuthorAvatarUrl: post.repicAuthorAvatarUrl,
                repicAuthorIsVerified: post.repicAuthorIsVerified,
              ),

            // Post Header with Badges
            _PostHeader(post: post),

            // Main Image Viewer
            Expanded(
              child: _MultiImageViewer(
                post: post,
                allPosts: allPosts,
                postIndex: postIndex,
              ),
            ),

            // Engagement Bar
            _EngagementBar(post: post),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION 17: POST HEADER WITH BADGES
// ============================================================================

class _PostHeader extends StatelessWidget {
  final PostModel post;

  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOwner = FirebaseAuth.instance.currentUser?.uid == post.authorId;

    return ChangeNotifierProvider(
      create: (_) =>
          FollowController()..loadFollower(targetUserId: post.authorId),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HomeScreenConstants.headerPaddingHorizontal,
          vertical: HomeScreenConstants.headerPaddingVertical,
        ),
        child: Row(
          children: [
            // Tappable Author Info
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
                    // Avatar
                    _buildAuthorAvatar(context),
                    const SizedBox(width: 8),

                    // Name + Handle + Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ═══════════════════════════════════════════════════
                          // NAME ROW WITH VERIFIED BADGE
                          // ═══════════════════════════════════════════════════
                          Row(
                            children: [
                              // Author Name
                              Flexible(
                                child: Text(
                                  post.authorName.isNotEmpty
                                      ? post.authorName
                                      : 'Unknown',
                                  style: TextStyle(
                                    fontWeight:
                                        HomeScreenConstants.headerFontWeight,
                                    fontSize: HomeScreenConstants.fontSizeLG,
                                    color: scheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // ✅ GAZETTEER STAMP BADGE (for verified users)
                              if (post.authorIsVerified) ...[
                                const SizedBox(width: 6),
                                const GazetteerBadgeInline(height: 18),
                                //GazetteerStampBadgeInline(),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Follow Button (hidden for own posts)
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
              radius: HomeScreenConstants.avatarRadius,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: scheme.surfaceContainerHighest,
            );
          }

          return CircleAvatar(
            radius: HomeScreenConstants.avatarRadius,
            backgroundColor: scheme.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              size: HomeScreenConstants.avatarIconSize,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            backgroundColor: isFollowing
                ? scheme.surfaceContainerHighest
                : scheme.primary,
            foregroundColor: isFollowing
                ? scheme.onSurfaceVariant
                : scheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                HomeScreenConstants.borderRadiusLG,
              ),
            ),
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: const TextStyle(
              fontSize: HomeScreenConstants.fontSizeMD,
              fontWeight: HomeScreenConstants.fontWeightSemiBold,
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// SECTION 18: MULTI-IMAGE VIEWER
// ============================================================================

class _MultiImageViewer extends StatefulWidget {
  final PostModel post;
  final List<PostModel> allPosts;
  final int postIndex;

  const _MultiImageViewer({
    required this.post,
    required this.allPosts,
    required this.postIndex,
  });

  @override
  State<_MultiImageViewer> createState() => _MultiImageViewerState();
}

class _MultiImageViewerState extends State<_MultiImageViewer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    // For quote posts, show visual quote design
    if (post.isQuote && post.quotedPreview != null) {
      return _buildQuotePostContent(context, Theme.of(context).colorScheme);
    }

    // For repic posts, use original post's images
    final imageUrls = post.isRepic && post.originalImageUrls.isNotEmpty
        ? post.originalImageUrls
        : post.imageUrls;

    if (imageUrls.isEmpty) {
      return _buildNoImagePlaceholder(context);
    }

    // Single image
    if (imageUrls.length == 1) {
      return _buildTappableImage(context, imageUrls.first);
    }

    // Multiple images with vertical scrolling
    return Stack(
      children: [
        // Image PageView
        GestureDetector(
          onTap: () => _navigateToViewer(context),
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(
                HomeScreenConstants.cardBorderRadius,
              ),
              child: _buildOptimizedImage(context, imageUrls[i]),
            ),
          ),
        ),

        // Image numbering (1/10)
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_currentIndex + 1}/${imageUrls.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Vertical dots on the right
        Positioned(
          right: 12,
          top: 0,
          bottom: 0,
          child: Center(
            child: _VerticalImageDots(
              count: imageUrls.length,
              currentIndex: _currentIndex,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuotePostContent(BuildContext context, ColorScheme scheme) {
    final post = widget.post;
    final quotedPreview = post.quotedPreview;
    final commentary = post.commentary;

    final thumbnailUrl = quotedPreview?['thumbnailUrl'] as String?;
    final authorName = quotedPreview?['authorName'] as String? ?? 'Unknown';
    final authorHandle = quotedPreview?['authorHandle'] as String?;

    return GestureDetector(
      onTap: () => _navigateToViewer(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          HomeScreenConstants.cardBorderRadius,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: 800,
                errorBuilder: (_, __, ___) => _buildGradientPlaceholder(scheme),
              )
            else
              _buildGradientPlaceholder(scheme),

            // Quote Overlay (Top)
            if (commentary != null && commentary.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          commentary.length > 30
                              ? '${commentary.substring(0, 30)}...'
                              : commentary,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Original Poster Badge (Bottom-right)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_outlined,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      authorHandle != null ? '@$authorHandle' : authorName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quote Badge (Top-right)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.repeat, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Quote',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientPlaceholder(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.format_quote_rounded,
          size: 80,
          color: scheme.onPrimaryContainer.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildTappableImage(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () => _navigateToViewer(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          HomeScreenConstants.cardBorderRadius,
        ),
        child: _buildOptimizedImage(context, imageUrl),
      ),
    );
  }

  Widget _buildNoImagePlaceholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          HomeScreenConstants.cardBorderRadius,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
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
            : HomeScreenConstants.defaultCacheSize.toDouble();

        var cacheWidth = (width * pixelRatio).toInt();

        if (cacheWidth > HomeScreenConstants.maxCacheSize) {
          cacheWidth = HomeScreenConstants.maxCacheSize;
        }
        if (cacheWidth < HomeScreenConstants.minCacheSize) {
          cacheWidth = HomeScreenConstants.minCacheSize;
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
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: HomeScreenConstants.progressIndicatorStrokeWidth,
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            color: scheme.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }

  void _navigateToViewer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DayAlbumViewerScreen(
          posts: widget.allPosts,
          sessionStartedAt: DateTime.now(),
          initialIndex: widget.postIndex,
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION 19: VERTICAL IMAGE DOTS
// ============================================================================

class _VerticalImageDots extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _VerticalImageDots({required this.count, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (index) {
          final isActive = index == currentIndex;
          return Container(
            width: 6,
            height: isActive ? 16 : 6,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================================
// SECTION 20: ENGAGEMENT BAR
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
        vertical: HomeScreenConstants.engagementBarPaddingVertical,
        horizontal: HomeScreenConstants.engagementBarPaddingHorizontal,
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
          /*   _EngagementAction(
            icon: Icons.chat_bubble_outline,
            color: iconColor,
            count: currentPost.replyCount,
            onPressed: () => _navigateToReply(context, currentPost),
            onCountTap: currentPost.replyCount > 0
                ? () => _navigateToRepliesList(context, currentPost)
                : null,
          ), */

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

          // REPIC
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

          // SHARE
          _EngagementAction(
            icon: Icons.share_outlined,
            color: iconColor,
            count: 0,
            showCount: false,
            onPressed: () {
              SharePostSheet.show(
                context,
                postId: currentPost.postId,
                postUrl: 'https://piccture.app/post/${currentPost.postId}',
                imageUrl: currentPost.imageUrls.isNotEmpty
                    ? currentPost.imageUrls.first
                    : null,
                caption: currentPost.caption,
                authorName: currentPost.authorName,
              );
            },
            onCountTap: null,
          ),
        ],
      ),
    );
  }

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
// SECTION 21: ENGAGEMENT ACTION BUTTON
// ============================================================================

class _EngagementAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final bool showCount;
  final VoidCallback? onPressed;
  final VoidCallback? onCountTap;

  const _EngagementAction({
    required this.icon,
    required this.color,
    required this.count,
    this.showCount = true,
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
            HomeScreenConstants.iconButtonBorderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              color: color,
              size: HomeScreenConstants.engagementIconSize,
            ),
          ),
        ),
        if (showCount && count > 0)
          GestureDetector(
            onTap: onCountTap,
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                _formatCount(count),
                style: TextStyle(
                  fontSize: HomeScreenConstants.engagementCountSize,
                  fontWeight: HomeScreenConstants.engagementCountFontWeight,
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
// SECTION 22: SUGGESTED USERS SECTION
// ============================================================================

class _SuggestedUsersSection extends StatelessWidget {
  const _SuggestedUsersSection();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeScreenConstants.paddingXL,
          ),
          child: Text(
            'Suggested for you',
            style: TextStyle(
              fontSize: HomeScreenConstants.fontSizeXL,
              fontWeight: HomeScreenConstants.fontWeightSemiBold,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: HomeScreenConstants.suggestedUsersHeight,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('__name__', isNotEqualTo: uid)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data?.docs ?? [];

              if (users.isEmpty) {
                return Center(
                  child: Text(
                    'No suggestions yet',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeScreenConstants.paddingXL,
                ),
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final userData = users[i].data() as Map<String, dynamic>;
                  final userId = users[i].id;

                  return _SuggestedUserCard(
                    userId: userId,
                    displayName: userData['displayName'] ?? 'User',
                    handle: userData['handle'] ?? userData['username'],
                    avatarUrl:
                        userData['profileImageUrl'] ?? userData['photoUrl'],
                    isVerified: userData['isVerified'] ?? false,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SECTION 23: SUGGESTED USER CARD
// ============================================================================

class _SuggestedUserCard extends StatelessWidget {
  final String userId;
  final String displayName;
  final String? handle;
  final String? avatarUrl;
  final bool isVerified;

  const _SuggestedUserCard({
    required this.userId,
    required this.displayName,
    this.handle,
    this.avatarUrl,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileEntry(userId: userId)),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(HomeScreenConstants.paddingMD),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(
            HomeScreenConstants.borderRadiusMD,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: HomeScreenConstants.avatarRadiusLG,
              backgroundColor: scheme.surfaceContainerHighest,
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? Icon(Icons.person, color: scheme.onSurfaceVariant)
                  : null,
            ),
            const SizedBox(height: 8),

            // Name with Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: HomeScreenConstants.fontSizeSM,
                      fontWeight: HomeScreenConstants.fontWeightSemiBold,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                if (isVerified) ...[
                  const SizedBox(width: 6),
                  const GazetteerBadge(size: 20),
                ],
              ],
            ),

            // Handle
            if (handle != null)
              Text(
                '@$handle',
                style: TextStyle(
                  fontSize: HomeScreenConstants.fontSizeXS,
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION 24: PROFILE BOTTOM SHEET
// ============================================================================

class _ProfileBottomSheet extends StatelessWidget {
  const _ProfileBottomSheet();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(HomeScreenConstants.sheetBorderRadius),
            ),
          ),
          child: StreamBuilder<DocumentSnapshot>(
            stream: user != null
                ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots()
                : null,
            builder: (context, snapshot) {
              final userData =
                  snapshot.data?.data() as Map<String, dynamic>? ?? {};

              final displayName =
                  userData['displayName'] ?? user?.displayName ?? 'User';
              final handle = userData['handle'] ?? userData['username'];
              final avatarUrl =
                  userData['profileImageUrl'] ?? userData['photoUrl'];

              final isAdmin = userData['isAdmin'] == true;
              final isVerified = userData['isVerified'] == true;

              final followersCount = userData['followersCount'] ?? 0;
              final followingCount = userData['followingCount'] ?? 0;
              final mutualsCount = userData['mutualsCount'] ?? 0;

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  // ═══════════════════════════════════════════════════════════
                  // DRAG HANDLE
                  // ═══════════════════════════════════════════════════════════
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // ═══════════════════════════════════════════════════════════
                  // PROFILE CARD (Gradient, Tappable)
                  // ═══════════════════════════════════════════════════════════
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileEntry(userId: user!.uid),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primaryContainer.withOpacity(0.4),
                            scheme.secondaryContainer.withOpacity(0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: scheme.surfaceContainerHighest,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 32,
                                    color: scheme.onSurfaceVariant,
                                  )
                                : null,
                          ),

                          const SizedBox(width: 16),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name + Verified
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayName,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: scheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isVerified) ...[
                                      const SizedBox(width: 6),
                                      const VerifiedBadge(size: 18),
                                    ],
                                  ],
                                ),

                                // Handle
                                if (handle != null)
                                  Text(
                                    '@$handle',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),

                                const SizedBox(height: 10),

                                // Stats Row
                                Row(
                                  children: [
                                    _buildStatColumn(
                                      followersCount,
                                      'Followers',
                                      scheme,
                                    ),
                                    const SizedBox(width: 16),
                                    _buildStatColumn(
                                      followingCount,
                                      'Following',
                                      scheme,
                                    ),
                                    const SizedBox(width: 16),
                                    _buildStatColumn(
                                      mutualsCount,
                                      'Mutuals',
                                      scheme,
                                      highlight: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Chevron
                          Icon(
                            Icons.chevron_right,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════════════════════════
                  // QUICK ACTIONS ROW
                  // ═══════════════════════════════════════════════════════════
                  Row(
                    children: [
                      _buildQuickAction(
                        context,
                        Icons.edit_outlined,
                        'Edit',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileEntry(userId: user!.uid),
                            ),
                          );
                        },
                        scheme,
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        context,
                        Icons.bookmark_outline,
                        'Saved',
                        () {
                          Navigator.pop(context);
                          // Navigate to saved posts
                        },
                        scheme,
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        context,
                        Icons.share_outlined,
                        'Share',
                        () {
                          // Share profile
                        },
                        scheme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // ACCOUNT SECTION
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader('ACCOUNT', scheme),
                  const SizedBox(height: 8),
                  _buildMenuGroup(scheme, [
                    _buildMenuTile(
                      Icons.person_outline,
                      'View Profile',
                      scheme,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileEntry(userId: user!.uid),
                          ),
                        );
                      },
                    ),
                    if (!isVerified)
                      _buildMenuTile(
                        Icons.verified_outlined,
                        'Request Verification',
                        scheme,
                        () {
                          Navigator.pop(context);
                          _showVerificationDialog(
                            context,
                            user!.uid,
                            displayName,
                          );
                        },
                        iconColor: Colors.blue,
                      ),
                    if (isAdmin)
                      _buildMenuTile(
                        Icons.admin_panel_settings,
                        'Admin Dashboard',
                        scheme,
                        () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/admin');
                        },
                        iconColor: Colors.purple,
                      ),
                  ]),

                  const SizedBox(height: 16),

                  // ═══════════════════════════════════════════════════════════
                  // PRIVACY SECTION
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader('PRIVACY', scheme),
                  const SizedBox(height: 8),
                  _buildMenuGroup(scheme, [
                    _buildMenuTile(
                      Icons.block_outlined,
                      'Blocked Accounts',
                      scheme,
                      () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/blocked');
                      },
                    ),
                    _buildMenuTile(
                      Icons.volume_off_outlined,
                      'Muted Accounts',
                      scheme,
                      () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/muted');
                      },
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ═══════════════════════════════════════════════════════════
                  // PREFERENCES SECTION
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader('PREFERENCES', scheme),
                  const SizedBox(height: 8),
                  _buildMenuGroup(scheme, [
                    // Settings
                    _buildMenuTile(
                      Icons.settings_outlined,
                      'Settings',
                      scheme,
                      () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                    // Theme Toggle
                    Consumer<ThemeController>(
                      builder: (_, controller, __) => _buildMenuTile(
                        controller.isDarkMode
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        controller.isDarkMode ? 'Light Mode' : 'Dark Mode',
                        scheme,
                        () => controller.toggleTheme(),
                        trailing: Switch.adaptive(
                          value: controller.isDarkMode,
                          onChanged: (_) => controller.toggleTheme(),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ═══════════════════════════════════════════════════════════
                  // SUPPORT SECTION
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader('SUPPORT', scheme),
                  const SizedBox(height: 8),
                  _buildMenuGroup(scheme, [
                    _buildMenuTile(
                      Icons.help_outline,
                      'Help & Support',
                      scheme,
                      () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildMenuTile(
                      Icons.info_outline,
                      'About Piccture',
                      scheme,
                      () {
                        Navigator.pop(context);
                        _showAboutDialog(context);
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // LOGOUT BUTTON
                  // ═══════════════════════════════════════════════════════════
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.error.withOpacity(0.3)),
                    ),
                    child: InkWell(
                      onTap: () => _handleLogout(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 20, color: scheme.error),
                            const SizedBox(width: 8),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: scheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER: Stat Column
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatColumn(
    int value,
    String label,
    ColorScheme scheme, {
    bool highlight = false,
  }) {
    String formatted;
    if (value >= 1000000) {
      formatted = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      formatted = '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      formatted = value.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatted,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: highlight
                ? HomeScreenConstants.mutualBadgeColor
                : scheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER: Quick Action Button
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
    ColorScheme scheme,
  ) {
    return Expanded(
      child: Material(
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, size: 24, color: scheme.onSurface),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER: Section Header
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER: Menu Group Container
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMenuGroup(ColorScheme scheme, List<Widget> children) {
    final filteredChildren = children.where((c) => c is! SizedBox).toList();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: filteredChildren.asMap().entries.map((entry) {
          final isLast = entry.key == filteredChildren.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 52,
                  color: scheme.outlineVariant.withOpacity(0.3),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER: Menu Tile
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMenuTile(
    IconData icon,
    String label,
    ColorScheme scheme,
    VoidCallback onTap, {
    Color? iconColor,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (iconColor ?? scheme.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor ?? scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VERIFICATION DIALOG
  // ─────────────────────────────────────────────────────────────────────────
  void _showVerificationDialog(
    BuildContext context,
    String uid,
    String displayName,
  ) {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.verified, color: Colors.blue.shade400),
            const SizedBox(width: 8),
            const Text('Request Verification'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gazetteer badges are for:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• Photographers & content creators'),
            const Text('• Journalists & reporters'),
            const Text('• Notable public figures'),
            const SizedBox(height: 16),
            Text(
              'Requirements:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• 30+ days account age'),
            const Text('• 10+ original posts'),
            const Text('• 100+ followers'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Submit'),
            onPressed: () async {
              Navigator.pop(ctx);
              await _submitVerificationRequest(context, uid, displayName);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitVerificationRequest(
    BuildContext context,
    String uid,
    String displayName,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('verification_requests').add({
        'userId': uid,
        'userName': displayName,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Verification request submitted!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Piccture',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: HomeScreenConstants.brandAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
      children: const [
        Text('Share your world through pictures.'),
        SizedBox(height: 8),
        Text('© 2024 Piccture'),
      ],
    );
  }
}

class _InlineStat extends StatelessWidget {
  final String label;
  final int value;
  final ColorScheme scheme;

  const _InlineStat({
    required this.label,
    required this.value,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ============================================================================
// SECTION 25: SHEET MENU ITEM
// ============================================================================

class _SheetMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SheetMenuItem({
    required this.icon,
    required this.label,
    this.iconColor,
    this.textColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: iconColor ?? scheme.primary),
      title: Text(
        label,
        style: TextStyle(
          color: textColor ?? scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          trailing ??
          Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

// ============================================================================
// SECTION 26: LOGOUT HANDLER
// ============================================================================

Future<void> _handleLogout(BuildContext context) async {
  final scheme = Theme.of(context).colorScheme;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Log Out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: const Text('Log Out'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  if (context.mounted) {
    Navigator.pop(context);
  }

  await AuthService().logout();

  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }
}
