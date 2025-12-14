import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'replies_list_controller.dart';

class RepliesListScreen extends StatelessWidget {
  final String postId;

  const RepliesListScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RepliesListController(postId),
      child: Consumer<RepliesListController>(
        builder: (context, c, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5EDE3),
            appBar: AppBar(
              title: const Text("Replies"),
              backgroundColor: const Color(0xFFF5EDE3),
              elevation: 4,
            ),
            body: c.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFC56A45)),
                  )
                : c.replies.isEmpty
                ? const Center(
                    child: Text(
                      "No replies yet",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: c.replies.length,
                    itemBuilder: (context, index) {
                      final r = c.replies[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E2D2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.text, style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 6),
                            Text(
                              r.createdAt.toLocal().toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
