import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../create/post_model.dart';
import 'reply_model.dart';

/// ===========================================================================
/// REPLIES LIST SCREEN
/// ===========================================================================
/// Displays all replies for a specific post.
/// Accessible from tapping the reply count in engagement bar.
/// ===========================================================================
class RepliesListScreen extends StatelessWidget {
  final PostModel post;

  const RepliesListScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Replies'), elevation: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(post.postId)
            .collection('replies')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ERROR
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: scheme.error.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading replies',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // EMPTY STATE
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: scheme.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No replies yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to reply!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          // REPLIES LIST
          final replies = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: replies.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: scheme.outlineVariant.withOpacity(0.3),
            ),
            itemBuilder: (context, index) {
              final reply = ReplyModel.fromDoc(replies[index]);
              return _ReplyTile(reply: reply);
            },
          );
        },
      ),
    );
  }
}

/// ===========================================================================
/// REPLY TILE
/// ===========================================================================
class _ReplyTile extends StatelessWidget {
  final ReplyModel reply;

  const _ReplyTile({required this.reply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FutureBuilder<DocumentSnapshot>(
      // Fetch user data for the reply author
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(reply.uid)
          .get(),
      builder: (context, userSnapshot) {
        String authorName = 'User';
        String? authorHandle;
        String? avatarUrl;
        bool isVerified = false;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          authorName = userData?['displayName'] ?? 'User';
          authorHandle = userData?['handle'];
          avatarUrl = userData?['profileImageUrl'] ?? userData?['photoURL'];
          isVerified = userData?['isVerified'] ?? false;
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AVATAR
              CircleAvatar(
                radius: 18,
                backgroundColor: scheme.surfaceContainerHighest,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Icon(
                        Icons.person,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AUTHOR ROW
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            authorName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified, size: 14, color: scheme.primary),
                        ],
                        if (authorHandle != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '@$authorHandle',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(reply.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // REPLY TEXT
                    Text(
                      reply.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}';
  }
}
