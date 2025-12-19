/* import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/list_skeleton.dart';
import './widgets/user_list_row.dart';
import '../../features/profile/profile_service.dart';
import 'mutual_controller.dart';
import '../profile/profile_screen.dart';

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
      appBar: AppBar(title: const Text('Mutuals')),
      body: _buildBody(context, controller),
    );
  }

  Widget _buildBody(BuildContext context, MutualController controller) {
    switch (controller.state) {
      case MutualLoadState.loading:
        return const ListSkeleton();

      //  return const Center(child: CircularProgressIndicator(strokeWidth: 2));

      case MutualLoadState.empty:
        return const Center(child: Text('No mutuals yet'));

      case MutualLoadState.error:
        return const Center(child: Text('Failed to load mutuals'));

      case MutualLoadState.success:
        return ListView.separated(
          itemCount: controller.mutualUids.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final uid = controller.mutualUids[index];

            return FutureBuilder<UserModel?>(
              future: ProfileService().getUser(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const UserListRowSkeleton();
                }

                return UserListRow(
                  user: snapshot.data!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: uid),
                      ),
                    );
                  },
                );
              },
            );
          },
        );

      case MutualLoadState.idle:
      default:
        return const SizedBox.shrink();
    }
  }
}
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'mutual_controller.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_service.dart';
import '../profile/user_model.dart';

/// ---------------------------------------------------------------------------
/// MUTUALS LIST SCREEN
/// ---------------------------------------------------------------------------
/// - Uses MutualController (UIDs only)
/// - Resolves UserModel lazily (API-aware)
/// - No business logic inside UI
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
        return const _MutualsSkeletonList();

      case MutualLoadState.empty:
        return const Center(
          child: Text('No mutuals yet', style: TextStyle(fontSize: 14)),
        );

      case MutualLoadState.error:
        return Center(
          child: Text(
            controller.error ?? 'Failed to load mutuals',
            style: const TextStyle(color: Colors.red),
          ),
        );

      case MutualLoadState.success:
        return ListView.separated(
          itemCount: controller.mutualUids.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final uid = controller.mutualUids[index];

            return _MutualUserRow(uid: uid);
          },
        );

      case MutualLoadState.idle:
      default:
        return const SizedBox.shrink();
    }
  }
}

/// ---------------------------------------------------------------------------
/// SINGLE MUTUAL USER ROW
/// ---------------------------------------------------------------------------
class _MutualUserRow extends StatelessWidget {
  final String uid;

  const _MutualUserRow({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: ProfileService().getUser(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _UserRowSkeleton();
        }

        final user = snapshot.data!;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            backgroundImage:
                user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(
            user.displayName ?? 'User',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: user.handle != null && user.handle!.isNotEmpty
              ? Text('@${user.handle}')
              : null,
          trailing: user.isVerified
              ? const Icon(Icons.verified, size: 18, color: Colors.blue)
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen(userId: uid)),
            );
          },
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// SKELETONS
/// ---------------------------------------------------------------------------
class _MutualsSkeletonList extends StatelessWidget {
  const _MutualsSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => const _UserRowSkeleton(),
    );
  }
}

class _UserRowSkeleton extends StatelessWidget {
  const _UserRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: Colors.grey.shade300),
      title: Container(height: 14, width: 120, color: Colors.grey.shade300),
      subtitle: Container(
        height: 12,
        width: 80,
        margin: const EdgeInsets.only(top: 6),
        color: Colors.grey.shade200,
      ),
    );
  }
}
