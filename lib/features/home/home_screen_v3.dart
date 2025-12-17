/* import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../feed/day_feed_controller.dart';
import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';
import '../feed/day_album_viewer_screen.dart';

/// ---------------------------------------------------------------------------
/// HOME SCREEN V3
/// ---------------------------------------------------------------------------
/// - Assumes DayFeedController is PROVIDED from above (MainNavigation)
/// - Does NOT create its own controller
/// - Reacts to banner + feed state only
class HomeScreenV3 extends StatelessWidget {
  const HomeScreenV3({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DayFeedController>();
    final state = controller.state;

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top -
                  kBottomNavigationBarHeight,
              child: Column(
                children: [
                  _DayAlbumBanner(
                    count: controller.totalPostCount,
                    hasNewPosts: state.hasNewPosts,
                  ),
                  const SizedBox(height: 12),

                  /// PRIMARY — DAY FEED
                  Expanded(
                    child: _PostCarousel(
                      posts: state.posts,
                      isLoading: state.isLoading,
                      errorMessage: state.errorMessage,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// SECONDARY — SUGGESTED USERS
                  const _SuggestedUsersSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
      title: const Text(
        'PICCTURE',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// DAY ALBUM BANNER
/// ---------------------------------------------------------------------------
class _DayAlbumBanner extends StatelessWidget {
  final int count;
  final bool hasNewPosts;

  const _DayAlbumBanner({required this.count, required this.hasNewPosts});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.photo_library_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasNewPosts
                  ? 'New pictures available'
                  : 'You have $count pictures to review in the last 24 hours.',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {
              final controller = context.read<DayFeedController>();
              controller.markBannerSeen();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DayAlbumViewerScreen(
                    posts: controller.state.posts,
                    sessionStartedAt: controller.state.sessionStartedAt,
                  ),
                ),
              );
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST CAROUSEL (POST-LEVEL PAGEVIEW)
/// ---------------------------------------------------------------------------
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (errorMessage != null) {
      return Center(
        child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (posts.isEmpty) {
      return const Center(child: Text('No pictures yet today'));
    }

    return PageView.builder(
      controller: PageController(viewportFraction: 0.95),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return ChangeNotifierProvider(
          create: (_) => EngagementController(),
          child: _PostCard(post: posts[index]),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST CARD (IMAGE-LEVEL PAGEVIEW + ENGAGEMENT)
/// ---------------------------------------------------------------------------
class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          /// FLEXIBLE IMAGE AREA
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PageView.builder(
                itemCount: post.imageUrls.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    post.imageUrls[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Center(child: Icon(Icons.broken_image)),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          /// ENGAGEMENT BAR
          _EngagementBar(post: post),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// ENGAGEMENT BAR
/// ---------------------------------------------------------------------------
class _EngagementBar extends StatelessWidget {
  final PostModel post;

  const _EngagementBar({required this.post});

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            post.hasLiked ? Icons.favorite : Icons.favorite_border,
            color: post.hasLiked ? Colors.red : null,
          ),
          onPressed: () {
            post.hasLiked
                ? engagement.dislikePost(post)
                : engagement.likePost(post);
          },
        ),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () {},
        ),
        IconButton(icon: const Icon(Icons.repeat), onPressed: () {}),
        IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        IconButton(
          icon: Icon(post.hasSaved ? Icons.bookmark : Icons.bookmark_border),
          onPressed: () {
            engagement.savePost(post);
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () {
            engagement.sharePost(post);
          },
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// SUGGESTED USERS (SECONDARY)
/// ---------------------------------------------------------------------------
class _SuggestedUsersSection extends StatelessWidget {
  const _SuggestedUsersSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Suggested for You',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('User')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../feed/day_feed_controller.dart';
import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';
import '../feed/day_album_viewer_screen.dart';

/// ---------------------------------------------------------------------------
/// HOME SCREEN V3
/// ---------------------------------------------------------------------------
/// - Assumes DayFeedController is PROVIDED from above (MainNavigation)
/// - Does NOT create its own controller
/// - Reacts to banner + feed state only
class HomeScreenV3 extends StatelessWidget {
  const HomeScreenV3({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DayFeedController>();
    final state = controller.state;

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top -
                  kBottomNavigationBarHeight,
              child: Column(
                children: [
                  _DayAlbumBanner(
                    count: controller.totalPostCount,
                    hasNewPosts: state.hasNewPosts,
                  ),
                  const SizedBox(height: 12),

                  /// PRIMARY — DAY FEED
                  Expanded(
                    child: _PostCarousel(
                      posts: state.posts,
                      isLoading: state.isLoading,
                      errorMessage: state.errorMessage,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// SECONDARY — SUGGESTED USERS
                  const _SuggestedUsersSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
      title: const Text(
        'PICCTURE',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// DAY ALBUM BANNER
/// ---------------------------------------------------------------------------
class _DayAlbumBanner extends StatelessWidget {
  final int count;
  final bool hasNewPosts;

  const _DayAlbumBanner({required this.count, required this.hasNewPosts});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.photo_library_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasNewPosts
                  ? 'New pictures available'
                  : 'You have $count pictures to review in the last 24 hours.',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {
              final controller = context.read<DayFeedController>();
              controller.markBannerSeen();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DayAlbumViewerScreen(
                    posts: controller.state.posts,
                    sessionStartedAt: controller.state.sessionStartedAt,
                  ),
                ),
              );
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST CAROUSEL (POST-LEVEL PAGEVIEW)
/// ---------------------------------------------------------------------------
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (errorMessage != null) {
      return Center(
        child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (posts.isEmpty) {
      return const Center(child: Text('No pictures yet today'));
    }

    return PageView.builder(
      controller: PageController(viewportFraction: 0.95),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return ChangeNotifierProvider(
          create: (_) => EngagementController(),
          child: _PostCard(
            post: posts[index],
            postIndex: index,
            allPosts: posts,
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST CARD (IMAGE-LEVEL PAGEVIEW + ENGAGEMENT + LONG PRESS)
/// ---------------------------------------------------------------------------
class _PostCard extends StatelessWidget {
  final PostModel post;
  final int postIndex;
  final List<PostModel> allPosts;

  const _PostCard({
    required this.post,
    required this.postIndex,
    required this.allPosts,
  });

  @override
  Widget build(BuildContext context) {
    final feedController = context.read<DayFeedController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DayAlbumViewerScreen(
                posts: allPosts,
                sessionStartedAt: feedController.state.sessionStartedAt,
                initialIndex: postIndex,
              ),
            ),
          );
        },
        child: Column(
          children: [
            /// IMAGE AREA
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PageView.builder(
                  itemCount: post.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      post.imageUrls[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Center(child: Icon(Icons.broken_image)),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            _EngagementBar(post: post),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// ENGAGEMENT BAR
/// ---------------------------------------------------------------------------
class _EngagementBar extends StatelessWidget {
  final PostModel post;

  const _EngagementBar({required this.post});

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            post.hasLiked ? Icons.favorite : Icons.favorite_border,
            color: post.hasLiked ? Colors.red : null,
          ),
          onPressed: () {
            post.hasLiked
                ? engagement.dislikePost(post)
                : engagement.likePost(post);
          },
        ),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () {},
        ),
        IconButton(icon: const Icon(Icons.repeat), onPressed: () {}),
        IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        IconButton(
          icon: Icon(post.hasSaved ? Icons.bookmark : Icons.bookmark_border),
          onPressed: () => engagement.savePost(post),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () => engagement.sharePost(post),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// SUGGESTED USERS (SECONDARY)
/// ---------------------------------------------------------------------------
class _SuggestedUsersSection extends StatelessWidget {
  const _SuggestedUsersSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Suggested for You',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('User')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
