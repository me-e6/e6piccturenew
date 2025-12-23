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

  void _showInitialDpChooser(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Upload profile photo'),
              onTap: () {
                Navigator.pop(context);
                onEditAvatar?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Upload video DP (≤20s)'),
              onTap: () {
                Navigator.pop(context);
                onEditVideoDp?.call();
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ------------------------------------------------------------
        /// BANNER + OVERLAPPING AVATAR (TWITTER STYLE)
        /// ------------------------------------------------------------
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Banner
            Container(
              height: 120,
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

            // Banner edit button
            if (isOwner)
              Positioned(
                top: 8,
                right: 8,
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

            // Avatar (overlapping banner - Twitter style)
            Positioned(
              left: 16,
              bottom: -40,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!isOwner) return;

                      if (hasVideoDp) {
                        onVideoDpTap?.call();
                      } else {
                        _showInitialDpChooser(context);
                      }
                    },
                    onLongPress: hasVideoDp && isOwner
                        ? () => _showVideoActions(context)
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage:
                            avatarUrl != null && avatarUrl!.isNotEmpty
                            ? NetworkImage(avatarUrl!)
                            : null,
                        child: avatarUrl == null || avatarUrl!.isEmpty
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                    ),
                  ),

                  /// VIDEO BADGE
                  if (hasVideoDp)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(220, 15, 136, 49),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 12,
                          color: Color.fromARGB(255, 255, 255, 222),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        /// ------------------------------------------------------------
        /// ACTION BUTTONS ROW (TOP RIGHT - TWITTER STYLE)
        /// ------------------------------------------------------------
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isOwner) ...[
                OutlinedButton(
                  onPressed: onEditProfile,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    'Edit profile',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                if (hasVideoDp && onEditVideoDp != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _showVideoActions(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      shape: const CircleBorder(),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.videocam, size: 18),
                  ),
                ],
              ] else
                ElevatedButton(
                  onPressed: onFollowToggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing
                        ? Colors.transparent
                        : const Color.fromARGB(220, 15, 136, 49),
                    foregroundColor: isFollowing ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: isFollowing
                          ? BorderSide(color: Colors.grey.shade300)
                          : BorderSide.none,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 0),

        /// ------------------------------------------------------------
        /// NAME + HANDLE + BIO (LEFT ALIGNED - TWITTER STYLE)
        /// ------------------------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Name + Verified
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 2),
                    const Icon(Icons.verified, size: 20, color: Colors.blue),
                  ],
                ],
              ),

              const SizedBox(height: 2),

              // Handle
              if (handle != null && handle!.isNotEmpty)
                Text(
                  '@$handle',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),

              // Bio
              if (bio != null && bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  bio!,
                  style: const TextStyle(fontSize: 15),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}


