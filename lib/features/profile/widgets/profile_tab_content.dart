import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../post/create/post_model.dart';
import '../profile_controller.dart';
import '../grids/pictters_grid.dart';
import '../grids/repics_grid.dart';
import '../grids/quotes_grid.dart';
import '../grids/saved_grid.dart';
import '../profile_feed_viewer.dart';

/// ============================================================================
/// PROFILE TAB CONTENT
/// ============================================================================
/// Renders the appropriate grid based on selected tab.
///
/// Tabs:
/// - 0: Pictures (user's posts)
/// - 1: Repics (posts user repicced)
/// - 2: Quotes (quote posts by user)
/// - 3: Saved (bookmarked posts - owner only)
/// ============================================================================
class ProfileTabContent extends StatelessWidget {
  const ProfileTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();

    // Loading state
    if (controller.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    /// Opens feed viewer at tapped index
    void openFeed(List<PostModel> posts, int index) {
      if (posts.isEmpty) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileFeedViewer(posts: posts, initialIndex: index),
        ),
      );
    }

    switch (controller.selectedTab) {
      // ------------------------------------------------------------------
      // TAB 0: PICTURES (User's own posts)
      // ------------------------------------------------------------------
      case 0:
        return PicturesGrid(
          posts: controller.posts,
          onPostTap: (_, index) => openFeed(controller.posts, index),
        );

      // ------------------------------------------------------------------
      // TAB 1: REPICS (Posts user has repicced)
      // ------------------------------------------------------------------
      case 1:
        return RepicsGrid(
          posts: controller.repics,
          onPostTap: (_, index) => openFeed(controller.repics, index),
        );

      // ------------------------------------------------------------------
      // TAB 2: QUOTES (Quote posts authored by user)
      // ------------------------------------------------------------------
      case 2:
        return QuotesGrid(
          posts: controller.quotes,
          onPostTap: (_, index) => openFeed(controller.quotes, index),
        );

      // ------------------------------------------------------------------
      // TAB 3: SAVED (Bookmarked posts - owner only)
      // ------------------------------------------------------------------
      case 3:
        return SavedGrid(
          posts: controller.saved,
          isOwner: controller.isOwner,
          onPostTap: (_, index) => openFeed(controller.saved, index),
        );

      // ------------------------------------------------------------------
      // DEFAULT: Pictures
      // ------------------------------------------------------------------
      default:
        return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }
}
