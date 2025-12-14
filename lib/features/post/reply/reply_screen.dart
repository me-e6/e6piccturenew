import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'reply_controller.dart';

class ReplyScreen extends StatelessWidget {
  final String postId;

  const ReplyScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReplyController(postId),
      child: Consumer<ReplyController>(
        builder: (context, c, _) {
          return Scaffold(
            appBar: AppBar(title: const Text("Reply")),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: c.textController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Write your reply...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: c.isPosting
                        ? null
                        : () => c.submitReply(context),
                    child: c.isPosting
                        ? const CircularProgressIndicator()
                        : const Text("Reply"),
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
