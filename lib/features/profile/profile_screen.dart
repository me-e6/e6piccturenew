/* import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ------------------------------------------------------------
/// VIDEO DP VIEWER (UI ONLY)
/// ------------------------------------------------------------
import 'video_dp_viewer_screen.dart';

/// ------------------------------------------------------------
/// FOLLOW / MUTUALS FEATURES
/// ------------------------------------------------------------
import 'package:e6piccturenew/features/follow/mutuals_list_screen.dart';
import 'package:e6piccturenew/features/follow/mutual_controller.dart';
import '../../features/follow/following_list_screen.dart';
import '../../features/follow/follower_list_screen.dart';

/// ------------------------------------------------------------
/// PROFILE FEATURE
/// ------------------------------------------------------------
import 'profile_controller.dart';
import 'widgets/profile_identity_banner.dart';
import 'widgets/profile_tabs_bar.dart';
import 'widgets/profile_tab_content.dart';
import '../follow/follow_controller.dart';
import 'edit_profile_screen.dart';

/// ---------------------------------------------------------------------------
/// PROFILE SCREEN
///
/// • Pure UI
/// • Controller-driven
/// • No business logic
/// • Ownership derived from FirebaseAuth
/// ---------------------------------------------------------------------------
class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid == userId;

    return MultiProvider(
      providers: [
        /// Main profile controller
        ChangeNotifierProvider(
          create: (_) => ProfileController()..loadProfile(userId),
        ),

        /// Mutual graph
        ChangeNotifierProvider(
          create: (_) => MutualController()..loadMutuals(userId),
        ),

        /// Follow controller (external profiles only)
        if (!isOwner)
          ChangeNotifierProvider(
            create: (_) => FollowController()..load(userId),
          ),
      ],/*  */
      child: const _ProfileScreenBody(),
    );
  }
}

/// ---------------------------------------------------------------------------
/// PROFILE SCREEN BODY
/// ---------------------------------------------------------------------------
class _ProfileScreenBody extends StatelessWidget {
  const _ProfileScreenBody();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();

    if (profile.isLoading || profile.user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final user = profile.user!;
    final isOwner = profile.isOwner;
    final follow = !isOwner ? context.watch<FollowController>() : null;
    final mutuals = context.watch<MutualController>();

    final bool hasVideoDp =
        user.videoDpUrl != null && user.videoDpUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),

            /// ------------------------------------------------------------
            /// PROFILE IDENTITY BANNER
            /// ------------------------------------------------------------
            ProfileIdentityBanner(
              displayName: user.displayName,
              handle: user.handle,
              avatarUrl: user.profileImageUrl,
              bannerUrl: user.profileBannerUrl,
              bio: user.bio,

              /// Verification
              isVerified: user.isVerified,

              /// Video DP
              hasVideoDp: hasVideoDp,
              isUpdatingVideoDp: profile.isUpdatingVideoDp,

              /// Ownership / follow
              isOwner: isOwner,
              isFollowing: follow?.isFollowing ?? false,

              /// Loading flags
              isUpdatingAvatar: profile.isUpdatingPhoto,
              isUpdatingBanner: profile.isUpdatingBanner,

              /// Avatar / banner actions
              onEditAvatar: isOwner ? () => profile.updatePhoto(context) : null,

              onEditBanner: isOwner
                  ? () => profile.updateBanner(context)
                  : null,

              /// Video DP interactions
              onVideoDpTap: hasVideoDp
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VideoDpViewerScreen(videoUrl: user.videoDpUrl!),
                        ),
                      );
                    }
                  : null,

              onEditVideoDp: isOwner
                  ? () => profile.showVideoDpActions(context)
                  : null,

              onReplaceVideo: () => profile.replaceVideoDp(context),
              onDeleteVideo: () => profile.deleteVideoDp(context),

              /// Profile actions
              onEditProfile: isOwner
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: profile,
                            child: const EditProfileScreen(),
                          ),
                        ),
                      );
                    }
                  : null,

              //   onFollowToggle: !isOwner ? profile.toggleFollow : null,
              onFollowToggle: () => profile.toggleFollow(),
            ),

            const SizedBox(height: 24),

            /// ------------------------------------------------------------
            /// PROFILE STATS
            /// ------------------------------------------------------------
            _ProfileStatsRow(
              posts: profile.posts.length,
              mutuals: mutuals.count,
              followers: profile.followersCount,
              following: profile.followingCount,
              onMutualsTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MutualsListScreen(userId: user.uid),
                  ),
                );
              },
              onFollowersTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowersListScreen(userId: user.uid),
                  ),
                );
              },
              onFollowingTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowingListScreen(userId: user.uid),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            /// ------------------------------------------------------------
            /// PROFILE CONTENT
            /// ------------------------------------------------------------
            const ProfileTabsBar(),
            const SizedBox(height: 12),
            const ProfileTabContent(),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// PROFILE STATS ROW (UI-ONLY)
/// ---------------------------------------------------------------------------
class _ProfileStatsRow extends StatelessWidget {
  final int posts;
  final int mutuals;
  final int followers;
  final int following;

  final VoidCallback onMutualsTap;
  final VoidCallback onFollowersTap;
  final VoidCallback onFollowingTap;

  const _ProfileStatsRow({
    required this.posts,
    required this.mutuals,
    required this.followers,
    required this.following,
    required this.onMutualsTap,
    required this.onFollowersTap,
    required this.onFollowingTap,
  });

