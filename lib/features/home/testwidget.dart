import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../feed/day_feed_controller.dart';
import '../feed/day_album_viewer_screen.dart';
import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';
import '../follow/follow_controller.dart';
import '../follow/mutual_controller.dart';
import '../profile/profile_controller.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../search/search_controllers.dart';
import '../../core/theme/theme_controller.dart';

/// ---------------------------------------------------------------------------
/// HOME SCREEN - CLEAN, PRODUCTION-READY, PICTURE-FIRST
/// ---------------------------------------------------------------------------
class HomeScreenV3Refined extends StatelessWidget {
  final VoidCallback onMenuTap;

  const HomeScreenV3Refined({super.key, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<DayFeedController>();
    final state = feed.state;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EF),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: feed.refresh,
          color: const Color(0xFF8B7355),
          strokeWidth: 2.5,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              /// X-STYLE DAY ALBUM PILL
              SliverToBoxAdapter(
                child: _XStyleDayAlbumPill(
                  count: feed.totalPostCount,
                  onTap: feed.refresh,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              /// HERO - POST CAROUSEL (SIMPLE, NO COMPLEX ANIMATIONS)
              SliverToBoxAdapter(
                child: _PostCarousel(
                  posts: state.posts,
                  isLoading: state.isLoading,
                  errorMessage: state.errorMessage,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              /// SUGGESTED USERS
              SliverToBoxAdapter(child: _SuggestedUsersSection()),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),

      /// FLOATING PROFILE BUTTON (CREATIVE ALTERNATIVE TO DRAWER)
      floatingActionButton: _FloatingProfileButton(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFF6F4EF),
      leading: IconButton(
        icon: const Icon(
          Icons.menu_rounded,
          color: Color(0xFF3D3D3D),
          size: 26,
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
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF3D3D3D),
                size: 25,
              ),
              onPressed: () {
                // TODO: Navigate to notifications
              },
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFD84315),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF3D3D3D),
            size: 25,
          ),
          onPressed: () => _openSearch(context),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SearchControllers()),
            ChangeNotifierProvider(create: (_) => ProfileController()),
            ChangeNotifierProvider(create: (_) => MutualController()),
            ChangeNotifierProvider(create: (_) => FollowController()),
          ],
          child: const SearchScreen(),
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ProfileBottomSheet(),
    );
  }
}

/// ---------------------------------------------------------------------------
/// FLOATING PROFILE BUTTON - CREATIVE ALTERNATIVE TO DRAWER
/// ---------------------------------------------------------------------------
class _FloatingProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onTap: () => _showProfileSheet(context),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF8B7355), Color(0xFFA0876D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B7355).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: user?.photoURL != null
            ? ClipOval(child: Image.network(user!.photoURL!, fit: BoxFit.cover))
            : const Icon(Icons.person, color: Colors.white, size: 28),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ProfileBottomSheet(),
    );
  }
}

/// ---------------------------------------------------------------------------
/// PROFILE BOTTOM SHEET - MODERN ALTERNATIVE TO DRAWER
/// ---------------------------------------------------------------------------
class _ProfileBottomSheet extends StatelessWidget {
  const _ProfileBottomSheet();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = context.watch<ThemeController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFF6F4EF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          /// PROFILE HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFFE8E4D9),
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(
                              Icons.person,
                              size: 32,
                              color: Color(0xFF8B7355),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B7355),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFF6F4EF),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.videocam,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFF3D3D3D),
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7A7A7A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// STATS ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('Mutuals', '0'),
                _statItem('Following', '0'),
                _statItem('Followers', '0'),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(height: 1),

          /// MENU ITEMS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _menuTile(Icons.settings_outlined, 'Settings', () {}),
                _menuTile(Icons.message_outlined, 'Messenger', () {}),
                _menuTile(Icons.mail_outline, 'Mailbox', () {}),
                _menuTile(Icons.photo_library_outlined, 'Picctures', () {}),
                _menuTile(Icons.stars_outlined, 'Impact Piccters', () {}),

                const Divider(height: 24),

                /// DAY/NIGHT TOGGLE
                SwitchListTile(
                  value: theme.isDarkMode,
                  onChanged: (_) => theme.toggleTheme(),
                  title: const Text(
                    'Day / Night Mode',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  secondary: Icon(
                    theme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: const Color(0xFF8B7355),
                  ),
                ),

                const Divider(height: 24),

                _menuTile(
                  Icons.delete_outline,
                  'Delete Account',
                  () {},
                  danger: true,
                ),
                _menuTile(
                  Icons.logout,
                  'Logout',
                  () => FirebaseAuth.instance.signOut(),
                ),
                _menuTile(Icons.info_outline, 'About Us', () {}),

                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Piccture v0.4.9',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF3D3D3D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF7A7A7A)),
        ),
      ],
    );
  }

  Widget _menuTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: danger ? Colors.red : const Color(0xFF8B7355),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: danger ? Colors.red : const Color(0xFF3D3D3D),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// ---------------------------------------------------------------------------
