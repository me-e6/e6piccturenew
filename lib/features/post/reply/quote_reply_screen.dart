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
          return Scaffold(
            appBar: AppBar(title: const Text("Quote Reply")),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // QUOTED POST PREVIEW
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.network(
                      post.resolvedImages.first,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CAPTION
                  TextField(
                    controller: c.descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Add your thoughts...",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      // 1️⃣ Create the quote post
                      final result = await c.createPost(context);

                      // 2️⃣ Increment quoteReplyCount ONLY if post creation succeeded
                      if (result == "success") {
                        await FirebaseFirestore.instance
                            .collection("posts")
                            .doc(post.postId)
                            .update({
                              "quoteReplyCount": FieldValue.increment(1),
                            });
                      }
                    },
                    child: const Text("Post Quote"),
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
