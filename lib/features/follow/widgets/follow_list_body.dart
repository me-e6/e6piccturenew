import 'package:flutter/material.dart';
import 'package:e6piccturenew/features/follow/follow_list_controller.dart';
import 'package:e6piccturenew/features/profile/profile_screen.dart';
import 'package:provider/provider.dart';
import '../../follow/mutual_controller.dart';
import '../../profile/profile_controller.dart';
import '../../follow/follow_controller.dart';

class FollowListBody extends StatelessWidget {
  final String title;

  const FollowListBody({required this.title});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FollowListController>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.users.isEmpty
          ? const Center(child: Text('No users found'))
          : ListView.separated(
              itemCount: controller.users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final user = controller.users[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Row(
                    children: [
                      Text(user.displayName ?? 'User'),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: Colors.blue,
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiProvider(
                          providers: [
                            ChangeNotifierProvider(
                              create: (_) =>
                                  ProfileController()..loadProfile(user.uid),
                            ),
                            ChangeNotifierProvider(
                              create: (_) =>
                                  MutualController()..loadMutuals(user.uid),
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
                  /*  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: user.uid),
                      ),
                    );
                  }, */
                );
              },
            ),
    );
  }
}
