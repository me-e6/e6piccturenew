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
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          return Scaffold(
            // ❌ No backgroundColor override
            appBar: AppBar(title: const Text("Reply"), elevation: 1),

            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --------------------------------------------------
                  // REPLY INPUT
                  // --------------------------------------------------
                  TextField(
                    controller: c.textController,
                    maxLines: 4,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: "Write your reply...",
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --------------------------------------------------
                  // SUBMIT BUTTON
                  // --------------------------------------------------
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: c.isPosting
                          ? null
                          : () => c.submitReply(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        disabledBackgroundColor: scheme.primary.withOpacity(
                          0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: c.isPosting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : const Text(
                              "Reply",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
