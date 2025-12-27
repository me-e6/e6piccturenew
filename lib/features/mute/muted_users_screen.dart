import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'mute_service.dart';

/// ============================================================================
/// MUTED USERS SCREEN
/// ============================================================================
/// Displays list of muted users with:
/// - ✅ User avatars and names
/// - ✅ Unmute button for each user
/// - ✅ Empty state
/// - ✅ Loading state
/// ============================================================================
class MutedUsersScreen extends StatefulWidget {
  const MutedUsersScreen({super.key});

  @override
  State<MutedUsersScreen> createState() => _MutedUsersScreenState();
}

class _MutedUsersScreenState extends State<MutedUsersScreen> {
  final _muteService = MuteService();
  
  List<MutedUser> _mutedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMutedUsers();
  }

  Future<void> _loadMutedUsers() async {
    setState(() => _isLoading = true);

    try {
      final users = await _muteService.getMutedUsers();
      setState(() {
        _mutedUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading muted users: $e')),
        );
      }
    }
  }

  Future<void> _unmuteUser(MutedUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unmute User'),
        content: Text(
          'Are you sure you want to unmute ${user.displayName}? '
          'Their posts will appear in your feed again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unmute'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _muteService.unmuteUser(user.userId);

    if (success) {
      setState(() {
        _mutedUsers.removeWhere((u) => u.userId == user.userId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unmuted ${user.displayName}')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to unmute user')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Muted Accounts'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mutedUsers.isEmpty
              ? _buildEmptyState(scheme)
              : RefreshIndicator(
                  onRefresh: _loadMutedUsers,
                  child: ListView.builder(
                    itemCount: _mutedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _mutedUsers[index];
                      return _MutedUserTile(
                        user: user,
                        onUnmute: () => _unmuteUser(user),
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
            Icons.volume_off,
            size: 64,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No muted accounts',
            style: TextStyle(
              fontSize: 18,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accounts you mute will appear here',
            style: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Muted accounts won\'t know they\'re muted.\n'
            'You just won\'t see their posts in your feed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedUserTile extends StatelessWidget {
  final MutedUser user;
  final VoidCallback onUnmute;

  const _MutedUserTile({
    required this.user,
    required this.onUnmute,
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
          if (user.mutedAt != null)
            Text(
              'Muted ${_formatDate(user.mutedAt!)}',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
      isThreeLine: user.mutedAt != null,
      trailing: OutlinedButton(
        onPressed: onUnmute,
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
        ),
        child: const Text('Unmute'),
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
/// MUTE USER BOTTOM SHEET
/// ============================================================================
/// Quick action sheet for muting a user from their profile
/// ============================================================================
class MuteUserSheet extends StatelessWidget {
  final String userId;
  final String userName;
  final VoidCallback? onMuted;

  const MuteUserSheet({
    super.key,
    required this.userId,
    required this.userName,
    this.onMuted,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String userName,
    VoidCallback? onMuted,
  }) {
    return showModalBottomSheet(
      context: context,
      builder: (_) => MuteUserSheet(
        userId: userId,
        userName: userName,
        onMuted: onMuted,
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
              Icons.volume_off,
              size: 48,
              color: scheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Mute $userName?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You won\'t see their posts in your feed. '
              'They won\'t know they\'re muted.',
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
                    onPressed: () async {
                      final success = await MuteService().muteUser(userId);
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (success) {
                          onMuted?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Muted $userName')),
                          );
                        }
                      }
                    },
                    child: const Text('Mute'),
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

/// ============================================================================
/// USER OPTIONS MENU
/// ============================================================================
/// Combined menu for block/mute actions from a user profile
/// ============================================================================
class UserOptionsMenu extends StatelessWidget {
  final String userId;
  final String userName;
  final bool isBlocked;
  final bool isMuted;
  final VoidCallback? onBlock;
  final VoidCallback? onMute;
  final VoidCallback? onReport;

  const UserOptionsMenu({
    super.key,
    required this.userId,
    required this.userName,
    this.isBlocked = false,
    this.isMuted = false,
    this.onBlock,
    this.onMute,
    this.onReport,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String userName,
    bool isBlocked = false,
    bool isMuted = false,
    VoidCallback? onBlock,
    VoidCallback? onMute,
    VoidCallback? onReport,
  }) {
    return showModalBottomSheet(
      context: context,
      builder: (_) => UserOptionsMenu(
        userId: userId,
        userName: userName,
        isBlocked: isBlocked,
        isMuted: isMuted,
        onBlock: onBlock,
        onMute: onMute,
        onReport: onReport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Mute option
          ListTile(
            leading: Icon(
              isMuted ? Icons.volume_up : Icons.volume_off,
              color: scheme.primary,
            ),
            title: Text(isMuted ? 'Unmute $userName' : 'Mute $userName'),
            subtitle: Text(
              isMuted
                  ? 'See their posts in your feed again'
                  : 'Hide their posts from your feed',
            ),
            onTap: () {
              Navigator.pop(context);
              onMute?.call();
            },
          ),

          // Block option
          ListTile(
            leading: Icon(
              isBlocked ? Icons.check_circle : Icons.block,
              color: scheme.error,
            ),
            title: Text(
              isBlocked ? 'Unblock $userName' : 'Block $userName',
              style: TextStyle(color: isBlocked ? null : scheme.error),
            ),
            subtitle: Text(
              isBlocked
                  ? 'Allow them to see your profile'
                  : 'Prevent them from seeing your profile',
            ),
            onTap: () {
              Navigator.pop(context);
              onBlock?.call();
            },
          ),

          const Divider(),

          // Report option
          ListTile(
            leading: Icon(Icons.flag_outlined, color: scheme.error),
            title: Text(
              'Report $userName',
              style: TextStyle(color: scheme.error),
            ),
            subtitle: const Text('Report inappropriate behavior'),
            onTap: () {
              Navigator.pop(context);
              onReport?.call();
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
