import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e6piccturenew/features/feed/day_feed_controller.dart';
import '../create/post_model.dart';
import 'immersive_post_controller.dart';
import '../../common/widgets/gazetter_badge.dart';

// Replies & Quotes
import '../reply/replies_list_screen.dart';
import '../reply/quote_reply_screen.dart';

class ImmersivePostViewer extends StatelessWidget {
  final PostModel post;

  const ImmersivePostViewer({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ImmersivePostController(post),
      child: const _ImmersivePostView(),
    );
  }
}

class _ImmersivePostView extends StatelessWidget {
  const _ImmersivePostView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ImmersivePostController>();
    final images = controller.post.resolvedImages;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // --------------------------------------------------
            // IMAGE CAROUSEL
            // --------------------------------------------------
            PageView.builder(
              itemCount: images.length,
              onPageChanged: controller.onPageChanged,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    images[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                );
              },
            ),

            // --------------------------------------------------
            // TOP BAR (CLOSE + AUTHOR + GAZETTER + IMAGE INDEX)
            // --------------------------------------------------
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT: CLOSE + AUTHOR INFO
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // AUTHOR + GAZETTER
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.post.originalOwnerName ??
                                controller.post.repostedByName ??
                                "User",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          // ✅ GAZETTER BADGE
                          if (controller.post.isVerifiedOwner)
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: GazetterBadge(iconSize: 13, fontSize: 11),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // RIGHT: IMAGE COUNTER
                  if (controller.totalImages > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${controller.currentIndex + 1}/${controller.totalImages}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // --------------------------------------------------
            // RIGHT SIDE — ENGAGEMENT ACTIONS + COUNTS
            // --------------------------------------------------
            Positioned(
              right: 14,
              bottom: 120,
              child: Column(
                children: [
                  // ---------------- LIKE ----------------
                  _ActionIcon(
                    icon: controller.post.hasLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: "Like",
                    onTap: () {
                      // 1️⃣ Optimistic UI (instant)
                      context.read<DayFeedController>().optimisticLike(
                        controller.post.postId,
                        controller.post.hasLiked,
                      );

                      // 2️⃣ Viewer local state
                      controller.toggleLike();
                    },
                  ),

                  // LIVE LIKE COUNT
                  Text(
                    "${controller.post.likeCount}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),

                  const SizedBox(height: 22),

                  // ---------------- REPLIES LIST ----------------
                  _ActionIcon(
                    icon: Icons.reply,
                    label: "Replies",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RepliesListScreen(postId: controller.post.postId),
                        ),
                      );
                    },
                  ),

                  // LIVE REPLY COUNT
                  Text(
                    "${controller.post.replyCount}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),

                  const SizedBox(height: 22),

                  // ---------------- QUOTE ----------------
                  _ActionIcon(
                    icon: Icons.format_quote,
                    label: "Quote",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              QuoteReplyScreen(post: controller.post),
                        ),
                      );
                    },
                  ),

                  // LIVE QUOTE COUNT
                  Text(
                    "${controller.post.quoteReplyCount}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // BOTTOM GRADIENT
            // --------------------------------------------------
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// REUSABLE ACTION ICON WIDGET
// --------------------------------------------------
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