/// X-STYLE DAY ALBUM PILL
/// ---------------------------------------------------------------------------
class _XStyleDayAlbumPill extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _XStyleDayAlbumPill({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFE8E3D6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD0C9B8), width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                size: 16,
                color: Color(0xFF8B7355),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Day Album has $count new picture${count > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A),
                  ),
                  textAlign: TextAlign.center,
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
/// POST CAROUSEL - SIMPLE, NO DRAG ANIMATIONS
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
      return const SizedBox(
        height: 600,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFF8B7355),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return SizedBox(
        height: 500,
        child: Center(
          child: Text(
            errorMessage!,
            style: const TextStyle(color: Color(0xFF7A7A7A)),
          ),
        ),
      );
    }

    if (posts.isEmpty) {
      return const SizedBox(
        height: 500,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 56,
                color: Color(0xFFB8A89A),
              ),
              SizedBox(height: 16),
              Text(
                'No pictures yet today',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF7A7A7A),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 600,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.92),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _PostCard(post: posts[index]),
          );
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST CARD - CLEAN, SIMPLE
/// ---------------------------------------------------------------------------
class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFFDF9),
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          _CompactEngagementBar(post: post),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST HEADER
/// ---------------------------------------------------------------------------
class _PostHeader extends StatelessWidget {
  final PostModel post;

  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid == post.authorId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _openProfile(context),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE8E4D9),
              backgroundImage:
                  post.authorAvatarUrl != null &&
                      post.authorAvatarUrl!.isNotEmpty
                  ? NetworkImage(post.authorAvatarUrl!)
                  : null,
              child:
                  post.authorAvatarUrl == null || post.authorAvatarUrl!.isEmpty
                  ? const Icon(Icons.person, size: 18, color: Color(0xFF8B7355))
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _openProfile(context),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      post.authorName.isNotEmpty ? post.authorName : 'Unknown',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                  ),
                  if (post.isVerifiedOwner) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      size: 14,
                      color: Color(0xFF8B7355),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!isOwner) _FollowButton(authorId: post.authorId),
          _PostMenu(post: post, isOwner: isOwner),
        ],
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => ProfileController()..loadProfile(post.authorId),
            ),
            ChangeNotifierProvider(
              create: (_) => MutualController()..loadMutuals(post.authorId),
            ),
            ChangeNotifierProvider(
              create: (_) => FollowController()..load(post.authorId),
            ),
          ],
          child: ProfileScreen(userId: post.authorId),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// FOLLOW BUTTON
/// ---------------------------------------------------------------------------
class _FollowButton extends StatelessWidget {
  final String authorId;

  const _FollowButton({required this.authorId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FollowController()..load(authorId),
      child: Consumer<FollowController>(
        builder: (_, controller, __) {
          return TextButton(
            onPressed: controller.isFollowing
                ? () => controller.unfollow(authorId)
                : () => controller.follow(authorId),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B7355),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Text(
              controller.isFollowing ? 'Following' : 'Follow',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST MENU
/// ---------------------------------------------------------------------------
class _PostMenu extends StatelessWidget {
  final PostModel post;
  final bool isOwner;

  const _PostMenu({required this.post, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF7A7A7A)),
      onSelected: (value) {
        if (value == 'delete') {
          _showDeleteDialog(context);
        } else if (value == 'share') {
          context.read<EngagementController>().sharePost(post);
        }
      },
      itemBuilder: (_) => [
        if (isOwner)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete Post', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_outlined, size: 18),
              SizedBox(width: 8),
              Text('Share'),
            ],
          ),
        ),
        if (!isOwner)
          const PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 18),
                SizedBox(width: 8),
                Text('Report'),
              ],
            ),
          ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Post deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// COMPACT ENGAGEMENT BAR
/// ---------------------------------------------------------------------------
class _CompactEngagementBar extends StatelessWidget {
  final PostModel post;

  const _CompactEngagementBar({required this.post});

  @override
  Widget build(BuildContext context) {
    final engagement = context.read<EngagementController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _icon(Icons.favorite_border, () => engagement.likePost(post)),
          _icon(Icons.chat_bubble_outline, () {}),
          _icon(Icons.bookmark_border, () => engagement.savePost(post)),
          _icon(Icons.share_outlined, () => engagement.sharePost(post)),
        ],
      ),
    );
  }

  Widget _icon(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 20, color: const Color(0xFF6B6B6B)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: onTap,
    );
  }
}

/// ---------------------------------------------------------------------------
/// SUGGESTED USERS
/// ---------------------------------------------------------------------------
class _SuggestedUsersSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested for you',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A4A4A),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 8,
              itemBuilder: (context, index) {
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFE8E4D9),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF8B7355),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'User ${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5A5A5A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
