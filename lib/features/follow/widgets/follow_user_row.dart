import 'package:flutter/material.dart';
import '../../profile/user_model.dart';

/// ---------------------------------------------------------------------------
/// FOLLOW USER ROW (UNIFIED UI)
/// ---------------------------------------------------------------------------
/// Used by:
/// - Followers list
/// - Following list
/// - Mutuals list
///
/// UI-only, API-aware, reusable
class FollowUserRow extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final Widget? trailing;

  const FollowUserRow({
    super.key,
    required this.user,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
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

      title: Row(
        children: [
          Flexible(
            child: Text(
              user.displayName ?? 'User',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, size: 16, color: Colors.blue),
          ],
        ],
      ),

      subtitle: user.handle != null && user.handle!.isNotEmpty
          ? Text('@${user.handle}', style: const TextStyle(fontSize: 13))
          : null,

      trailing: trailing,

      onTap: onTap,
    );
  }
}
