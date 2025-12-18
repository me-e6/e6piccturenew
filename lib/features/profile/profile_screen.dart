/* Profile_screen.dart */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/profile_tabs_bar.dart';
import 'widgets/profile_tab_content.dart';

import 'profile_controller.dart';
import 'widgets/profile_identity_banner.dart';
import '../post/create/post_model.dart';

/// ---------------------------------------------------------------------------
/// PROFILE SCREEN (API-AWARE, CONTROLLER-DRIVEN)
/// ---------------------------------------------------------------------------
class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileController()..loadProfile(userId),
      child: const _ProfileScreenBody(),
    );
  }
}

class _ProfileScreenBody extends StatelessWidget {
  const _ProfileScreenBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();

    if (controller.isLoading || controller.user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final user = controller.user!;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid == user.uid;

    // ------------------------------------------------------------
    // API-AWARE IDENTITY SNAPSHOT
    // ------------------------------------------------------------

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),
            ProfileIdentityBanner(
              displayName: user.displayName ?? 'User',
              handle: user.handle,
              avatarUrl: user.profileImageUrl,
              isVerified: user.isVerified,
              hasVideoDp: false, // future
              bio: user.bio,
              isOwner: isOwner,
              isFollowing: controller.isFollowing,
              isUpdatingAvatar: controller.isUpdatingPhoto,
              onEditAvatar: isOwner ? controller.updatePhoto : null,
              onEditProfile: isOwner ? controller.editProfile : null,
              onFollowToggle: !isOwner ? controller.toggleFollow : null,
            ),

            const SizedBox(height: 24),

            /// --------------------------------------------------------
            /// STATS
            /// --------------------------------------------------------
            _ProfileStatsRow(
              posts: controller.posts.length,
              reposts: controller.reposts.length,
              saved: controller.saved.length,
            ),

            const SizedBox(height: 24),

            /// --------------------------------------------------------
            /// Profile tabs
            /// --------------------------------------------------------
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
  final int reposts;
  final int saved;

  const _ProfileStatsRow({
    required this.posts,
    required this.reposts,
    required this.saved,
  });

  Widget _stat(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
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
          _stat('Repics', reposts),
          _stat('Saved', saved),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// PROFILE POSTS GRID (BASIC)
/// ---------------------------------------------------------------------------
class _ProfilePostsGrid extends StatelessWidget {
  final List<PostModel> posts;

  const _ProfilePostsGrid({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('No posts yet'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (_, index) {
        final post = posts[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: post.imageUrls.isNotEmpty
              ? Image.network(post.imageUrls.first, fit: BoxFit.cover)
              : Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image),
                ),
        );
      },
    );
  }
}
