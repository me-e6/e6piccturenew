import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../create/create_post_controller.dart';
import '../create/post_model.dart';

class QuoteReplyScreen extends StatelessWidget {
  final PostModel post;

  const QuoteReplyScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreatePostController(),
      child: Consumer<CreatePostController>(
        builder: (context, controller, _) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          return Scaffold(
            appBar: AppBar(title: const Text("Quote Reply"), elevation: 1),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // --------------------------------------------------
                  // QUOTED POST PREVIEW
                  // --------------------------------------------------
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.resolvedImages.first,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // --------------------------------------------------
                  // POST QUOTE BUTTON
                  // --------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await controller.createPost();

                        if (!success || !context.mounted) return;

                        // Increment quote count on original post
                        await FirebaseFirestore.instance
                            .collection("posts")
                            .doc(post.postId)
                            .update({
                              "quoteReplyCount": FieldValue.increment(1),
                            });

                        Navigator.pop(context);
                      },
                      child: const Text("Post Quote"),
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
