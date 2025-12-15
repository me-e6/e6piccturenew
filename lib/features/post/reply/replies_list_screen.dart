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
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          return Scaffold(
            // ❌ No backgroundColor override
            appBar: AppBar(title: const Text("Replies"), elevation: 1),

            body: Builder(
              builder: (_) {
                if (c.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: scheme.primary),
                  );
                }

                if (c.replies.isEmpty) {
                  return Center(
                    child: Text(
                      "No replies yet",
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: c.replies.length,
                  itemBuilder: (context, index) {
                    final r = c.replies[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.text, style: theme.textTheme.bodyMedium),

                          const SizedBox(height: 6),

                          Text(
                            _formatDate(r.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // DATE FORMATTER (NO UI LOGIC IN WIDGET TREE)
  // --------------------------------------------------
  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return "${local.day}/${local.month}/${local.year} • "
        "${local.hour.toString().padLeft(2, '0')}:"
        "${local.minute.toString().padLeft(2, '0')}";
  }
}
