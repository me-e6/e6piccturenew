import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../create/post_model.dart';
import 'post_details_controller.dart';

class PostDetailsScreen extends StatelessWidget {
  final PostModel post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PostDetailsController(post),
      child: Consumer<PostDetailsController>(
        builder: (context, controller, _) {
          final p = controller.post;

          return Scaffold(
            backgroundColor: const Color(0xFFF5EDE3),
            appBar: AppBar(
              backgroundColor: const Color(0xFFC56A45),
              title: const Text(
                "Post Details",
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IMAGE
                  Container(
                    width: double.infinity,
                    height: 320,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(p.resolvedImages.first),

                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p.isRepost && p.originalOwnerName != null)
                          Text(
                            "Re-pic from ${p.originalOwnerName}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C7A4C),
                            ),
                          ),

                        const SizedBox(height: 8),

                        Text(
                          "Posted at: ${p.createdAt}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ENGAGEMENT ROW
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // LIKE
                            GestureDetector(
                              onTap: controller.isProcessing
                                  ? null
                                  : () => controller.toggleLike(),
                              child: Column(
                                children: [
                                  Icon(
                                    p.hasLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: const Color(0xFFC56A45),
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${p.likeCount}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2F2F2F),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // SAVE
                            GestureDetector(
                              onTap: controller.isProcessing
                                  ? null
                                  : () => controller.toggleSave(),
                              child: Column(
                                children: [
                                  Icon(
                                    p.hasSaved
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    size: 28,
                                    color: Colors.black87,
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Save",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2F2F2F),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // MORE → Re-pic
                            PopupMenuButton(
                              icon: const Icon(Icons.more_horiz),
                              onSelected: (value) {
                                if (value == "repost") {
                                  controller.repost(context);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: "repost",
                                  child: Text("Re-Pic"),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
