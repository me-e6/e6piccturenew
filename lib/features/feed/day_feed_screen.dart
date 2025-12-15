import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile/widgets/verified_badge.dart';
import 'day_feed_controller.dart';
import '../post/create/post_model.dart';
import '../post/viewer/immersive_post_viewer.dart';

class DayFeedScreen extends StatelessWidget {
  const DayFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      // ❌ NO hard-coded backgroundColor
      appBar: AppBar(title: const Text("Day Feed"), elevation: 2),

      body: Consumer<DayFeedController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.posts.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: scheme.primary),
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (scroll) {
              if (scroll.metrics.pixels == scroll.metrics.maxScrollExtent &&
                  !controller.isLoadingMore) {
                controller.loadMore();
              }
              return false;
            },
            child: RefreshIndicator(
              color: scheme.primary,
              onRefresh: controller.refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount:
                    controller.posts.length +
                    (controller.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < controller.posts.length) {
                    final doc = controller.posts[index];
                    final post = PostModel.fromDocument(doc);
                    post.likeCount += controller.optimisticLikeDeltaFor(
                      post.postId,
                    );
                    return _PostCard(post: post);
                  }

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(color: scheme.primary),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// POST CARD (THEME AWARE)
// ---------------------------------------------------------------------------

class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ImmersivePostViewer(post: post)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.network(
                post.resolvedImages.first,
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 12),

            // OWNER ROW
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Posted by ${post.authorName}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  VerifiedBadge(
                    isVerified: post.isVerifiedOwner,
                    iconSize: 14,
                    fontSize: 11,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ENGAGEMENT ROW
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite,
                    size: 20,
                    color: post.likeCount > 0
                        ? Colors.red
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text("${post.likeCount}", style: theme.textTheme.bodySmall),

                  const SizedBox(width: 14),

                  Icon(Icons.reply, size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text("${post.replyCount}", style: theme.textTheme.bodySmall),

                  const SizedBox(width: 14),

                  Icon(
                    Icons.format_quote,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${post.quoteReplyCount}",
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
