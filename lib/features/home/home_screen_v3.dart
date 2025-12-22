import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../feed/day_feed_controller.dart';
import '../post/create/post_model.dart';
import '../engagement/engagement_controller.dart';
import '../feed/day_album_viewer_screen.dart';
import '../follow/follow_controller.dart';
import '../profile/profile_screen.dart';
import '../user/user_avatar_controller.dart';
import '../follow/mutual_controller.dart';
import '../profile/profile_controller.dart';
import '../search/search_screen.dart';
import '../search/search_controllers.dart';
import '../../core/theme/theme_controller.dart';
import '../../features/feed/day_album_tracker.dart';
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
    final albumStatus = state.albumStatus; // Access from state

    return Scaffold(
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
                    onTap: feed.dismissAlbumPill, // Controller handles logic
                  ),
                ),
              /* SliverToBoxAdapter(
                child: _XStyleDayAlbumPill(
                  count: feed.totalPostCount,
                  onTap: feed.refresh,
                ),
              ), */
              /* SliverToBoxAdapter(
                child: _TodayAlbumContextPill(
                  count: feed.totalPostCount,
                  onTap: feed.refresh,
                ),
              ), */
              /* SliverToBoxAdapter(
                child: _DayAlbumBanner(
                  count: feed.totalPostCount,
                  hasNewPosts: state.hasNewPosts,
                ),
              ), */
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              SliverToBoxAdapter(
                child: _PostCarousel(
                  posts: state.posts,
                  isLoading: state.isLoading,
                  errorMessage: state.errorMessage,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverToBoxAdapter(child: _SuggestedUsersSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  /*   AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
      title: const Text(
        'PICCTURE',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => openSearch(context),
        ),
        IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
      ],
    );
  } */

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
        IconButton(
          icon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF3D3D3D),
            size: 25,
          ),
          onPressed: () => _openSearch(context),
        ),
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

/* /// ---------------------------------------------------------------------------
/// DAY ALBUM BANNER
/// ---------------------------------------------------------------------------
class _DayAlbumBanner extends StatelessWidget {
  final int count;
  final bool hasNewPosts;

  const _DayAlbumBanner({required this.count, required this.hasNewPosts});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.photo_library_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasNewPosts
                  ? 'New pictures available'
                  : 'You have $count pictures to review in the last 24 hours.',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
} */

// ---------------------------------------------------------------------------
/// X-STYLE DAY ALBUM PILL (COMPACT LIKE TWITTER)
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
            mainAxisAlignment: MainAxisAlignment.center,
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
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* /// ---------------------------------------------------------------------------
/// X-STYLE DAY ALBUM PILL (COMPACT LIKE TWITTER)
/// ---------------------------------------------------------------------------
class _XStyleDayAlbumPill extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _XStyleDayAlbumPill({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                size: 14,
                color: Color(0xFF8B7355),
              ),
              const SizedBox(width: 6),
              Text(
                'Day Album has $count new ${count > 1 ? 'Picctures' : 'Piccture'}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A4A4A),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} */
/* 
/// ---------------------------------------------------------------------------
/// TODAY’S ALBUM — X/TWITTER STYLE CONTEXT PILL
/// ---------------------------------------------------------------------------
class _TodayAlbumContextPill extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _TodayAlbumContextPill({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEAE6DC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_library_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                '$count New Piccters ${count > 1 ? 's' : ''} in Day album '
                '$count more picture${count > 1 ? 's' : ''} from today',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} */

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
        itemBuilder: (_, index) {
          return _PostCard(post: posts[index]);
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// POST CARD (WITH EDGE NUDGE + DOTS)
/// ---------------------------------------------------------------------------
class _PostCard extends StatefulWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  late final PageController _imageController;
  int _imageIndex = 0;

  late final AnimationController _nudgeController;
  late final Animation<double> _nudgeAnimation;

  bool _nudgePlayed = false;
  bool _userInteracted = false;

  @override
  void initState() {
    super.initState();

    _imageController = PageController();

    _nudgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _nudgeAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -8, end: 0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 0, end: 8), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
      ],
    ).animate(CurvedAnimation(parent: _nudgeController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_nudgePlayed && mounted) {
        _nudgePlayed = true;
        _nudgeController.forward();
      }
    });
  }

  void _stopNudge() {
    if (_userInteracted) return;
    _userInteracted = true;
    _nudgeController.stop();
  }

  @override
  void dispose() {
    _imageController.dispose();
    _nudgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _PostHeader(post: widget.post),

          Expanded(
            child: AnimatedBuilder(
              animation: _nudgeAnimation,
              builder: (_, child) {
                return Transform.translate(
                  offset: Offset(
                    _userInteracted ? 0 : _nudgeAnimation.value,
                    0,
                  ),
                  child: child,
                );
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _stopNudge(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DayAlbumViewerScreen(
                        posts: [widget.post],
                        sessionStartedAt: DateTime.now(),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _imageController,
                        itemCount: widget.post.imageUrls.length,
                        onPageChanged: (i) {
                          _stopNudge();
                          setState(() => _imageIndex = i);
                        },
                        itemBuilder: (_, i) {
                          return Image.network(
                            widget.post.imageUrls[i],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: _ImageDots(
                          count: widget.post.imageUrls.length,
                          activeIndex: _imageIndex,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          _EngagementBar(post: widget.post),
        ],
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  final PostModel post;

  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final bool isOwner =
        FirebaseAuth.instance.currentUser?.uid == post.authorId;

    return ChangeNotifierProvider(
      create: (_) => FollowController()..load(post.authorId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            /// AUTHOR AVATAR + NAME
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider(
                            create: (_) =>
                                ProfileController()..loadProfile(post.authorId),
                          ),
                          ChangeNotifierProvider(
                            create: (_) =>
                                MutualController()..loadMutuals(post.authorId),
                          ),
                          ChangeNotifierProvider(
                            create: (_) =>
                                FollowController()..load(post.authorId),
                          ),
                        ],
                        child: ProfileScreen(userId: post.authorId),
                      ),
                    ),
                  );
                },

                child: Row(
                  children: [
                    /// AVATAR
                    ChangeNotifierProvider(
                      create: (_) => UserAvatarController(post.authorId),
                      child: Consumer<UserAvatarController>(
                        builder: (_, avatar, __) {
                          return CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage:
                                post.authorAvatarUrl != null &&
                                    post.authorAvatarUrl!.isNotEmpty
                                ? NetworkImage(post.authorAvatarUrl!)
                                : null,
                            child:
                                post.authorAvatarUrl == null ||
                                    post.authorAvatarUrl!.isEmpty
                                ? const Icon(Icons.person, size: 16)
                                : null,
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    Row(
                      children: [
                        Text(
                          post.authorName.isNotEmpty
                              ? post.authorName
                              : 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (post.isVerifiedOwner) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            /// FOLLOW + MENU
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<FollowController>(
                  builder: (_, follow, __) {
                    if (isOwner) return const SizedBox.shrink();

                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: follow.isProcessing
                          ? null
                          : () {
                              follow.isFollowing
                                  ? follow.unfollow(post.authorId)
                                  : follow.follow(post.authorId);
                            },

                      child: Text(
                        follow.isFollowing ? 'Following' : 'Follow',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'copy', child: Text('Copy link')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// IMAGE DOTS
/// ---------------------------------------------------------------------------
class _ImageDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _ImageDots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == activeIndex ? 7 : 4.5,
          height: i == activeIndex ? 7 : 4.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == activeIndex
                ? const Color.fromARGB(192, 27, 107, 228).withValues(alpha: 0.9)
                : const Color.fromARGB(255, 47, 77, 212).withValues(alpha: 0.4),
          ),
        );
      }),
    );
  }
}

/// ---------------------------------------------------------------------------
/// ENGAGEMENT BAR
/// ---------------------------------------------------------------------------
class _EngagementBar extends StatelessWidget {
  final PostModel post;

  const _EngagementBar({required this.post});

  @override
  Widget build(BuildContext context) {
    final engagement = context.watch<EngagementController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _EngagementIcon(
            icon: post.hasLiked ? Icons.favorite : Icons.favorite_border,
            onTap: () => post.hasLiked
                ? engagement.dislikePost(post)
                : engagement.likePost(post),
            color: post.hasLiked ? Colors.red : null,
          ),
          _EngagementIcon(icon: Icons.chat_bubble_outline, onTap: () {}),
          _EngagementIcon(icon: Icons.repeat, onTap: () {}),
          _EngagementIcon(
            icon: post.hasSaved ? Icons.bookmark : Icons.bookmark_border,
            onTap: () => engagement.savePost(post),
          ),
          _EngagementIcon(
            icon: Icons.more_horiz,
            onTap: () => engagement.sharePost(post),
          ),
        ],
      ),
    );
  }
}

class _EngagementIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _EngagementIcon({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// SUGGESTED USERS
/// ---------------------------------------------------------------------------
class _SuggestedUsersSection extends StatelessWidget {
  const _SuggestedUsersSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Suggested for You',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (_, __) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('User')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// LOGOUT HANDLER (CONFIRMED + SAFE NAV RESET)
/// ---------------------------------------------------------------------------
/* Future<void> _handleLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Logout',
            style: TextStyle(color: Color(0xFF8B7355)),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    // 🔐 Firebase sign out
    await FirebaseAuth.instance.signOut();

    // 🧹 Clear entire navigation stack & go to Auth gate
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  } catch (e) {
    debugPrint('❌ Logout failed: $e');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }
} */

Future<void> _handleLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Logout',
            style: TextStyle(color: Color(0xFF8B7355)),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await AuthService().logout();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  } catch (e) {
    debugPrint('❌ Logout failed: $e');
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

                _menuTile(Icons.logout, 'Logout', () => _handleLogout(context)),

                /*   _menuTile(
                  Icons.logout,
                  'Logout',
                  () => FirebaseAuth.instance.signOut(),
                ), */
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

String resolvePostAuthorLabel({
  required PostModel post,
  required String? currentUserId,
}) {
  if (currentUserId != null && post.authorId == currentUserId) {
    return 'You';
  }
  return post.authorName;
}

void openSearch(BuildContext context) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId != null) {
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
}
