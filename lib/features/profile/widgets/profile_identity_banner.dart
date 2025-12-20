import 'package:flutter/material.dart';

class ProfileIdentityBanner extends StatelessWidget {
  final String displayName;
  final String? handle;
  final String? avatarUrl;
  final String? bannerUrl;
  final bool isVerified;
  final bool hasVideoDp;
  final String? bio;

  final bool isOwner;
  final bool isFollowing;

  final bool isUpdatingAvatar;
  final bool isUpdatingBanner;

  final VoidCallback? onEditAvatar;
  final VoidCallback? onEditProfile;
  final VoidCallback? onFollowToggle;
  final VoidCallback? onEditBanner;

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
    this.onEditAvatar,
    this.onEditProfile,
    this.onFollowToggle,
    this.onEditBanner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// -------------------------------
        /// PROFILE BANNER
        /// -------------------------------
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

        /// -------------------------------
        /// AVATAR + ACTION
        /// -------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
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

                  if (hasVideoDp)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
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

                  if (isOwner)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: isUpdatingAvatar ? null : onEditAvatar,
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

        /// -------------------------------
        /// NAME + HANDLE + BIO
        /// -------------------------------
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