/*
// ----------------- Orginal -Script ------------
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
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!isOwner) return;

                      if (hasVideoDp) {
                        onVideoDpTap?.call(); // play video
                      } else {
                        _showInitialDpChooser(context);
                      }
                    },

                    onLongPress: hasVideoDp && isOwner
                        ? () =>
                              _showVideoActions(context) // edit / delete
                        : null,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          avatarUrl != null && avatarUrl!.isNotEmpty
                          ? NetworkImage(avatarUrl!)
                          : null,
                      child: avatarUrl == null || avatarUrl!.isEmpty
                          ? const Icon(Icons.person, size: 32)
                          : null,
                    ),
                  ),

                  /// VIDEO BADGE
                  if (hasVideoDp)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(120, 21, 106, 29),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 14,
                          color: Color.fromARGB(255, 255, 255, 222),
                        ),
                      ),
                    ),
                ],
              ),

              const Spacer(),
              /*    if (isOwner)
                OutlinedButton(
                  onPressed: onEditProfile,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 20), // exact size
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ), // width, height
                  ),
                  child: const Text('Edit profile'),
                )
              else
                OutlinedButton(
                  onPressed: onFollowToggle,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 20), // exact size
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ), // width, height
                  ),
                  child: Text(isFollowing ? 'Following' : 'Follow'),
                ), */
              if (isOwner)
                ElevatedButton(
                  onPressed: onEditProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                      120,
                      21,
                      106,
                      29,
                    ), // Orange color
                    foregroundColor: Colors.white, // White text
                    minimumSize: const Size(110, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0, // Flat design like Claude
                  ),
                  child: const Text('Edit profile'),
                )
              else
                ElevatedButton(
                  onPressed: onFollowToggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(
                      220,
                      15,
                      136,
                      49,
                    ), // Orange color
                    foregroundColor: Colors.white, // White text
                    minimumSize: const Size(110, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0, // Flat design like Claude
                  ),
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

  void _showInitialDpChooser(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Upload profile photo'),
              onTap: () {
                Navigator.pop(context);
                onEditAvatar?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Upload video DP (≤20s)'),
              onTap: () {
                Navigator.pop(context);
                onEditVideoDp?.call(); // 👈 THIS triggers upload
              },
            ),
          ],
        ),
      ),
    );
  }
} */
/*
import 'package:flutter/material.dart';

class ProfileIdentityBanner extends StatelessWidget {
  final String displayName;
  final String handle;
  final String? avatarUrl;
  final String? bannerUrl;
  final String bio;
  final bool isVerified;
  final bool hasVideoDp;
  final bool isUpdatingVideoDp;
  final bool isOwner;
  final bool isFollowing;
  final bool isUpdatingAvatar;
  final bool isUpdatingBanner;
  final VoidCallback? onEditAvatar;
  final VoidCallback? onEditBanner;
  final VoidCallback? onVideoDpTap;
  final VoidCallback? onEditVideoDp;
  final VoidCallback? onReplaceVideo;
  final VoidCallback? onDeleteVideo;
  final VoidCallback? onEditProfile;
  final VoidCallback? onFollowToggle;

  const ProfileIdentityBanner({
    super.key,
    required this.displayName,
    required this.handle,
    this.avatarUrl,
    this.bannerUrl,
    required this.bio,
    required this.isVerified,
    required this.hasVideoDp,
    required this.isUpdatingVideoDp,
    required this.isOwner,
    required this.isFollowing,
    required this.isUpdatingAvatar,
    required this.isUpdatingBanner,
    this.onEditAvatar,
    this.onEditBanner,
    this.onVideoDpTap,
    this.onEditVideoDp,
    this.onReplaceVideo,
    this.onDeleteVideo,
    this.onEditProfile,
    this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Banner
        Stack(
          children: [
            Container(
              height: 160,
              width: double.infinity,
              color: Colors.grey[300],
              child: bannerUrl != null
                  ? Image.network(bannerUrl!, fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.landscape, size: 48)),
            ),
            if (isOwner && onEditBanner != null)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: isUpdatingBanner
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.white,
                          ),
                          onPressed: onEditBanner,
                        ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Avatar + Video DP
        Stack(
          children: [
            GestureDetector(
              onTap: hasVideoDp ? onVideoDpTap : null,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, size: 48)
                    : null,
              ),
            ),
            if (hasVideoDp)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            if (isOwner && onEditAvatar != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black87,
                  child: isUpdatingAvatar
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: Colors.white,
                          ),
                          onPressed: onEditAvatar,
                        ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Display Name + Verified
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, size: 18, color: Colors.blue),
            ],
          ],
        ),

        const SizedBox(height: 4),

        // Handle
        Text(
          '@$handle',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),

        const SizedBox(height: 12),

        // Bio
        if (bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              bio,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),

        const SizedBox(height: 16),

        // Action Buttons
        if (isOwner)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onEditProfile != null)
                ElevatedButton.icon(
                  onPressed: onEditProfile,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Profile'),
                ),
              if (hasVideoDp && onEditVideoDp != null) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onEditVideoDp,
                  icon: const Icon(Icons.videocam, size: 16),
                  label: const Text('Video DP'),
                ),
              ] else if (onEditVideoDp != null) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onEditVideoDp,
                  icon: const Icon(Icons.add_a_photo, size: 16),
                  label: const Text('Add Video DP'),
                ),
              ],
            ],
          )
        else if (onFollowToggle != null)
          ElevatedButton(
            onPressed: onFollowToggle,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey[300] : Colors.blue,
              foregroundColor: isFollowing ? Colors.black : Colors.white,
            ),
            child: Text(isFollowing ? 'Following' : 'Follow'),
          ),
      ],
    );
  }
}
*/