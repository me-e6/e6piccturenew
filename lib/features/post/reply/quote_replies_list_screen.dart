import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../create/post_model.dart';

class QuoteRepliesListScreen extends StatelessWidget {
  final PostModel post;

  const QuoteRepliesListScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quote Replies")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("posts")
            .doc(post.postId)
            .collection("quoteReplies")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // --------------------------------------------------
          // LOADING
          // --------------------------------------------------
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --------------------------------------------------
          // EMPTY STATE
          // --------------------------------------------------
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No quote replies yet",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final quotes = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: quotes.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final data = quotes[index].data() as Map<String, dynamic>;
              return _QuoteReplyTile(data: data);
            },
          );
        },
      ),
    );
  }
}

// --------------------------------------------------
// SINGLE QUOTE REPLY TILE
// --------------------------------------------------

class _QuoteReplyTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _QuoteReplyTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final quoted = data["quotedPostSnapshot"] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --------------------------------------------------
        // QUOTE AUTHOR
        // --------------------------------------------------
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade400,
              child: const Icon(Icons.person, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              data["authorUid"] ?? "User",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // --------------------------------------------------
        // USER COMMENTARY
        // --------------------------------------------------
        Text(data["text"] ?? "", style: const TextStyle(fontSize: 14)),

        const SizedBox(height: 12),

        // --------------------------------------------------
        // QUOTED POST SNAPSHOT
        // --------------------------------------------------
        if (quoted.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                if (quoted["imageUrl"] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      quoted["imageUrl"],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Quoted post",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
