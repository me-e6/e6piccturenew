/* import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile_controller.dart';
import '../grids/pictters_grid.dart';
import '../grids/repics_grid.dart';
import '../grids/quotes_grid.dart';
import '../grids/saved_grid.dart';
import '../profile_feed_viewer.dart';

class ProfileTabContent extends StatelessWidget {
  const ProfileTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final selectedTab = controller.selectedTab;

    if (controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    void openFeed(List posts, int index) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProfileFeedViewer(posts: posts.cast(), initialIndex: index),
        ),
      );
    }

    Widget content;

    switch (selectedTab) {
      // ---------------- PICTURES ----------------
      case 0:
        content = PicturesGrid(
          posts: controller.posts,
          onPostTap: (post, index) {
            openFeed(controller.posts, index);
          },
        );
        break;

      // ---------------- REPICS ----------------
      case 1:
        content = RepicsGrid(
          posts: controller.repics,
          onPostTap: (repics, index) {
            openFeed(controller.repics, index);
          },
        );
        break;

      // ---------------- QUOTES ----------------
      case 2:
        content = QuotesGrid(
          posts: controller.quotes,
          onPostTap: (quotes, index) {
            openFeed(controller.quotes, index);
          },
        );
        break;

      // ---------------- SAVED ----------------
      case 3:
        content = SavedGrid(
          posts: controller.saved,
          onPostTap: (saved, index) {
            openFeed(controller.saved, index);
          },
        );
        break;

      default:
        content = const SizedBox.shrink();
    }

    /// SINGLE SCROLL CONTAINER (prevents unbounded height)
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(children: [content, const SizedBox(height: 32)]),
    );
  }
}
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile_controller.dart';
import '../grids/pictters_grid.dart';
import '../grids/repics_grid.dart';
import '../grids/quotes_grid.dart';
import '../grids/saved_grid.dart';
import '../profile_feed_viewer.dart';

class ProfileTabContent extends StatelessWidget {
  const ProfileTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();

    if (controller.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    void openFeed(List posts, int index) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProfileFeedViewer(posts: posts.cast(), initialIndex: index),
        ),
      );
    }

    switch (controller.selectedTab) {
      case 0:
        return PicturesGrid(
          posts: controller.posts,
          onPostTap: (_, index) => openFeed(controller.posts, index),
        );

      case 1:
        return RepicsGrid(
          posts: controller.repics,
          onPostTap: (_, index) => openFeed(controller.repics, index),
        );

      case 2:
        return QuotesGrid(
          posts: controller.quotes,
          onPostTap: (_, index) => openFeed(controller.quotes, index),
        );

      case 3:
        return SavedGrid(
          posts: controller.saved,
          onPostTap: (_, index) => openFeed(controller.saved, index),
        );

      default:
        return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }
}
