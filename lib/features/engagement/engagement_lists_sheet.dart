import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../profile/profile_entry.dart';
import 'repic_service.dart';

/// ============================================================================
/// ENGAGEMENT LISTS SHEET
/// ============================================================================
/// Bottom sheet showing engagement lists for a post:
/// - Repics tab: Users who repicced
/// - Quotes tab: Quote posts referencing this
/// - Likes tab: Users who liked (optional)
/// ============================================================================
class EngagementListsSheet extends StatefulWidget {
  final String postId;
  final int repicCount;
  final int quoteCount;
  final int likeCount;

  const EngagementListsSheet({
    super.key,
    required this.postId,
    this.repicCount = 0,
    this.quoteCount = 0,
    this.likeCount = 0,
  });

  /// Show as modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    required String postId,
    int repicCount = 0,
    int quoteCount = 0,
    int likeCount = 0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EngagementListsSheet(
        postId: postId,
        repicCount: repicCount,
        quoteCount: quoteCount,
        likeCount: likeCount,
      ),
    );
  }

  @override
  State<EngagementListsSheet> createState() => _EngagementListsSheetState();
}

class _EngagementListsSheetState extends State<EngagementListsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RepicService _repicService = RepicService();

  List<Map<String, dynamic>> _repicUsers = [];
  List<Map<String, dynamic>> _quotePosts = [];
  bool _isLoadingRepics = true;
  bool _isLoadingQuotes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRepics();
    _loadQuotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRepics() async {
    try {
      final users = await _repicService.getRepicUsers(widget.postId);
      if (mounted) {
        setState(() {
          _repicUsers = users;
          _isLoadingRepics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRepics = false);
      }
    }
  }

  Future<void> _loadQuotes() async {
    try {
      final posts = await _repicService.getQuotePosts(widget.postId);
      if (mounted) {
        setState(() {
          _quotePosts = posts;
          _isLoadingQuotes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingQuotes = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.6,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Engagement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurfaceVariant,
            indicatorColor: scheme.primary,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.repeat, size: 18),
                    const SizedBox(width: 6),
                    Text('Repics (${widget.repicCount})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.format_quote, size: 18),
                    const SizedBox(width: 6),
                    Text('Quotes (${widget.quoteCount})'),
                  ],
                ),
              ),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRepicsTab(scheme),
                _buildQuotesTab(scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // REPICS TAB
  // --------------------------------------------------------------------------
  Widget _buildRepicsTab(ColorScheme scheme) {
    if (_isLoadingRepics) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_repicUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.repeat,
              size: 48,
              color: scheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No repics yet',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _repicUsers.length,
      itemBuilder: (context, index) {
        final user = _repicUsers[index];
        return _UserListTile(
          uid: user['uid'],
          displayName: user['displayName'],
          handle: user['handle'],
          avatarUrl: user['avatarUrl'],
          isVerified: user['isVerified'] ?? false,
          subtitle: 'Repicced',
          onTap: () => _navigateToProfile(user['uid']),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // QUOTES TAB
  // --------------------------------------------------------------------------
  Widget _buildQuotesTab(ColorScheme scheme) {
    if (_isLoadingQuotes) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_quotePosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.format_quote,
              size: 48,
              color: scheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No quotes yet',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _quotePosts.length,
      itemBuilder: (context, index) {
        final quote = _quotePosts[index];
        return _QuoteListTile(
          authorId: quote['authorId'],
          authorName: quote['authorName'],
          authorHandle: quote['authorHandle'],
          authorAvatarUrl: quote['authorAvatarUrl'],
          authorIsVerified: quote['authorIsVerified'] ?? false,
          commentary: quote['commentary'],
          onTap: () => _navigateToProfile(quote['authorId']),
        );
      },
    );
  }

  void _navigateToProfile(String userId) {
    Navigator.pop(context); // Close sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEntry(userId: userId),
      ),
    );
  }
}

// ============================================================================
// USER LIST TILE
// ============================================================================
class _UserListTile extends StatelessWidget {
  final String uid;
  final String displayName;
  final String? handle;
  final String? avatarUrl;
  final bool isVerified;
  final String? subtitle;
  final VoidCallback? onTap;

  const _UserListTile({
    required this.uid,
    required this.displayName,
    this.handle,
    this.avatarUrl,
    this.isVerified = false,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
            ? CachedNetworkImageProvider(avatarUrl!)
            : null,
        child: avatarUrl == null || avatarUrl!.isEmpty
            ? Icon(Icons.person, color: scheme.onSurfaceVariant)
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isVerified) ...[
            const SizedBox(width: 4),
            Icon(Icons.verified, size: 16, color: scheme.primary),
          ],
        ],
      ),
      subtitle: handle != null
          ? Text(
              '@$handle',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            )
          : subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                )
              : null,
      trailing: Icon(
        Icons.chevron_right,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

// ============================================================================
// QUOTE LIST TILE
// ============================================================================
class _QuoteListTile extends StatelessWidget {
  final String authorId;
  final String authorName;
  final String? authorHandle;
  final String? authorAvatarUrl;
  final bool authorIsVerified;
  final String? commentary;
  final VoidCallback? onTap;

  const _QuoteListTile({
    required this.authorId,
    required this.authorName,
    this.authorHandle,
    this.authorAvatarUrl,
    this.authorIsVerified = false,
    this.commentary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.surfaceContainerHighest,
              backgroundImage: authorAvatarUrl != null && authorAvatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(authorAvatarUrl!)
                  : null,
              child: authorAvatarUrl == null || authorAvatarUrl!.isEmpty
                  ? Icon(Icons.person, color: scheme.onSurfaceVariant)
                  : null,
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author info
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          authorName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (authorIsVerified) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified, size: 16, color: scheme.primary),
                      ],
                      if (authorHandle != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '@$authorHandle',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Commentary
                  if (commentary != null && commentary!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      commentary!,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Quote indicator
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Quoted this post',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
