import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/load_state.dart';

import '../feed/day_feed_controller.dart';
import '../post/create/post_model.dart';
import '../post/viewer/immersive_post_viewer.dart';

/// ------------------------------------------------------------
/// DAY FEED SCREEN
/// ------------------------------------------------------------
/// Fullscreen infinite feed
/// - Vertical swipe = next post
/// - Horizontal swipe = image carousel (per post)
/// - Controller-driven only
class DayFeedScreen extends StatefulWidget {
  const DayFeedScreen({super.key});

  @override
  State<DayFeedScreen> createState() => _DayFeedScreenState();
}

class _DayFeedScreenState extends State<DayFeedScreen> {
  late final PageController _verticalController;

  @override
  void initState() {
    super.initState();
    _verticalController = PageController();

    // Load initial feed once UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DayFeedController>().loadInitial();
    });
  }

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(Provider.of<DayFeedController>(context, listen: false) != null);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<DayFeedController>(
          builder: (_, controller, __) {
            switch (controller.state) {
              case LoadState.loading:
                return const Center(child: CircularProgressIndicator());

              case LoadState.empty:
                return _EmptyState();

              case LoadState.error:
                return _ErrorState(onRetry: controller.loadInitial);

              case LoadState.success:
              case LoadState.loadingMore:
                return _buildFeed(controller);

              case LoadState.idle:
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FEED VIEW
  // ------------------------------------------------------------
  Widget _buildFeed(DayFeedController controller) {
    return PageView.builder(
      controller: _verticalController,
      scrollDirection: Axis.vertical,
      itemCount: controller.posts.length + (controller.hasMore ? 1 : 0),
      onPageChanged: (index) {
        // Prefetch next page
        if (index >= controller.posts.length - 3 &&
            controller.hasMore &&
            controller.state != LoadState.loadingMore) {
          controller.loadMore();
        }
      },
      itemBuilder: (_, index) {
        if (index >= controller.posts.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final post = controller.posts[index];
        return _PostPage(post: post);
      },
    );
  }
}

/// ------------------------------------------------------------
/// SINGLE POST PAGE (FULLSCREEN)
/// ------------------------------------------------------------
class _PostPage extends StatelessWidget {
  final PostModel post;

  const _PostPage({required this.post});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // --------------------------------------------------
        // IMAGE CAROUSEL
        // --------------------------------------------------
        PageView.builder(
          itemCount: post.resolvedImages.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, index) {
            return Image.network(
              post.resolvedImages[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
          },
        ),

        // --------------------------------------------------
        // OVERLAY UI (IMMERSIVE VIEWER)
        // --------------------------------------------------
        Positioned.fill(child: ImmersivePostViewer(post: post)),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// EMPTY STATE
/// ------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "No posts in your Day Album yet",
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// ERROR STATE
/// ------------------------------------------------------------
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Failed to load Day Feed",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text("Retry")),
        ],
      ),
    );
  }
}
