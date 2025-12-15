import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../create/create_post_controller.dart';
import '../create/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuoteReplyScreen extends StatelessWidget {
  final PostModel post;

  const QuoteReplyScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreatePostController(),
      child: Consumer<CreatePostController>(
        builder: (context, c, _) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          return Scaffold(
            appBar: AppBar(title: const Text("Quote Reply"), elevation: 1),

            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --------------------------------------------------
                  // CAPTION
                  // --------------------------------------------------
                  TextField(
                    controller: c.descController,
                    maxLines: 4,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: "Add your thoughts...",
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --------------------------------------------------
                  // POST QUOTE BUTTON
                  // --------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: c.isLoading
                          ? null
                          : () async {
                              // 1️⃣ Create the quote post
                              final result = await c.createPost(context);

                              // 2️⃣ Increment quoteReplyCount ONLY if success
                              if (result == "success") {
                                await FirebaseFirestore.instance
                                    .collection("posts")
                                    .doc(post.postId)
                                    .update({
                                      "quoteReplyCount": FieldValue.increment(
                                        1,
                                      ),
                                    });
                              }
                            },
                      child: c.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : const Text("Post Quote"),
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
