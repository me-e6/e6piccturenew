import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../feed/day_feed_controller.dart';
import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';
import '../feed/day_album_viewer_screen.dart';
import '../follow/follow_controller.dart';

/// ---------------------------------------------------------------------------
/// HOME SCREEN V3
/// ---------------------------------------------------------------------------
class HomeScreenV3 extends StatelessWidget {
  const HomeScreenV3({super.key});

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<DayFeedController>();
    final state = feed.state;

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: feed.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _DayAlbumBanner(
                  count: feed.totalPostCount,
                  hasNewPosts: state.hasNewPosts,
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

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              const SliverToBoxAdapter(child: _SuggestedUsersSection()),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('No pictures yet today')),
      );
    }

    return SizedBox(
      height: 500,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.94),
        itemCount: posts.length,
        itemBuilder: (_, index) {
          return _PostCard(post: posts[index]);
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST CARD
/// ---------------------------------------------------------------------------
class _PostCard extends StatefulWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late final PageController _imageController;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _PostHeader(post: widget.post),

          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    controller: _imageController,
                    itemCount: widget.post.imageUrls.length,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                    itemBuilder: (_, index) {
                      return Image.network(
                        widget.post.imageUrls[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  if (widget.post.imageUrls.length > 1)
                    Positioned(
                      bottom: 10,
                      child: _ImageDots(
                        count: widget.post.imageUrls.length,
                        activeIndex: _imageIndex,
                      ),
                    ),
                ],
              ),
            ),
          ),

          _EngagementBar(post: widget.post),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST HEADER (AUTHOR + VERIFIED + MENU)
/// ---------------------------------------------------------------------------
class _PostHeader extends StatelessWidget {
  final PostModel post;

  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final bool isOwner =
        FirebaseAuth.instance.currentUser?.uid == post.authorId;

    return ChangeNotifierProvider(
      create: (_) {
        final c = FollowController();
        c.load(post.authorId); // 👈 REQUIRED
        return c;
      },
      child: Builder(
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const CircleAvatar(radius: 16),
                const SizedBox(width: 8),

                Expanded(
                  child: Row(
                    children: [
                      Text(
                        post.authorName.isNotEmpty
                            ? post.authorName
                            : (isOwner ? 'You' : 'Unknown'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (post.isVerifiedOwner) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.blue,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Consumer<FollowController>(
                  builder: (_, follow, __) {
                    if (isOwner) return const SizedBox.shrink();

                    return TextButton(
                      onPressed: follow.isFollowing
                          ? () => follow.unfollow(post.authorId)
                          : () => follow.follow(post.authorId),
                      child: Text(
                        follow.isFollowing ? 'Following' : 'Follow',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: follow.isFollowing
                              ? Colors.grey
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
                // const SizedBox(width: 1),
                Consumer<FollowController>(
                  builder: (_, follow, __) {
                    return PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'follow') {
                          follow.follow(post.authorId);
                        } else if (value == 'unfollow') {
                          follow.unfollow(post.authorId);
                        }
                      },
                      itemBuilder: (_) => [
                        if (!isOwner)
                          PopupMenuItem(
                            value: follow.isFollowing ? 'unfollow' : 'follow',
                            child: Text(
                              follow.isFollowing ? 'Unfollow' : 'Follow',
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'copy',
                          child: Text('Copy link'),
                        ),
                        if (isOwner)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// IMAGE DOTS
/// ---------------------------------------------------------------------------
class _ImageDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _ImageDots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 7 : 5,
          height: active ? 7 : 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.white : Colors.white.withOpacity(0.4),
          ),
        );
      }),
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
            post.hasLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
            color: post.hasLiked ? Colors.red : null,
          ),
          onPressed: () {
            post.hasLiked
                ? engagement.dislikePost(post)
                : engagement.likePost(post);
          },
        ),
        IconButton(
          icon: Icon(
            post.hasLiked ? Icons.thumb_down : Icons.thumb_down_off_alt,
            color: post.hasLiked ? Colors.red : null,
          ),
          onPressed: () {
            post.hasLiked
                ? engagement.dislikePost(post)
                : engagement.likePost(post);
          },
        ),
        IconButton(icon: const Icon(Icons.repeat), onPressed: () {}),
        // IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        IconButton(
          icon: Icon(post.hasSaved ? Icons.bookmark : Icons.bookmark_border),
          onPressed: () => engagement.savePost(post),
        ),
        IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () => engagement.sharePost(post),
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
      height: 120,
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
              itemBuilder: (_, __) {
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
