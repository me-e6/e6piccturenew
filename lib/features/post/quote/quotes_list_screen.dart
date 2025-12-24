import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'quote_controller.dart';
import 'quote_model.dart';
import 'quoted_post_card.dart';

/// ------------------------------------------------------------
/// QUOTES LIST SCREEN
/// ------------------------------------------------------------
/// Displays all quotes of a specific post.
/// Accessible from the quote count button on any post.
/// 
/// Features:
/// - Real-time updates
/// - Pull to refresh
/// - Empty state
/// - Loading state
/// - Error handling
/// - Navigate to quote or original post
/// ------------------------------------------------------------
class QuotesListScreen extends StatelessWidget {
  final String postId;
  final String? postAuthorName;

  const QuotesListScreen({
    super.key,
    required this.postId,
    this.postAuthorName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuotesListController(postId: postId),
      child: _QuotesListContent(postAuthorName: postAuthorName),
    );
  }
}

class _QuotesListContent extends StatelessWidget {
  final String? postAuthorName;

  const _QuotesListContent({this.postAuthorName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = context.watch<QuotesListController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          postAuthorName != null ? 'Quotes of $postAuthorName\'s post' : 'Quotes',
        ),
        elevation: 0,
      ),
      body: _buildBody(context, controller, theme, scheme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    QuotesListController controller,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    // Loading state
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (controller.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                controller.error!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: controller.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (controller.quotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.format_quote_outlined,
                size: 64,
                color: scheme.onSurfaceVariant.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No quotes yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to quote this post!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Quotes list
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: controller.quotes.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: scheme.outlineVariant.withOpacity(0.3),
        ),
        itemBuilder: (context, index) {
          final doc = controller.quotes[index];
          return _QuoteListItem(doc: doc);
        },
      ),
    );
  }
}

/// Single quote item in the list
class _QuoteListItem extends StatelessWidget {
  final DocumentSnapshot doc;

  const _QuoteListItem({required this.doc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Extract quote data
    final quoteAuthorName = data['authorName'] as String? ?? 'Unknown';
    final quoteAuthorHandle = data['authorHandle'] as String?;
    final quoteAuthorAvatarUrl = data['authorAvatarUrl'] as String?;
    final isVerified = data['isVerifiedOwner'] as bool? ?? false;
    final commentary = data['commentary'] as String?;
    final createdAtRaw = data['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : DateTime.now();

    // Extract quoted preview
    final quotedPreviewData = data['quotedPreview'] as Map<String, dynamic>?;
    final quotedPreview = quotedPreviewData != null
        ? QuotedPostPreview.fromMap(quotedPreviewData)
        : null;

    return InkWell(
      onTap: () => _navigateToQuotePost(context, doc.id),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AUTHOR ROW
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: scheme.surfaceContainerHighest,
                  backgroundImage: quoteAuthorAvatarUrl != null
                      ? NetworkImage(quoteAuthorAvatarUrl)
                      : null,
                  child: quoteAuthorAvatarUrl == null
                      ? Icon(Icons.person, color: scheme.onSurfaceVariant)
                      : null,
                ),
                const SizedBox(width: 12),

                // Name & Handle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              quoteAuthorName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified, size: 16, color: scheme.primary),
                          ],
                        ],
                      ),
                      if (quoteAuthorHandle != null)
                        Text(
                          '@$quoteAuthorHandle',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),

                // Timestamp
                Text(
                  _formatTimestamp(createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),

            // COMMENTARY
            if (commentary != null && commentary.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                commentary,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ],

            // QUOTED POST PREVIEW (if no commentary, show bigger preview)
            if (quotedPreview != null) ...[
              const SizedBox(height: 12),
              QuotedPostCard(
                preview: quotedPreview,
                compact: commentary != null && commentary.isNotEmpty,
                onTap: () => _navigateToOriginalPost(context, quotedPreview.postId),
              ),
            ],

            // ENGAGEMENT STATS (optional - can add later)
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStat(
                  context,
                  Icons.favorite_border,
                  data['likeCount'] as int? ?? 0,
                ),
                const SizedBox(width: 20),
                _buildStat(
                  context,
                  Icons.chat_bubble_outline,
                  data['replyCount'] as int? ?? 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, int count) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant.withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 365) return '${dateTime.day}/${dateTime.month}';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _navigateToQuotePost(BuildContext context, String quotePostId) {
    // TODO: Navigate to post details screen
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => PostDetailsScreen(postId: quotePostId),
    // ));
    debugPrint('Navigate to quote post: $quotePostId');
  }

  void _navigateToOriginalPost(BuildContext context, String postId) {
    // TODO: Navigate to post details screen
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => PostDetailsScreen(postId: postId),
    // ));
    debugPrint('Navigate to original post: $postId');
  }
}

/// ------------------------------------------------------------
/// QUOTE COUNT BUTTON
/// ------------------------------------------------------------
/// Clickable quote count that navigates to quotes list.
/// Used in engagement bars.
/// ------------------------------------------------------------
class QuoteCountButton extends StatelessWidget {
  final String postId;
  final int count;
  final String? postAuthorName;
  final bool compact;

  const QuoteCountButton({
    super.key,
    required this.postId,
    required this.count,
    this.postAuthorName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: count > 0 ? () => _navigateToQuotesList(context) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.format_quote_rounded,
              size: compact ? 16 : 20,
              color: scheme.onSurfaceVariant,
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(count),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToQuotesList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuotesListScreen(
          postId: postId,
          postAuthorName: postAuthorName,
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
