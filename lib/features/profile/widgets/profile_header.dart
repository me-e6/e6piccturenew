import 'package:flutter/material.dart';
import '../../common/widgets/gazetter_badge.dart';

class ProfileHeader extends StatelessWidget {
  final String displayName;
  final String? photoUrl;
  final bool isVerified;

  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.isVerified,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --------------------------------------------------
          // PROFILE PHOTO
          // --------------------------------------------------
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                ? NetworkImage(photoUrl!)
                : null,
            child: photoUrl == null || photoUrl!.isEmpty
                ? const Icon(Icons.person, size: 34, color: Colors.white)
                : null,
          ),

          const SizedBox(width: 14),

          // --------------------------------------------------
          // NAME + GAZETTER BADGE
          // --------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),

                    // ✅ VERIFIED GAZETTER
                    if (isVerified)
                      const GazetterBadge(iconSize: 16, fontSize: 12),
                  ],
                ),

                const SizedBox(height: 4),

                if (isVerified)
                  const Text(
                    "Official Gazzetter Account",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