  Widget _stat(String label, int value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat('Posts', posts),
          _stat('Mutuals', mutuals, onTap: onMutualsTap),
          _stat('Followers', followers, onTap: onFollowersTap),
          _stat('Following', following, onTap: onFollowingTap),
        ],
      ),
    );
  }
}
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// ------------------------------------------------------------
/// VIDEO DP VIEWER (UI ONLY)
/// ------------------------------------------------------------
import 'video_dp_viewer_screen.dart';

/// ------------------------------------------------------------
/// FOLLOW / MUTUALS FEATURES
/// ------------------------------------------------------------
import 'package:e6piccturenew/features/follow/mutuals_list_screen.dart';
import 'package:e6piccturenew/features/follow/mutual_controller.dart';
import '../../features/follow/following_list_screen.dart';
import '../../features/follow/follower_list_screen.dart';

/// ------------------------------------------------------------
/// PROFILE FEATURE
/// ------------------------------------------------------------
import 'profile_controller.dart';
import 'widgets/profile_identity_banner.dart';
import 'widgets/profile_tabs_bar.dart';
import 'widgets/profile_tab_content.dart';
import '../follow/follow_controller.dart';
import 'edit_profile_screen.dart';

/// ---------------------------------------------------------------------------
/// PROFILE SCREEN
///
/// ✅ UI ONLY
/// ❌ NO providers created here
/// ❌ NO controller lifecycle here
/// ---------------------------------------------------------------------------
class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return const _ProfileScreenBody();
  }
}

/// ---------------------------------------------------------------------------
/// PROFILE SCREEN BODY
/// ---------------------------------------------------------------------------
class _ProfileScreenBody extends StatelessWidget {
  const _ProfileScreenBody();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final mutuals = context.watch<MutualController>();
    final follow = context.watch<FollowController>();

    if (profile.isLoading || profile.user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final user = profile.user!;
    final isOwner = profile.isOwner;

    final bool hasVideoDp =
        user.videoDpUrl != null && user.videoDpUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),

            /// ------------------------------------------------------------
            /// PROFILE IDENTITY BANNER
            /// ------------------------------------------------------------
            ProfileIdentityBanner(
              displayName: user.displayName,
              handle: user.handle,
              avatarUrl: user.profileImageUrl,
              bannerUrl: user.profileBannerUrl,
              bio: user.bio,

              /// Verification
              isVerified: user.isVerified,

              /// Video DP
              hasVideoDp: hasVideoDp,
              isUpdatingVideoDp: profile.isUpdatingVideoDp,

              /// Ownership / follow
              isOwner: isOwner,
              isFollowing: follow?.isFollowing ?? false,

              /// Loading flags
              isUpdatingAvatar: profile.isUpdatingPhoto,
              isUpdatingBanner: profile.isUpdatingBanner,

              /// Avatar / banner actions
              /// Avatar / banner actions
              onEditAvatar: isOwner ? () => profile.updatePhoto(context) : null,

              onEditBanner: isOwner
                  ? () => profile.updateBanner(context)
                  : null,
              /*   onEditAvatar: isOwner ? profile.updatePhoto : null,
              onEditBanner: isOwner ? profile.updateBanner : null,
              */
              /// Video DP interactions
              onVideoDpTap: hasVideoDp
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VideoDpViewerScreen(videoUrl: user.videoDpUrl!),
                        ),
                      );
                    }
                  : null,

              onEditVideoDp: isOwner
                  ? () => profile.showVideoDpActions(context)
                  : null,

              onReplaceVideo: () => profile.replaceVideoDp(context),
              onDeleteVideo: () => profile.deleteVideoDp(context),

              /// Profile edit
              onEditProfile: isOwner
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: profile,
                            child: const EditProfileScreen(),
                          ),
                        ),
                      );
                    }
                  : null,

              /// Follow / unfollow
              onFollowToggle: !isOwner ? profile.toggleFollow : null,
            ),

            const SizedBox(height: 24),

            /// ------------------------------------------------------------
            /// PROFILE STATS
            /// ------------------------------------------------------------
            _ProfileStatsRow(
              posts: profile.posts.length,
              mutuals: mutuals.count,
              followers: profile.followersCount,
              following: profile.followingCount,
              onMutualsTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MutualsListScreen(userId: user.uid),
                  ),
                );
              },
              onFollowersTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowersListScreen(userId: user.uid),
                  ),
                );
              },
              onFollowingTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowingListScreen(userId: user.uid),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            /// ------------------------------------------------------------
            /// PROFILE CONTENT
            /// ------------------------------------------------------------
            const ProfileTabsBar(),
            const SizedBox(height: 12),
            const ProfileTabContent(),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// PROFILE STATS ROW (UI-ONLY)
/// ---------------------------------------------------------------------------
class _ProfileStatsRow extends StatelessWidget {
  final int posts;
  final int mutuals;
  final int followers;
  final int following;

  final VoidCallback onMutualsTap;
  final VoidCallback onFollowersTap;
  final VoidCallback onFollowingTap;

  const _ProfileStatsRow({
    required this.posts,
    required this.mutuals,
    required this.followers,
    required this.following,
    required this.onMutualsTap,
    required this.onFollowersTap,
    required this.onFollowingTap,
  });

  Widget _stat(String label, int value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat('Posts', posts),
          _stat('Mutuals', mutuals, onTap: onMutualsTap),
          _stat('Followers', followers, onTap: onFollowersTap),
          _stat('Following', following, onTap: onFollowingTap),
        ],
      ),
    );
  }
}
