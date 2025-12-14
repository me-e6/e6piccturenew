import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '.././profile/widgets/verified_badge.dart';

import 'day_feed_controller.dart';
import '../post/create/post_model.dart';
import '../post/viewer/immersive_post_viewer.dart';

class DayFeedScreen extends StatelessWidget {
  const DayFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EDE3),
        elevation: 6,
        title: const Text(
          "Day Feed",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6C7A4C),
          ),
        ),
      ),
      body: Consumer<DayFeedController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.posts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFC56A45)),
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
              onRefresh: controller.refresh,
              color: const Color(0xFFC56A45),
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

                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFC56A45),
                      ),
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
// POST CARD
// ---------------------------------------------------------------------------

class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ImmersivePostViewer(post: post)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E2D2),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
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

            const SizedBox(height: 10),

            // OWNER LABEL
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      post.isRepost
                          ? "RePic by ${post.repostedByName ?? 'User'}"
                          : "Posted by ${post.originalOwnerName ?? 'User'}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6C7A4C),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 6),

                  // ✅ Gazetter badge
                  VerifiedBadge(
                    isVerified: post.isVerifiedOwner,
                    iconSize: 14,
                    fontSize: 11,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            const SizedBox(height: 6),

            // ---------------- ENGAGEMENT ROW ----------------
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
              child: Row(
                children: [
                  // LIKE
                  Icon(
                    Icons.favorite,
                    size: 20,
                    color: post.likeCount > 0
                        ? Colors.red
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${post.likeCount}",
                    style: const TextStyle(fontSize: 13),
                  ),

                  const SizedBox(width: 14),

                  // REPLY
                  const Icon(Icons.reply, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    "${post.replyCount}",
                    style: const TextStyle(fontSize: 13),
                  ),

                  const SizedBox(width: 14),

                  // QUOTE
                  const Icon(Icons.format_quote, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    "${post.quoteReplyCount}",
                    style: const TextStyle(fontSize: 13),
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
