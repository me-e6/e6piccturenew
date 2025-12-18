/* Profile_Identtity_Banner */

import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// PROFILE IDENTITY BANNER (API-AWARE, REUSABLE)
/// ---------------------------------------------------------------------------
/// - UI-only
/// - No Firestore / Firebase imports
/// - No controllers inside
/// - Safe for Feed, Profile, Repic attribution
class ProfileIdentityBanner extends StatelessWidget {
  final String displayName;
  final String? handle;
  final String? avatarUrl;
  final bool isVerified;
  final bool hasVideoDp;
  final String? bio;

  /// Ownership & relationship
  final bool isOwner;
  final bool isFollowing;

  /// Loading flags
  final bool isUpdatingAvatar;

  /// Actions (delegated upward)
  final VoidCallback? onEditAvatar;
  final VoidCallback? onEditProfile;
  final VoidCallback? onFollowToggle;

  const ProfileIdentityBanner({
    super.key,
    required this.displayName,
    this.handle,
    this.avatarUrl,
    required this.isVerified,
    required this.hasVideoDp,
    this.bio,
    required this.isOwner,
    required this.isFollowing,
    required this.isUpdatingAvatar,
    this.onEditAvatar,
    this.onEditProfile,
    this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          /// ------------------------------------------------------------
          /// TOP ROW: AVATAR + ACTION
          /// ------------------------------------------------------------
          Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: avatarUrl == null || avatarUrl!.isEmpty
                        ? const Icon(Icons.person, size: 32)
                        : null,
                  ),

                  /// Video DP badge (future-safe)
                  if (hasVideoDp)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  /// Edit avatar (owner only)
                  if (isOwner)
                    Positioned(
                      right: 0,
                      bottom: 0,
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
                              : const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                ],
              ),

              const Spacer(),

              /// --------------------------------------------------------
              /// ACTION BUTTON
              /// --------------------------------------------------------
              if (isOwner)
                OutlinedButton(
                  onPressed: onEditProfile,
                  child: const Text('Edit profile'),
                )
              else
                OutlinedButton(
                  onPressed: onFollowToggle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isFollowing
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                  ),
                  child: Text(isFollowing ? 'Following' : 'Follow'),
                ),
            ],
          ),

          const SizedBox(height: 12),

          /// ------------------------------------------------------------
          /// NAME + VERIFIED
          /// ------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, size: 18, color: Colors.blue),
              ],
            ],
          ),

          /// Handle
          if (handle != null && handle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@$handle',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],

          /// Bio
          if (bio != null && bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
