import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../feed/day_feed_controller.dart';
import '../feed/day_feed_service.dart';
import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';
import '../feed/day_album_viewer_screen.dart';

class HomeScreenV3 extends StatelessWidget {
  const HomeScreenV3({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DayFeedController(DayFeedService())..init(),
      child: const _HomeScreenV3Body(),
    );
  }
}

class _HomeScreenV3Body extends StatelessWidget {
  const _HomeScreenV3Body();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DayFeedController>();
    final state = controller.state;

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () {
            return context.read<DayFeedController>().refresh();
          },
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

      bottomNavigationBar: const _BottomNavBar(),
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

/* class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: PageView.builder(
              itemCount: post.imageUrls.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.imageUrls[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _EngagementBar(post: post), // 👈 IMPORTANT
        ],
      ),
    );
  }
} */
class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          /// FLEXIBLE IMAGE AREA (THIS FIXES OVERFLOW)
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

          /// FIXED HEIGHT — ALWAYS VISIBLE
          _EngagementBar(post: post),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// ENGAGEMENT BAR (POST-SCOPED, REACTIVE)
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
        /// LIKE / UNLIKE
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

        /// COMMENT (STUB)
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () {},
        ),

        /// RE-PIC (STUB)
        IconButton(icon: const Icon(Icons.repeat), onPressed: () {}),

        /// QUOTE (STUB)
        IconButton(icon: const Icon(Icons.edit), onPressed: () {}),

        /// SAVE / UNSAVE
        IconButton(
          icon: Icon(post.hasSaved ? Icons.bookmark : Icons.bookmark_border),
          onPressed: () {
            engagement.savePost(post);
          },
        ),

        /// SHARE
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
/// SUGGESTED USERS
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

/// ---------------------------------------------------------------------------
/// BOTTOM NAVIGATION BAR
/// ---------------------------------------------------------------------------

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      onTap: (_) {},
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Pictures'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
