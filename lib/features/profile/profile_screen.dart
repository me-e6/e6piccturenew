/* import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:e6piccturenew/features/follow/mutuals_list_screen.dart';
import 'package:e6piccturenew/features/follow/mutual_controller.dart';
import '../../features/follow/following_list_screen.dart';
import '../../features/follow/follower_list_screen.dart';

import 'profile_controller.dart';
import 'widgets/profile_identity_banner.dart';
import 'widgets/profile_tabs_bar.dart';
import 'widgets/profile_tab_content.dart';
import '../follow/follow_controller.dart';
import 'edit_profile_screen.dart';

/// ---------------------------------------------------------------------------
/// PROFILE SCREEN (API-AWARE, CONTROLLER-DRIVEN)
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
        ChangeNotifierProvider(
          create: (_) => ProfileController()..loadProfile(userId),
        ),
        ChangeNotifierProvider(
          create: (_) => MutualController()..loadMutuals(userId),
        ),
        if (!isOwner)
          ChangeNotifierProvider(
            create: (_) => FollowController()..load(userId),
          ),
      ],
      child: const _ProfileScreenBody(),
    );
  }
}

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
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid == user.uid;

    final follow = !isOwner ? context.watch<FollowController>() : null;
    final mutuals = context.watch<MutualController>();

    /// ------------------------------------------------------------
    /// CONTROLLER → UI NAVIGATION WIRING (ONCE)
    /// ------------------------------------------------------------
    profile.onEditProfileRequested ??= () {
   //  onEditProfile:
      isOwner
          ? () {
              final profile = context.read<ProfileController>();

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
          : null;
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),

            /// ------------------------------------------------------------
            /// PROFILE IDENTITY BANNER (FINAL)
            /// ------------------------------------------------------------
            ProfileIdentityBanner(
              displayName: user.displayName,
              handle: user.handle,
              avatarUrl: user.profileImageUrl,
              isVerified: user.isVerified,
              hasVideoDp: false, // future-safe
              bio: user.bio,

              /// Ownership
              isOwner: isOwner,

              /// Follow state (external only)
              isFollowing: follow?.isFollowing ?? false,

              /// Avatar / banner update
              isUpdatingAvatar: profile.isUpdatingPhoto,
              isUpdatingBanner: profile.isUpdatingBanner,
              onEditAvatar: isOwner ? profile.updatePhoto : null,

              /// Actions
              onEditProfile: isOwner ? profile.requestEditProfile : null,
              onFollowToggle: !isOwner ? profile.toggleFollow : null,
            ),

            const SizedBox(height: 24),

            /// ------------------------------------------------------------
            /// STATS ROW
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
            /// TABS
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
/// PROFILE STATS ROW
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
import 'package:firebase_auth/firebase_auth.dart';

import 'package:e6piccturenew/features/follow/mutuals_list_screen.dart';
import 'package:e6piccturenew/features/follow/mutual_controller.dart';
import '../../features/follow/following_list_screen.dart';
import '../../features/follow/follower_list_screen.dart';

import 'profile_controller.dart';
import 'widgets/profile_identity_banner.dart';
import 'widgets/profile_tabs_bar.dart';
import 'widgets/profile_tab_content.dart';
import '../follow/follow_controller.dart';
import 'edit_profile_screen.dart';

/// ---------------------------------------------------------------------------
/// PROFILE SCREEN (API-AWARE, CONTROLLER-DRIVEN)
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
        ChangeNotifierProvider(
          create: (_) => ProfileController()..loadProfile(userId),
        ),
        ChangeNotifierProvider(
          create: (_) => MutualController()..loadMutuals(userId),
        ),
        if (!isOwner)
          ChangeNotifierProvider(
            create: (_) => FollowController()..load(userId),
          ),
      ],
      child: const _ProfileScreenBody(),
    );
  }
}

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
              isVerified: user.isVerified,
              hasVideoDp: false,
              bio: user.bio,

              isOwner: isOwner,
              isFollowing: follow?.isFollowing ?? false,

              isUpdatingAvatar: profile.isUpdatingPhoto,
              isUpdatingBanner: profile.isUpdatingBanner,
              onEditAvatar: isOwner ? profile.updatePhoto : null,

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

              onFollowToggle: !isOwner ? profile.toggleFollow : null,
            ),

            const SizedBox(height: 24),

            /// ------------------------------------------------------------
            /// STATS ROW
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
            /// TABS
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
/// PROFILE STATS ROW
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
