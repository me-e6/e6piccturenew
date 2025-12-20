import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/list_skeleton.dart';
import 'follow_list_controller.dart';
import '../profile/profile_screen.dart';
import './widgets/user_list_row.dart';

import '../follow/mutual_controller.dart';
import '../profile/profile_controller.dart';
import '../follow/follow_controller.dart';

/// ---------------------------------------------------------------------------
/// FOLLOWING LIST SCREEN (API-AWARE, CONTROLLER-DRIVEN)
/// ---------------------------------------------------------------------------
class FollowingListScreen extends StatelessWidget {
  final String userId;

  const FollowingListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          FollowListController(userId: userId, type: FollowListType.following)
            ..load(),
      child: const _FollowingListBody(),
    );
  }
}

class _FollowingListBody extends StatelessWidget {
  const _FollowingListBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FollowListController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Following'), centerTitle: true),
      body: _buildBody(context, controller),
    );
  }

  Widget _buildBody(BuildContext context, FollowListController controller) {
    if (controller.isLoading) {
      return const ListSkeleton();
    }

    if (controller.error != null) {
      return Center(
        child: Text(
          controller.error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (controller.users.isEmpty) {
      return const Center(child: Text('Not following anyone yet'));
    }

    return ListView.separated(
      itemCount: controller.users.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final user = controller.users[index];

        return UserListRow(
          user: user,
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
    );
  }
}
