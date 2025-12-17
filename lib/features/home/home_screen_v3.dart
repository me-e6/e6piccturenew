import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../feed/day_feed_controller.dart';
import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';
import '../follow/follow_controller.dart';
import '../feed/day_album_viewer_screen.dart';

/// ---------------------------------------------------------------------------
/// HOME SCREEN V3
/// ---------------------------------------------------------------------------
/// - DayFeedController is PROVIDED from MainNavigation
/// - PostCard scopes FollowController + EngagementController per post
class HomeScreenV3 extends StatelessWidget {
  const HomeScreenV3({super.key});

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<DayFeedController>();
    final state = feed.state;

    return Scaffold(
      appBar: AppBar(
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
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: feed.refresh,
          child: Column(
            children: [
              const SizedBox(height: 8),

              _DayAlbumBanner(
                count: feed.totalPostCount,
                hasNewPosts: state.hasNewPosts,
              ),

              const SizedBox(height: 12),

              Expanded(
                child: _PostCarousel(
                  posts: state.posts,
                  isLoading: state.isLoading,
                  errorMessage: state.errorMessage,
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
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
                  : 'You have $count pictures to review today',
            ),
          ),
          TextButton(
            onPressed: () {
              final feed = context.read<DayFeedController>();
              feed.markBannerSeen();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DayAlbumViewerScreen(
                    posts: feed.state.posts,
                    sessionStartedAt: feed.state.sessionStartedAt,
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
/// POST CAROUSEL
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
      controller: PageController(viewportFraction: 0.96),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => EngagementController()),
            ChangeNotifierProvider(
              create: (_) => FollowController()..load(post.authorId),
            ),
          ],
          child: PostCard(post: post),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST CARD (STABLE)
/// ---------------------------------------------------------------------------
class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int _imageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(post: post),
          const SizedBox(height: 8),

          _PostMedia(
            images: post.imageUrls,
            onChanged: (i) => setState(() => _imageIndex = i),
          ),

          if (post.imageUrls.length > 1)
            _ImageDots(count: post.imageUrls.length, index: _imageIndex),

          const SizedBox(height: 4),
          _EngagementBar(post: post),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST HEADER
/// ---------------------------------------------------------------------------
class _PostHeader extends StatelessWidget {
  final PostModel post;

  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final follow = context.watch<FollowController>();

    return Row(
      children: [
        const CircleAvatar(radius: 16),
        const SizedBox(width: 8),

        Expanded(
          child: Text(
            post.authorName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        TextButton(
          onPressed: follow.isLoading
              ? null
              : () {
                  follow.isFollowing
                      ? follow.follow(post.authorId)
                      : follow.unfollow(post.authorId);
                },
          child: follow.isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  follow.isFollowing ? 'Following' : 'Follow',
                  style: const TextStyle(fontSize: 12),
                ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST MEDIA (NO OVERFLOW)
/// ---------------------------------------------------------------------------
class _PostMedia extends StatelessWidget {
  final List<String> images;
  final ValueChanged<int> onChanged;

  const _PostMedia({required this.images, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: PageView.builder(
          itemCount: images.length,
          onPageChanged: onChanged,
          itemBuilder: (_, i) {
            return Image.network(
              images[i],
              fit: BoxFit.cover,
              width: double.infinity,
            );
          },
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// IMAGE DOTS
/// ---------------------------------------------------------------------------
class _ImageDots extends StatelessWidget {
  final int count;
  final int index;

  const _ImageDots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (i) => Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == index ? Colors.blue : Colors.grey.shade400,
            ),
          ),
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
      children: [
        IconButton(
          iconSize: 18,
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
          iconSize: 18,
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () {},
        ),
        IconButton(
          iconSize: 18,
          icon: Icon(post.hasSaved ? Icons.bookmark : Icons.bookmark_border),
          onPressed: () => engagement.savePost(post),
        ),
      ],
    );
  }
}
