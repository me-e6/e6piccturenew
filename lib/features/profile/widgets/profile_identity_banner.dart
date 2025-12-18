import 'package:flutter/material.dart';
import '../user_model.dart';

class ProfileIdentityBanner extends StatelessWidget {
  final UserModel user;
  final bool isOwner;
  final bool isUpdatingAvatar;
  final VoidCallback? onEditAvatar;

  const ProfileIdentityBanner({
    super.key,
    required this.user,
    required this.isOwner,
    required this.isUpdatingAvatar,
    this.onEditAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  user.profileImageUrl != null &&
                      user.profileImageUrl!.isNotEmpty
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child:
                  user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                  ? const Icon(Icons.person, size: 36)
                  : null,
            ),

            if (isOwner)
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: isUpdatingAvatar ? null : onEditAvatar,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: isUpdatingAvatar
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.displayName ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (user.isVerified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, size: 18, color: Colors.blue),
            ],
          ],
        ),

        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            user.bio!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
