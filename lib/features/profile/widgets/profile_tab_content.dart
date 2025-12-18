import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile_controller.dart';
import '../../post/create/post_model.dart';
import 'repic_grid_tile.dart';
import 'impact_grid_tile.dart';

class ProfileTabContent extends StatelessWidget {
  const ProfileTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();

    switch (controller.selectedTab) {
      case 0:
        return _PostsGrid(posts: controller.posts);

      case 1: // Repics
        if (controller.reposts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Text('No repics yet'),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: controller.reposts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemBuilder: (_, index) {
            return RepicGridTile(post: controller.reposts[index]);
          },
        );
      case 2:
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: controller.impactPosts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemBuilder: (_, index) {
            return ImpactGridTile(post: controller.impactPosts[index]);
          },
        );

      case 3:
        return _PostsGrid(posts: controller.saved);

      default:
        return const SizedBox.shrink();
    }
  }
}

/// ------------------------------------------------------------
/// POSTS GRID (REUSABLE)
/// ------------------------------------------------------------
class _PostsGrid extends StatelessWidget {
  final List<PostModel> posts;

  const _PostsGrid({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('Nothing here yet', textAlign: TextAlign.center),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      /*  itemBuilder: (_, index) {
        final post = posts[index];

        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: post.imageUrls.isNotEmpty
              ? Image.network(post.imageUrls.first, fit: BoxFit.cover)
              : Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image),
                ),
        );
      },
    );
  }
} */
      itemBuilder: (_, index) {
        final post = posts[index];

        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              post.imageUrls.isNotEmpty
                  ? Image.network(post.imageUrls.first, fit: BoxFit.cover)
                  : Container(color: Colors.grey.shade300),

              /// Repic badge
              if (post.isRepost)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.repeat,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// ------------------------------------------------------------
/// IMPACT PLACEHOLDER (API-SAFE)
/// ------------------------------------------------------------
class _ImpactPlaceholder extends StatelessWidget {
  const _ImpactPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        'Impact pictures coming soon',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
