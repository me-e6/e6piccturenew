import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../follow/mutual_controller.dart';
import '../profile/profile_controller.dart';
import '../follow/follow_controller.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_service.dart';
import '../profile/user_model.dart';
import 'widgets/user_list_row.dart';

/// ---------------------------------------------------------------------------
/// MUTUALS LIST SCREEN (API-AWARE, UNIFIED ROW UI)
/// ---------------------------------------------------------------------------
/// - Uses MutualController (uids only)
/// - Resolves UserModel via ProfileService (UI-safe)
/// - Reuses UserListRow (same as Followers / Following)
class MutualsListScreen extends StatelessWidget {
  final String userId;

  const MutualsListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MutualController()..loadMutuals(userId),
      child: const _MutualsListBody(),
    );
  }
}

class _MutualsListBody extends StatelessWidget {
  const _MutualsListBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MutualController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mutuals'), centerTitle: true),
      body: _buildBody(context, controller),
    );
  }

  Widget _buildBody(BuildContext context, MutualController controller) {
    switch (controller.state) {
      case MutualLoadState.loading:
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));

      case MutualLoadState.empty:
        return const Center(child: Text('No mutuals yet'));

      case MutualLoadState.error:
        return Center(child: Text(controller.error ?? 'Something went wrong'));

      case MutualLoadState.success:
        return ListView.separated(
          itemCount: controller.mutualUids.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final uid = controller.mutualUids[index];
            return _MutualUserTile(uid: uid);
          },
        );

      //   case MutualLoadState.idle:
      default:
        return const SizedBox.shrink();
    }
  }
}

/// ---------------------------------------------------------------------------
/// MUTUAL USER TILE (RESOLVES USER → UNIFIED ROW)
/// ---------------------------------------------------------------------------
class _MutualUserTile extends StatelessWidget {
  final String uid;

  const _MutualUserTile({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: ProfileService().getUser(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            leading: CircleAvatar(radius: 20),
            title: Text('Loading...'),
          );
        }

        final user = snapshot.data!;
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
        );
      },
    );
  }
}
