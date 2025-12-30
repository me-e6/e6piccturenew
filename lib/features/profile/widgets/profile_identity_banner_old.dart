import 'package:flutter/material.dart';
import 'package:e6piccturenew/features/common/widgets/gazetteer_badge.dart';

/// ============================================================================
/// PROFILE IDENTITY BANNER - v2 (With Gazetteer Badge)
/// ============================================================================
/// Features:
/// - ✅ Twitter-style banner + avatar overlap
/// - ✅ Verified badge (blue checkmark)
/// - ✅ Gazetteer badge (stamp icon) - NEW!
/// - ✅ Video DP support
/// - ✅ Edit profile actions
/// - ✅ Follow button for non-owners
/// ============================================================================
class ProfileIdentityBanner extends StatelessWidget {
  final String displayName;
  final String? handle;
  final String? avatarUrl;
  final String? bannerUrl;
  final bool isVerified;
  final bool isGazetteer; // ✅ NEW
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
    this.isGazetteer = false, // ✅ NEW
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
        /// NAME + BADGES + HANDLE + BIO (LEFT ALIGNED - TWITTER STYLE)
        /// ------------------------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Name + Badges
              Row(
                children: [
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified || isGazetteer) ...[
                          const SizedBox(width: 6),
                          const GazetteerBadge(size: 20),
                        ],
                      ],
                    ),
                  ),

                  // ✅ NEW: Gazetteer Badge
                  if (isGazetteer && isVerified) ...[
                    const SizedBox(width: 6),
                    _GazetteerBadge(),
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

/// ============================================================================
/// GAZETTEER BADGE WIDGET
/// ============================================================================
/// Blue stamp icon with "Gazetteer" label
/// Shows for verified content creators
/// ============================================================================
class _GazetteerBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium, // Stamp/badge icon
            size: 12,
            color: Colors.blue,
          ),
          SizedBox(width: 3),
          Text(
            'Gazetteer',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
