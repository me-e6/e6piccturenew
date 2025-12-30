import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:e6piccturenew/features/profile/profile_entry.dart';
import 'package:e6piccturenew/features/common/widgets/gazetteer_badge.dart';

/// ============================================================================
/// REPIC HEADER WIDGET
/// ============================================================================
/// Displays "🔄 Username repicced" header above repic posts in feeds.
/// Tapping navigates to the repiccer's profile.
/// ============================================================================
class RepicHeader extends StatelessWidget {
  final String repicAuthorId;
  final String repicAuthorName;
  final String? repicAuthorHandle;
  final String? repicAuthorAvatarUrl;
  final bool repicAuthorIsVerified;

  const RepicHeader({
    super.key,
    required this.repicAuthorId,
    required this.repicAuthorName,
    this.repicAuthorHandle,
    this.repicAuthorAvatarUrl,
    this.repicAuthorIsVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _navigateToProfile(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.5),
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Repic icon
            Icon(Icons.repeat_rounded, size: 16, color: scheme.primary),

            const SizedBox(width: 8),

            // Small avatar (optional)
            if (repicAuthorAvatarUrl != null &&
                repicAuthorAvatarUrl!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 6),
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: scheme.surfaceContainerHighest,
                  backgroundImage: CachedNetworkImageProvider(
                    repicAuthorAvatarUrl!,
                  ),
                ),
              ),

            // Name
            Flexible(
              child: Text(
                repicAuthorName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: scheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Verified badge
            if (repicAuthorIsVerified) ...[
              const SizedBox(width: 4),
              GazetteerBadge.small(),

              //Icon(Icons.verified, size: 14, color: scheme.primary),
            ],

            // "repicced" text
            const SizedBox(width: 4),
            Text(
              'repicced',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),

            const Spacer(),

            // Chevron
            Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileEntry(userId: repicAuthorId)),
    );
  }
}

/// ============================================================================
/// QUOTE HEADER WIDGET (Similar for quote posts)
/// ============================================================================
class QuoteHeader extends StatelessWidget {
  final String quoteAuthorId;
  final String quoteAuthorName;
  final String? quoteAuthorHandle;
  final bool quoteAuthorIsVerified;

  const QuoteHeader({
    super.key,
    required this.quoteAuthorId,
    required this.quoteAuthorName,
    this.quoteAuthorHandle,
    this.quoteAuthorIsVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _navigateToProfile(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.5),
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Quote icon
            Icon(Icons.format_quote_rounded, size: 16, color: scheme.secondary),

            const SizedBox(width: 8),

            // Name
            Flexible(
              child: Text(
                quoteAuthorName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: scheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Verified badge
            if (quoteAuthorIsVerified) ...[
              const SizedBox(width: 4),
              Icon(Icons.verified, size: 14, color: scheme.primary),
            ],

            // "quoted" text
            const SizedBox(width: 4),
            Text(
              'quoted',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),

            const Spacer(),

            // Chevron
            Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileEntry(userId: quoteAuthorId)),
    );
  }
}
