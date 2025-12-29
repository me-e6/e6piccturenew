import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'video_dp_viewer_screen.dart';
import 'package:e6piccturenew/features/follow/mutuals_list_screen.dart';
import 'package:e6piccturenew/features/follow/mutual_controller.dart';
import '../../features/follow/following_list_screen.dart';
import '../../features/follow/follower_list_screen.dart';
import 'profile_controller.dart';
import 'widgets/profile_identity_banner.dart';
import 'widgets/profile_tabs_bar.dart';
import 'widgets/profile_tab_content.dart';
import 'edit_profile_screen.dart';

/// ============================================================================
/// PROFILE SCREEN - v2 (With Gazetteer Badge)
/// ============================================================================
class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return const _ProfileScreenBody();
  }
}

class _ProfileScreenBody extends StatelessWidget {
  const _ProfileScreenBody();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final mutuals = context.watch<MutualController>();

    if (profile.isLoading || profile.user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final user = profile.user!;
    final isOwner = profile.isOwner;
    final bool hasVideoDp =
        user.videoDpUrl != null && user.videoDpUrl!.isNotEmpty;

    // ✅ Check if user is a Gazetteer
    final bool isGazetteer =
        user.type == 'gazetteer' || user.role == 'gazetteer';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                ProfileIdentityBanner(
                  displayName: user.displayName,
                  handle: user.handle,
                  avatarUrl: user.profileImageUrl,
                  bannerUrl: user.profileBannerUrl,
                  bio: user.bio,
                  isVerified: user.isVerified,
                  isGazetteer: isGazetteer, // ✅ NEW
                  hasVideoDp: hasVideoDp,
                  isUpdatingVideoDp: profile.isUpdatingVideoDp,
                  isOwner: isOwner,
                  isFollowing: profile.isFollowing,
                  isUpdatingAvatar: profile.isUpdatingPhoto,
                  isUpdatingBanner: profile.isUpdatingBanner,
                  onEditAvatar: isOwner
                      ? () => profile.updatePhoto(context)
                      : null,
                  onEditBanner: isOwner
                      ? () => profile.updateBanner(context)
                      : null,
                  onVideoDpTap: hasVideoDp
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VideoDpViewerScreen(videoUrl: user.videoDpUrl!),
                          ),
                        )
                      : null,
                  onEditVideoDp: isOwner
                      ? () => profile.updateVideoDp(context)
                      : null,
                  onReplaceVideo: () => profile.replaceVideoDp(context),
                  onDeleteVideo: () => profile.deleteVideoDp(context),
                  onEditProfile: isOwner
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: profile,
                              child: const EditProfileScreen(),
                            ),
                          ),
                        )
                      : null,
                  onFollowToggle: !isOwner ? profile.toggleFollow : null,
                ),
                const SizedBox(height: 24),
                _ProfileStatsRow(
                  posts: profile.posts.length,
                  mutuals: mutuals.count,
                  followers: profile.followersCount,
                  following: profile.followingCount,
                  onMutualsTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MutualsListScreen(userId: user.uid),
                    ),
                  ),
                  onFollowersTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FollowersListScreen(userId: user.uid),
                    ),
                  ),
                  onFollowingTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FollowingListScreen(userId: user.uid),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const ProfileTabsBar(),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const ProfileTabContent(),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Text(
              _formatCount(value),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
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
