import 'package:flutter/material.dart';
import '../../profile/user_model.dart';

class UserListRow extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final Widget? trailing;

  const UserListRow({super.key, required this.user, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            /// Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  user.profileImageUrl != null &&
                      user.profileImageUrl!.isNotEmpty
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child:
                  user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),

            const SizedBox(width: 12),

            /// Name + handle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.displayName ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
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

                  if (user.handle != null && user.handle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '@${user.handle}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            /// Optional action (Follow button etc.)
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
