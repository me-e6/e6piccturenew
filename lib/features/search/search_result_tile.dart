import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile/user_model.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_controller.dart';
import '../follow/follow_controller.dart';
import '../follow/mutual_controller.dart';

class SearchResultTile extends StatelessWidget {
  final UserModel user;

  const SearchResultTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
            ? NetworkImage(user.profileImageUrl!)
            : null,
        child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('@${user.handle}'),
      trailing: user.hasMutual == true
          ? const Text(
              'Mutual',
              style: TextStyle(color: Colors.green, fontSize: 12),
            )
          : null,
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
