import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_scaffold.dart';

import 'profile_controller.dart';
import 'user_model.dart';

import '../post/create/post_model.dart';
import '../post/details/post_details_screen.dart';

import '../follow/follow_controller.dart';
import '../admin/admin_user_controller.dart';

class ProfileScreen extends StatelessWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProfileController()..loadProfile(uid),
        ),
        ChangeNotifierProvider(create: (_) => FollowController()..load(uid)),

        ChangeNotifierProvider(create: (_) => AdminUserController()),
      ],
      child: Consumer2<ProfileController, FollowController>(
        builder: (context, controller, follow, _) {
          if (controller.isLoading || controller.user == null) {
            return const AppScaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = controller.user!;
          return AppScaffold(
            appBar: AppBar(title: Text(user.displayName), centerTitle: false),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  _ProfileHeader(
                    user: user,
                    controller: controller,
                    follow: follow,
                    targetUid: uid,
                  ),

                  const SizedBox(height: 20),

                  _Tabs(controller: controller),

                  _TabContent(controller: controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PROFILE HEADER
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final ProfileController controller;
  final FollowController follow;
  final String targetUid;

  const _ProfileHeader({
    required this.user,
    required this.controller,
    required this.follow,
    required this.targetUid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final currentUid = follow.currentUid;
    final isOwnProfile = currentUid == targetUid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: isOwnProfile ? () => controller.updatePhoto(user.uid) : null,
            child: CircleAvatar(
              radius: 46,
              backgroundImage: user.photoUrl.isNotEmpty
                  ? NetworkImage(user.photoUrl)
                  : const AssetImage("assets/profile_placeholder.png")
                        as ImageProvider,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(user.displayName, style: theme.textTheme.titleLarge),
              if (user.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, size: 20),
                const SizedBox(width: 4),
                Text(
                  "Gazetter",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              user.type.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onPrimary,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat(context, "Posts", controller.postCount),
              _stat(context, "RePics", controller.repostCount),
              _stat(context, "Followers", controller.followersCount),
              _stat(context, "Following", controller.followingCount),
            ],
          ),

          const SizedBox(height: 18),

          if (!isOwnProfile)
            _FollowButton(follow: follow, targetUid: targetUid),

          if (controller.isAdminViewing)
            _AdminVerifyButton(user: user, targetUid: targetUid),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, int count) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text("$count", style: theme.textTheme.titleMedium),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FOLLOW BUTTON
// ---------------------------------------------------------------------------

class _FollowButton extends StatelessWidget {
  final FollowController follow;
  final String targetUid;

  const _FollowButton({required this.follow, required this.targetUid});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 42,
      width: 160,
      child: ElevatedButton(
        onPressed: follow.isLoading
            ? null
            : () {
                if (follow.isFollowing) {
                  follow.unfollow(targetUid);
                } else {
                  follow.follow(targetUid);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: follow.isFollowing
              ? scheme.surfaceContainerHighest
              : scheme.primary,
        ),
        child: follow.isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                follow.isFollowing ? "Following" : "Follow",
                style: TextStyle(
                  color: follow.isFollowing
                      ? scheme.onSurface
                      : scheme.onPrimary,
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ADMIN VERIFY BUTTON
// ---------------------------------------------------------------------------

class _AdminVerifyButton extends StatelessWidget {
  final UserModel user;
  final String targetUid;

  const _AdminVerifyButton({required this.user, required this.targetUid});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminUserController>(
      builder: (_, admin, __) {
        final scheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            height: 42,
            width: 220,
            child: ElevatedButton(
              onPressed: admin.isProcessing
                  ? null
                  : () => admin.toggleGazetter(
                      targetUid: targetUid,
                      currentStatus: user.isVerified,
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: user.isVerified
                    ? scheme.error
                    : scheme.primary,
              ),
              child: admin.isProcessing
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : Text(
                      user.isVerified ? "Revoke Gazetter" : "Grant Gazetter",
                      style: TextStyle(color: scheme.onPrimary),
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// TABS
// ---------------------------------------------------------------------------

class _Tabs extends StatelessWidget {
  final ProfileController controller;

  const _Tabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _tab(context, "Posts", 0),
          _tab(context, "RePics", 1),
          _tab(context, "Saved", 2),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, String label, int index) {
    final active = controller.selectedTab == index;
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => controller.setTab(index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? scheme.primary : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 4,
            width: 50,
            decoration: BoxDecoration(
              color: active ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TAB CONTENT
// ---------------------------------------------------------------------------

class _TabContent extends StatelessWidget {
  final ProfileController controller;

  const _TabContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    List<PostModel> list;

    switch (controller.selectedTab) {
      case 1:
        list = controller.reposts;
        break;
      case 2:
        list = controller.savedPosts;
        break;
      default:
        list = controller.userPosts;
    }

    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Text("Nothing here yet"),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, i) {
        final post = list[i];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailsScreen(post: post)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(post.resolvedImages.first, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}
