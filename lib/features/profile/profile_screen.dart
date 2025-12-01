import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'profile_controller.dart';
import 'user_model.dart';
import '../post/create/post_model.dart';
import '../post/details/post_details_screen.dart';
import '../follow/follow_controller.dart'; // NEW

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
        ChangeNotifierProvider(
          create: (_) => FollowController()..checkFollowing(uid),
        ),
      ],
      child: Consumer2<ProfileController, FollowController>(
        builder: (context, controller, follow, _) {
          if (controller.isLoading || controller.user == null) {
            return const Scaffold(
              backgroundColor: Color(0xFFF5EDE3),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFC56A45)),
              ),
            );
          }

          final user = controller.user!;
          return Scaffold(
            backgroundColor: const Color(0xFFF5EDE3),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
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

// ------------------- HEADER UI -----------------------

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
    final currentUid = follow.currentUid; // SAFE getter
    final isOwnProfile = currentUid == targetUid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E2D2),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ---- PROFILE IMAGE (Tap to update photo for SELF ONLY) ----
          GestureDetector(
            onTap: () {
              if (isOwnProfile) controller.updatePhoto(user.uid);
            },
            child: CircleAvatar(
              radius: 45,
              backgroundImage: user.photoUrl.isNotEmpty
                  ? NetworkImage(user.photoUrl)
                  : const AssetImage("assets/profile_placeholder.png")
                        as ImageProvider,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            user.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2F2F2F),
            ),
          ),

          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF6C7A4C),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              user.type.toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat("Posts", controller.postCount),
              _stat("RePics", controller.repostCount),
              _stat("Followers", controller.followersCount),
              _stat("Following", controller.followingCount),
            ],
          ),

          const SizedBox(height: 18),

          // ---------------- FOLLOW BUTTON -----------------
          if (!isOwnProfile) _buildFollowButton(follow),
        ],
      ),
    );
  }

  Widget _buildFollowButton(FollowController follow) {
    return SizedBox(
      height: 42,
      width: 160,
      child: ElevatedButton(
        onPressed: follow.isLoading
            ? null
            : () {
                if (follow.isFollowingUser) {
                  follow.unfollow(targetUid);
                } else {
                  follow.follow(targetUid);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: follow.isFollowingUser
              ? Colors.grey.shade500
              : const Color(0xFFC56A45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: follow.isLoading
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                follow.isFollowingUser ? "Following" : "Follow",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
      ),
    );
  }

  Widget _stat(String label, int count) {
    return Column(
      children: [
        Text(
          "$count",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2F2F2F),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ------------------- TABS -----------------------

class _Tabs extends StatelessWidget {
  final ProfileController controller;

  const _Tabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedTab;

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _tab(controller, 0, "Posts", selected == 0),
          _tab(controller, 1, "RePics", selected == 1),
          _tab(controller, 2, "Saved", selected == 2),
        ],
      ),
    );
  }

  Widget _tab(ProfileController c, int index, String label, bool active) {
    return GestureDetector(
      onTap: () => c.setTab(index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF2F2F2F),
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 4,
            width: 50,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFC56A45) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------- TAB CONTENT -----------------------

class _TabContent extends StatelessWidget {
  final ProfileController controller;

  const _TabContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    List<PostModel> list;

    if (controller.selectedTab == 0) {
      list = controller.userPosts;
    } else if (controller.selectedTab == 1) {
      list = controller.reposts;
    } else {
      list = controller.savedPosts;
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
            child: Image.network(post.imageUrl, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}
