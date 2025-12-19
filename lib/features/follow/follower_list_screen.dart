import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './widgets/user_list_row.dart';
import 'follow_list_controller.dart';
import '../profile/profile_screen.dart';
import '../../core/widgets/list_skeleton.dart';

/// ---------------------------------------------------------------------------
/// FOLLOWERS LIST SCREEN (API-AWARE, CONTROLLER-DRIVEN)
/// ---------------------------------------------------------------------------
class FollowersListScreen extends StatelessWidget {
  final String userId;

  const FollowersListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          FollowListController(userId: userId, type: FollowListType.followers)
            ..load(),
      child: const _FollowersListBody(),
    );
  }
}

class _FollowersListBody extends StatelessWidget {
  const _FollowersListBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FollowListController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Followers'), centerTitle: true),
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
      return const Center(child: Text('No followers yet'));
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
                builder: (_) => ProfileScreen(userId: user.uid),
              ),
            );
          },
        );
      },
    );
  }
}
