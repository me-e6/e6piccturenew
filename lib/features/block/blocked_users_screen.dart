import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'block_service.dart';

/// ============================================================================
/// BLOCKED USERS SCREEN
/// ============================================================================
/// Displays list of blocked users with:
/// - ✅ User avatars and names
/// - ✅ Unblock button for each user
/// - ✅ Empty state
/// - ✅ Loading state
/// ============================================================================
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _blockService = BlockService();
  
  List<BlockedUser> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);

    try {
      final users = await _blockService.getBlockedUsers();
      setState(() {
        _blockedUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading blocked users: $e')),
        );
      }
    }
  }

  Future<void> _unblockUser(BlockedUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _blockService.unblockUser(user.userId);

    if (success) {
      setState(() {
        _blockedUsers.removeWhere((u) => u.userId == user.userId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unblocked ${user.displayName}')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to unblock user')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Accounts'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? _buildEmptyState(scheme)
              : RefreshIndicator(
                  onRefresh: _loadBlockedUsers,
                  child: ListView.builder(
                    itemCount: _blockedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _blockedUsers[index];
                      return _BlockedUserTile(
                        user: user,
                        onUnblock: () => _unblockUser(user),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 64,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No blocked accounts',
            style: TextStyle(
              fontSize: 18,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accounts you block will appear here',
            style: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final BlockedUser user;
  final VoidCallback onUnblock;

  const _BlockedUserTile({
    required this.user,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: user.avatarUrl != null
            ? CachedNetworkImageProvider(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('@${user.handle}'),
          if (user.blockedAt != null)
            Text(
              'Blocked ${_formatDate(user.blockedAt!)}',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
      isThreeLine: user.blockedAt != null,
      trailing: OutlinedButton(
        onPressed: onUnblock,
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
        ),
        child: const Text('Unblock'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// ============================================================================
/// BLOCK USER BOTTOM SHEET
/// ============================================================================
/// Quick action sheet for blocking a user from their profile
/// ============================================================================
class BlockUserSheet extends StatelessWidget {
  final String userId;
  final String userName;
  final VoidCallback? onBlocked;

  const BlockUserSheet({
    super.key,
    required this.userId,
    required this.userName,
    this.onBlocked,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String userName,
    VoidCallback? onBlocked,
  }) {
    return showModalBottomSheet(
      context: context,
      builder: (_) => BlockUserSheet(
        userId: userId,
        userName: userName,
        onBlocked: onBlocked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.block,
              size: 48,
              color: scheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Block $userName?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'They won\'t be able to see your posts or profile. '
              'They won\'t be notified.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    ),
                    onPressed: () async {
                      final success = await BlockService().blockUser(userId);
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (success) {
                          onBlocked?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Blocked $userName')),
                          );
                        }
                      }
                    },
                    child: const Text('Block'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
