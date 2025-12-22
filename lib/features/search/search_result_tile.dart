import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '.././profile/user_model.dart';
import '.././follow/follow_controller.dart';
import '.././profile/profile_controller.dart';
import '.././follow/mutual_controller.dart';
import '.././profile/profile_screen.dart';

class SearchResultTile extends StatelessWidget {
  final UserModel user;

  const SearchResultTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FollowController()..load(user.uid),
      child: _SearchResultTileBody(user: user),
    );
  }
}

class _SearchResultTileBody extends StatelessWidget {
  final UserModel user;

  const _SearchResultTileBody({required this.user});

  @override
  Widget build(BuildContext context) {
    final follow = context.watch<FollowController>();

    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey.shade300,
        backgroundImage:
            user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
            ? NetworkImage(user.profileImageUrl!)
            : null,
        child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
            ? const Icon(Icons.person)
            : null,
      ),

      title: Row(
        children: [
          Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, size: 16, color: Colors.blue),
          ],
        ],
      ),

      subtitle: Text(
        '@${user.handle}',
        style: TextStyle(color: Colors.grey.shade600),
      ),

      trailing: follow.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : OutlinedButton(
              onPressed: follow.isFollowing
                  ? () => follow.unfollow(user.uid)
                  : () => follow.follow(user.uid),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                follow.isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (_) => ProfileController()..loadProfile(user.uid),
                ),
                ChangeNotifierProvider(
                  create: (_) => MutualController()..loadMutuals(user.uid),
                ),
                ChangeNotifierProvider(
                  create: (_) => FollowController()..load(user.uid),
                ),
              ],
              child: ProfileScreen(userId: user.uid),
            ),
          ),
        );
      },
    );
  }
}
