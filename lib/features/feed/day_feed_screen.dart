import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'day_feed_controller.dart';
import 'day_feed_service.dart';
import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';

/// ----------------------------------
/// DayFeedScreen
/// ----------------------------------
class DayFeedScreen extends StatefulWidget {
  const DayFeedScreen({super.key});

  @override
  State<DayFeedScreen> createState() => _DayFeedScreenState();
}

class _DayFeedScreenState extends State<DayFeedScreen> {
  late final DayFeedController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DayFeedController(DayFeedService());
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DayFeedController>.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(title: const Text('PICCTURE')),
        body: const _DayFeedBody(),
      ),
    );
  }
}

/// ----------------------------------
/// _DayFeedBody
/// ----------------------------------
class _DayFeedBody extends StatelessWidget {
  const _DayFeedBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<DayFeedController>(
      builder: (context, controller, _) {
        final state = controller.state;

        return Column(
          children: [
            _DayAlbumBanner(
              hasNewPosts: state.hasNewPosts,
              postCount: state.posts.length,
              onTap: () async {
                controller.markBannerSeen();
                await controller.refresh();
              },
            ),
            Expanded(child: _FeedContent()),
          ],
        );
      },
    );
  }
}

/// ----------------------------------
/// Day Album Banner
/// ----------------------------------
class _DayAlbumBanner extends StatelessWidget {
  final bool hasNewPosts;
  final int postCount;
  final VoidCallback onTap;

  const _DayAlbumBanner({
    required this.hasNewPosts,
    required this.postCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String text = hasNewPosts
        ? 'New posts available — tap to refresh'
        : 'You have $postCount pictures to review today';

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasNewPosts
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.withOpacity(0.08),
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasNewPosts ? Icons.refresh : Icons.photo_library_outlined,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------------
/// Feed Content
/// ----------------------------------
class _FeedContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DayFeedController>(
      builder: (context, controller, _) {
        final state = controller.state;

        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null) {
          return Center(
            child: Text(
              state.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (state.posts.isEmpty) {
          return const Center(child: Text('No pictures to review today'));
        }

        return PageView.builder(
          controller: PageController(viewportFraction: 0.92),
          itemCount: state.posts.length,
          itemBuilder: (context, index) {
            return ChangeNotifierProvider(
              create: (_) => EngagementController(),
              child: _PostCard(post: state.posts[index]),
            );
          },
        );
      },
    );
  }
}

/// ----------------------------------
/// _PostCard
/// ----------------------------------
class _PostCard extends StatefulWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.post.imageUrls;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Stack(
                  children: [
                    _buildImageCarousel(images),
                    if (images.length > 1) _buildImageIndicator(images.length),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _EngagementBar(post: widget.post),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) {
      return const Center(child: Text('No image available'));
    }

    if (images.length == 1) {
      return _buildImage(images.first);
    }

    return PageView.builder(
      itemCount: images.length,
      onPageChanged: (index) {
        setState(() => _currentImageIndex = index);
      },
      itemBuilder: (context, index) {
        return _buildImage(images[index]);
      },
    );
  }

  Widget _buildImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (_, __, ___) {
        return const Center(child: Icon(Icons.broken_image, size: 48));
      },
    );
  }

  Widget _buildImageIndicator(int total) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${_currentImageIndex + 1} / $total',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

/// ----------------------------------
/// Engagement Bar
/// ----------------------------------
class _EngagementBar extends StatelessWidget {
  final PostModel post;

  const _EngagementBar({required this.post});

  @override
  Widget build(BuildContext context) {
    return Consumer<EngagementController>(
      builder: (context, controller, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.thumb_up_alt_outlined),
              onPressed: () => controller.likePost(post),
            ),
            IconButton(
              icon: const Icon(Icons.thumb_down_alt_outlined),
              onPressed: () => controller.dislikePost(post),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: () => controller.savePost(post),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => controller.sharePost(post),
            ),
            IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
          ],
        );
      },
    );
  }
}
