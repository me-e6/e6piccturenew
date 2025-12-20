import 'package:flutter/material.dart';

class ProfileIdentityBanner extends StatelessWidget {
  final String displayName;
  final String? handle;
  final String? avatarUrl;
  final String? bannerUrl;
  final bool isVerified;
  final bool hasVideoDp;
  final String? bio;

  /// Ownership
  final bool isOwner;
  final bool isFollowing;

  /// Loading states
  final bool isUpdatingAvatar;
  final bool isUpdatingBanner;
  final bool? isUpdatingVideoDp;

  /// Actions
  final VoidCallback? onEditAvatar;
  final VoidCallback? onEditProfile;
  final VoidCallback? onFollowToggle;
  final VoidCallback? onEditBanner;

  /// Video DP actions
  final VoidCallback? onViewVideo;
  final VoidCallback? onReplaceVideo;
  final VoidCallback? onDeleteVideo;
  final VoidCallback? onEditVideoDp;
  final VoidCallback? onVideoDpTap;

  const ProfileIdentityBanner({
    super.key,
    required this.displayName,
    this.handle,
    this.avatarUrl,
    this.bannerUrl,
    required this.isVerified,
    required this.hasVideoDp,
    this.bio,
    required this.isOwner,
    required this.isFollowing,
    required this.isUpdatingAvatar,
    required this.isUpdatingBanner,
    this.isUpdatingVideoDp,
    this.onEditAvatar,
    this.onEditProfile,
    this.onFollowToggle,
    this.onEditBanner,
    this.onViewVideo,
    this.onReplaceVideo,
    this.onDeleteVideo,
    this.onEditVideoDp,
    this.onVideoDpTap,
  });

  // ------------------------------------------------------------
  // VIDEO DP ACTION SHEET (OWNER ONLY)
  // ------------------------------------------------------------
  void _showVideoActions(BuildContext context) {
    if (!isOwner) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle),
              title: const Text('View Video'),
              onTap: () {
                Navigator.pop(context);
                onViewVideo?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Replace Video'),
              onTap: () {
                Navigator.pop(context);
                onReplaceVideo?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Remove Video',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                onDeleteVideo?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// ------------------------------------------------------------
        /// PROFILE BANNER
        /// ------------------------------------------------------------
        Stack(
          children: [
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                image: bannerUrl != null && bannerUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(bannerUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            if (isOwner)
              Positioned(
                top: 12,
                right: 12,
                child: InkWell(
                  onTap: isUpdatingBanner ? null : onEditBanner,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: isUpdatingBanner
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 48),

        /// ------------------------------------------------------------
        /// AVATAR + ACTION
        /// ------------------------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              /// -------------------------------
              /// AVATAR
              /// -------------------------------
              GestureDetector(
                onTap: () {
                  if (hasVideoDp) {
                    _showVideoActions(context);
                  } else {
                    onEditAvatar?.call();
                  }
                },
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null || avatarUrl!.isEmpty
                      ? const Icon(Icons.person, size: 32)
                      : null,
                ),
              ),

              /// -------------------------------
              /// VIDEO DP BADGE (RIGHT SIDE)
              /// -------------------------------
              if (hasVideoDp) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onViewVideo ?? () => _showVideoActions(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'vDP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],

              const Spacer(),

              /// -------------------------------
              /// ACTION BUTTON
              /// -------------------------------
              if (isOwner)
                OutlinedButton(
                  onPressed: onEditProfile,
                  child: const Text('Edit profile'),
                )
              else
                OutlinedButton(
                  onPressed: onFollowToggle,
                  child: Text(isFollowing ? 'Following' : 'Follow'),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        /// ------------------------------------------------------------
        /// NAME + HANDLE + BIO
        /// ------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (isVerified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, size: 18, color: Colors.blue),
            ],
          ],
        ),

        if (handle != null && handle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '@$handle',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),

        if (bio != null && bio!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              bio!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
