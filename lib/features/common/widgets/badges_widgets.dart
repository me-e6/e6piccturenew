import 'package:flutter/material.dart';

/// ============================================================================
/// MUTUAL BADGE WIDGET
/// ============================================================================
/// Shows "Mutual" label for users who follow each other.
/// Use in post headers, profile cards, user lists.
/// 
/// Variants:
/// - Default: Pill with icon + text
/// - Compact: Just icon
/// - Inline: Text only
/// ============================================================================
class MutualBadge extends StatelessWidget {
  final MutualBadgeStyle style;
  final double? fontSize;
  final double? iconSize;

  const MutualBadge({
    super.key,
    this.style = MutualBadgeStyle.pill,
    this.fontSize,
    this.iconSize,
  });

  /// Compact version (just icon)
  const MutualBadge.compact({super.key})
      : style = MutualBadgeStyle.compact,
        fontSize = null,
        iconSize = 14;

  /// Inline version (text only)
  const MutualBadge.inline({super.key, this.fontSize = 11})
      : style = MutualBadgeStyle.inline,
        iconSize = null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    switch (style) {
      case MutualBadgeStyle.pill:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sync_alt,
                size: iconSize ?? 12,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                'Mutual',
                style: TextStyle(
                  fontSize: fontSize ?? 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        );

      case MutualBadgeStyle.compact:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.sync_alt,
            size: iconSize ?? 14,
            color: Colors.green.shade700,
          ),
        );

      case MutualBadgeStyle.inline:
        return Text(
          '· Mutual',
          style: TextStyle(
            fontSize: fontSize ?? 11,
            fontWeight: FontWeight.w500,
            color: Colors.green.shade700,
          ),
        );
    }
  }
}

enum MutualBadgeStyle {
  pill,    // Icon + "Mutual" in pill
  compact, // Just icon in circle
  inline,  // Just "· Mutual" text
}

/// ============================================================================
/// VERIFIED BADGE (Unified)
/// ============================================================================
/// Blue checkmark for verified users
/// ============================================================================
class VerifiedBadge extends StatelessWidget {
  final double size;
  final Color? color;

  const VerifiedBadge({
    super.key,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      size: size,
      color: color ?? Colors.blue,
    );
  }
}

/// ============================================================================
/// GAZETTEER BADGE (Inline version for lists)
/// ============================================================================
/// Blue stamp for Gazetteer users
/// ============================================================================
class GazetteerBadge extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool showLabel;

  const GazetteerBadge({
    super.key,
    this.iconSize = 14,
    this.fontSize = 10,
    this.showLabel = true,
  });

  /// Icon only version
  const GazetteerBadge.iconOnly({super.key, this.iconSize = 14})
      : fontSize = 10,
        showLabel = false;

  @override
  Widget build(BuildContext context) {
    if (!showLabel) {
      return Icon(
        Icons.workspace_premium,
        size: iconSize,
        color: Colors.blue,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            size: iconSize,
            color: Colors.blue,
          ),
          const SizedBox(width: 3),
          Text(
            'Gazetteer',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// USER BADGES ROW
/// ============================================================================
/// Displays all applicable badges for a user in a row
/// Order: Verified → Gazetteer → Mutual
/// ============================================================================
class UserBadgesRow extends StatelessWidget {
  final bool isVerified;
  final bool isGazetteer;
  final bool isMutual;
  final double spacing;
  final double iconSize;

  const UserBadgesRow({
    super.key,
    this.isVerified = false,
    this.isGazetteer = false,
    this.isMutual = false,
    this.spacing = 4,
    this.iconSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified && !isGazetteer && !isMutual) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isVerified) ...[
          VerifiedBadge(size: iconSize),
          SizedBox(width: spacing),
        ],
        if (isGazetteer) ...[
          GazetteerBadge.iconOnly(iconSize: iconSize),
          SizedBox(width: spacing),
        ],
        if (isMutual) const MutualBadge.compact(),
      ],
    );
  }
}

/// ============================================================================
/// POST AUTHOR HEADER (with all badges)
/// ============================================================================
/// Complete header for post cards showing:
/// - Avatar
/// - Display name + handle
/// - All badges
/// - Timestamp
/// ============================================================================
class PostAuthorHeader extends StatelessWidget {
  final String displayName;
  final String? handle;
  final String? avatarUrl;
  final bool isVerified;
  final bool isGazetteer;
  final bool isMutual;
  final DateTime? createdAt;
  final VoidCallback? onTap;

  const PostAuthorHeader({
    super.key,
    required this.displayName,
    this.handle,
    this.avatarUrl,
    this.isVerified = false,
    this.isGazetteer = false,
    this.isMutual = false,
    this.createdAt,
    this.onTap,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.surfaceContainerHighest,
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? Icon(Icons.person, size: 18, color: scheme.onSurfaceVariant)
                  : null,
            ),

            const SizedBox(width: 10),

            // Name + Handle + Badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row with badges
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 14),
                      ],
                      if (isGazetteer) ...[
                        const SizedBox(width: 4),
                        const GazetteerBadge.iconOnly(iconSize: 14),
                      ],
                    ],
                  ),

                  // Handle row with mutual badge
                  Row(
                    children: [
                      if (handle != null && handle!.isNotEmpty)
                        Text(
                          '@$handle',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      if (isMutual) ...[
                        const SizedBox(width: 6),
                        const MutualBadge.inline(),
                      ],
                      if (createdAt != null) ...[
                        Text(
                          ' · ${_formatTime(createdAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
