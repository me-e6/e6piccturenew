import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../feed/day_feed_controller.dart';
import '../feed/day_album_viewer_screen.dart';
import '../feed/day_album_tracker.dart';

import '../post/create/post_model.dart';

import '../engagement/engagement_controller.dart';

import '../follow/follow_controller.dart';

import '../profile/profile_entry.dart';

import '../search/search_screen.dart';
import '../search/search_controllers.dart';

import '../user/user_avatar_controller.dart';

import '../../core/theme/theme_controller.dart';
import '../post/reply/quote_reply_screen.dart';

import '../auth/auth_gate.dart';
import '../auth/auth_service.dart';

/// ---------------------------------------------------------------------------
/// HOME SCREEN V3
/// ---------------------------------------------------------------------------
class HomeScreenV3 extends StatelessWidget {
  const HomeScreenV3({super.key});

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<DayFeedController>();
    final state = feed.state;
    final albumStatus = state.albumStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: feed.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (albumStatus != null && albumStatus.hasUnseen)
                SliverToBoxAdapter(
                  child: _XStyleDayAlbumPill(
                    status: albumStatus,
                    onTap: feed.dismissAlbumPill,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              SliverToBoxAdapter(
                child: _PostCarousel(
                  posts: state.posts,
                  isLoading: state.isLoading,
                  errorMessage: state.errorMessage,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              const SliverToBoxAdapter(child: _SuggestedUsersSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// APP BAR
  /// -------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFF6F4EF),
      leading: IconButton(
        icon: const Icon(
          Icons.menu_rounded,
          size: 26,
          color: Color(0xFF3D3D3D),
        ),
        onPressed: () => _showProfileSheet(context),
      ),
      title: const Text(
        'PICCTURE',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          letterSpacing: 1.5,
          color: Color(0xFF3D3D3D),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.search_rounded,
            size: 25,
            color: Color(0xFF3D3D3D),
          ),
          onPressed: () => _openSearch(context),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 25),
          onPressed: () {},
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  /// -------------------------------------------------------------------------
  /// SEARCH
  /// -------------------------------------------------------------------------
  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => SearchControllers(),
          child: const SearchScreen(),
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// PROFILE SHEET
  /// -------------------------------------------------------------------------
  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ProfileBottomSheet(),
    );
  }
}

/// ---------------------------------------------------------------------------
/// DAY ALBUM PILL
/// ---------------------------------------------------------------------------
class _XStyleDayAlbumPill extends StatelessWidget {
  final DayAlbumStatus status;
  final VoidCallback onTap;

  const _XStyleDayAlbumPill({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8E3D6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD0C9B8), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                size: 14,
                color: Color(0xFF8B7355),
              ),
              const SizedBox(width: 6),
              Text(
                status.message ?? 'New Picctures available',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A4A4A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST CAROUSEL
/// ---------------------------------------------------------------------------
class _PostCarousel extends StatelessWidget {
  final List<PostModel> posts;
  final bool isLoading;
  final String? errorMessage;

  const _PostCarousel({
    required this.posts,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('No pictures yet today')),
      );
    }

    return SizedBox(
      height: 520,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.94),
        itemCount: posts.length,
        itemBuilder: (_, i) => _PostCard(post: posts[i]),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST CARD
/// ---------------------------------------------------------------------------
class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = EngagementController(
          postId: post.postId,
          initialPost: post,
        );
        controller.hydrate();
        return controller;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            _PostHeader(post: post),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DayAlbumViewerScreen(
                        posts: [post],
                        sessionStartedAt: DateTime.now(),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.imageUrls.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            const _EngagementBar(),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST HEADER (FOLLOW FIXED)
/// ---------------------------------------------------------------------------
class _PostHeader extends StatelessWidget {
  final PostModel post;

  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final isOwner = FirebaseAuth.instance.currentUser?.uid == post.authorId;

    return ChangeNotifierProvider(
      create: (_) =>
          FollowController()..loadFollower(targetUserId: post.authorId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileEntry(userId: post.authorId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    ChangeNotifierProvider(
                      create: (_) => UserAvatarController(post.authorId),
                      child: Consumer<UserAvatarController>(
                        builder: (_, avatar, __) => CircleAvatar(
                          radius: 16,
                          backgroundImage: post.authorAvatarUrl != null
                              ? NetworkImage(post.authorAvatarUrl!)
                              : null,
                          child: post.authorAvatarUrl == null
                              ? const Icon(Icons.person, size: 16)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post.authorName.isNotEmpty ? post.authorName : 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            if (!isOwner)
              Consumer<FollowController>(
                builder: (_, follow, __) => OutlinedButton(
                  onPressed: follow.isProcessing ? null : follow.toggle,
                  child: Text(follow.isFollowing ? 'Following' : 'Follow'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// ENGAGEMENT BAR
/// ---------------------------------------------------------------------------
class _EngagementBar extends StatelessWidget {
  const _EngagementBar();

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementController>();
    final post = engagement.post;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // LIKE
          _IconWithCount(
            icon: post.hasLiked ? Icons.favorite : Icons.favorite_border,
            color: post.hasLiked ? Colors.red : Colors.black,
            count: post.likeCount,
            onTap: engagement.isProcessing ? null : engagement.toggleLike,
          ),

          // REPIC
          _IconWithCount(
            icon: Icons.repeat,
            color: Colors.black,
            count: post.repicCount,
            onTap: engagement.isProcessing ? null : engagement.toggleRepic,
          ),

          // SAVE
          _IconWithCount(
            icon: post.hasSaved ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.black,
            count: post.saveCount,
            onTap: engagement.isProcessing ? null : engagement.toggleSave,
          ),

          // QUOTE COUNT (NO ACTION HERE)
          _IconWithCount(
            icon: Icons.chat_bubble_outline,
            color: Colors.black,
            count: post.quoteReplyCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<EngagementController>(),
                    child: QuoteReplyScreen(postId: post.postId),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IconWithCount extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  const _IconWithCount({
    required this.icon,
    required this.count,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// SUGGESTED USERS (PLACEHOLDER)
/// ---------------------------------------------------------------------------
class _SuggestedUsersSection extends StatelessWidget {
  const _SuggestedUsersSection();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: Text('Suggested users coming soon')),
    );
  }
}

/// ---------------------------------------------------------------------------
/// PROFILE BOTTOM SHEET + LOGOUT
/// ---------------------------------------------------------------------------
class _ProfileBottomSheet extends StatelessWidget {
  const _ProfileBottomSheet();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFF6F4EF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          SwitchListTile(
            value: theme.isDarkMode,
            onChanged: (_) => theme.toggleTheme(),
            title: const Text('Day / Night Mode'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// LOGOUT HANDLER
/// ---------------------------------------------------------------------------
Future<void> _handleLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Logout'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  await AuthService().logout();

  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }
}
