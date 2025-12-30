// ============================================================================
// FILE: lib/features/profile/widgets/profile_identity_banner.dart
// ============================================================================
// Version: 2.0.0 - CLEANED
// Features:
// ✅ Twitter-style banner + avatar overlap
// ✅ New circular Gazetteer stamp badge (matching official design)
// ✅ Video DP support
// ✅ Follow button
// ✅ Clean visual hierarchy
// ============================================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:e6piccturenew/features/common/widgets/gazetteer_badge.dart';
// ============================================================================
// PROFILE IDENTITY BANNER
// ============================================================================

class ProfileIdentityBanner extends StatelessWidget {
  final String displayName;
  final String? handle;
  final String? avatarUrl;
  final String? bannerUrl;
  final bool isVerified;
  final bool isGazetteer;
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
    this.isGazetteer = false,
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

  // Check if user should show Gazetteer badge
  bool get _showGazetteerBadge => isVerified || isGazetteer;

  // ──────────────────────────────────────────────────────────────────────────
  // VIDEO DP ACTION SHEET
  // ──────────────────────────────────────────────────────────────────────────
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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ════════════════════════════════════════════════════════════════════
        // BANNER + OVERLAPPING AVATAR (TWITTER STYLE)
        // ════════════════════════════════════════════════════════════════════
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Banner
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
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
                child: _buildEditButton(
                  onTap: isUpdatingBanner ? null : onEditBanner,
                  isLoading: isUpdatingBanner,
                ),
              ),

            // Avatar (overlapping banner)
            Positioned(left: 16, bottom: -40, child: _buildAvatar(context)),
          ],
        ),

        const SizedBox(height: 8),

        // ════════════════════════════════════════════════════════════════════
        // ACTION BUTTONS ROW
        // ════════════════════════════════════════════════════════════════════
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    side: BorderSide(color: scheme.outline),
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
                      side: BorderSide(color: scheme.outline),
                    ),
                    child: const Icon(Icons.videocam, size: 18),
                  ),
                ],
              ] else
                _buildFollowButton(scheme),

              // ════════════════════════════════════════════════════════════════
              // GAZETTEER STAMP BADGE (Prominent, below handle)
              // ════════════════════════════════════════════════════════════════
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ════════════════════════════════════════════════════════════════════
        // NAME + BADGES + HANDLE + BIO
        // ════════════════════════════════════════════════════════════════════
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Name + Verified checkmark
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_showGazetteerBadge) ...[
                    const SizedBox(width: 6),
                    GazetteerBadge.small(),
                    //const GazetteerStampBadge(size: 70),
                  ],
                  /* if (_showGazetteerBadge) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.verified, size: 22, color: Colors.blue.shade500),
                  ], */
                ],
              ),

              const SizedBox(height: 2),

              // Handle
              if (handle != null && handle!.isNotEmpty)
                Text(
                  '@$handle',
                  style: TextStyle(
                    fontSize: 15,
                    color: scheme.onSurfaceVariant,
                  ),
                ),

              /* // ════════════════════════════════════════════════════════════════
              // GAZETTEER STAMP BADGE (Prominent, below handle)
              // ════════════════════════════════════════════════════════════════
              if (_showGazetteerBadge) ...[
                const SizedBox(height: 12),
                GazetteerBadge.medium()
                //const GazetteerStampBadge(size: 70),
              ], */

              // Bio
              if (bio != null && bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  bio!,
                  style: TextStyle(fontSize: 15, color: scheme.onSurface),
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

  Widget _buildEditButton({VoidCallback? onTap, required bool isLoading}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: isLoading
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
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Stack(
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
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 4,
              ),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
          ),
        ),

        // Video DP badge
        if (hasVideoDp)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF0F8831),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.play_arrow,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFollowButton(ColorScheme scheme) {
    return ElevatedButton(
      onPressed: onFollowToggle,
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing
            ? Colors.transparent
            : const Color(0xFF0F8831),
        foregroundColor: isFollowing ? scheme.onSurface : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isFollowing
              ? BorderSide(color: scheme.outline)
              : BorderSide.none,
        ),
        elevation: 0,
      ),
      child: Text(
        isFollowing ? 'Following' : 'Follow',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ============================================================================
// GAZETTEER STAMP BADGE - Circular Stamp (Matches Official Design)
// ============================================================================
// Based on the official Gazetteer stamp with:
// - Circular design with multiple rings
// - "GAZETTEER" text curved at top
// - Large "G" in center
// - Decorative stars
// - Distressed ink effect
// ============================================================================

class GazetteerStampBadge extends StatelessWidget {
  final double size;

  const GazetteerStampBadge({super.key, this.size = 70});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GazetteerStampPainter(),
    );
  }
}

class _GazetteerStampPainter extends CustomPainter {
  static const _stampColor = Color(0xFF3B6DB5); // Royal blue from image

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final strokePaint = Paint()
      ..color = _stampColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = _stampColor
      ..style = PaintingStyle.fill;

    // ────────────────────────────────────────────────────────────────────────
    // OUTER DISTRESSED RING
    // ────────────────────────────────────────────────────────────────────────
    _drawDistressedCircle(
      canvas,
      center,
      radius * 0.95,
      strokePaint..strokeWidth = size.width * 0.045,
      distressLevel: 0.12,
    );

    // ────────────────────────────────────────────────────────────────────────
    // SECOND RING
    // ────────────────────────────────────────────────────────────────────────
    _drawDistressedCircle(
      canvas,
      center,
      radius * 0.80,
      strokePaint..strokeWidth = size.width * 0.018,
      distressLevel: 0.08,
    );

    // ────────────────────────────────────────────────────────────────────────
    // THIRD RING
    // ────────────────────────────────────────────────────────────────────────
    _drawDistressedCircle(
      canvas,
      center,
      radius * 0.72,
      strokePaint..strokeWidth = size.width * 0.012,
      distressLevel: 0.06,
    );

    // ────────────────────────────────────────────────────────────────────────
    // INNER CIRCLE BORDER
    // ────────────────────────────────────────────────────────────────────────
    _drawDistressedCircle(
      canvas,
      center,
      radius * 0.45,
      strokePaint..strokeWidth = size.width * 0.025,
      distressLevel: 0.04,
    );

    // ────────────────────────────────────────────────────────────────────────
    // "GAZETTEER" CURVED TEXT
    // ────────────────────────────────────────────────────────────────────────
    _drawCurvedText(
      canvas,
      center,
      radius * 0.62,
      'GAZETTEER',
      size.width * 0.11,
    );

    // ────────────────────────────────────────────────────────────────────────
    // CENTER "G"
    // ────────────────────────────────────────────────────────────────────────
    _drawCenterG(canvas, center, size.width * 0.35);

    // ────────────────────────────────────────────────────────────────────────
    // DECORATIVE STARS
    // ────────────────────────────────────────────────────────────────────────
    _drawStar(
      canvas,
      Offset(center.dx - radius * 0.52, center.dy + radius * 0.28),
      size.width * 0.045,
      fillPaint,
    );
    _drawStar(
      canvas,
      Offset(center.dx + radius * 0.52, center.dy + radius * 0.28),
      size.width * 0.045,
      fillPaint,
    );

    // ────────────────────────────────────────────────────────────────────────
    // DISTRESS SPOTS (authentic stamp look)
    // ────────────────────────────────────────────────────────────────────────
    _drawDistressSpots(canvas, center, radius, fillPaint);
  }

  void _drawDistressedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint, {
    double distressLevel = 0.1,
  }) {
    final path = Path();
    final random = math.Random(42);

    for (int i = 0; i <= 360; i += 2) {
      final angle = i * math.pi / 180;
      final distress = 1 + (random.nextDouble() - 0.5) * distressLevel;
      final r = radius * distress;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCurvedText(
    Canvas canvas,
    Offset center,
    double radius,
    String text,
    double fontSize,
  ) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const startAngle = -math.pi * 0.78;
    const sweepAngle = math.pi * 0.56;
    final anglePerChar = sweepAngle / (text.length - 1);

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final angle = startAngle + (anglePerChar * i);

      textPainter.text = TextSpan(
        text: char,
        style: TextStyle(
          color: _stampColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      );
      textPainter.layout();

      canvas.save();
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.translate(x, y);
      canvas.rotate(angle + math.pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  void _drawCenterG(Canvas canvas, Offset center, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'G',
        style: TextStyle(
          color: _stampColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 + fontSize * 0.05,
      ),
    );
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 4;
    final outerRadius = size;
    final innerRadius = size * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDistressSpots(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final random = math.Random(123);
    final spots = [
      Offset(center.dx + radius * 0.85, center.dy - radius * 0.3),
      Offset(center.dx - radius * 0.8, center.dy - radius * 0.5),
      Offset(center.dx + radius * 0.7, center.dy + radius * 0.7),
      Offset(center.dx - radius * 0.9, center.dy + radius * 0.1),
    ];

    for (final spot in spots) {
      final spotRadius = radius * 0.02 * (0.5 + random.nextDouble());
      canvas.drawCircle(
        spot,
        spotRadius,
        paint..color = _stampColor.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// INLINE GAZETTEER BADGE - For post headers
// ============================================================================

class GazetteerBadgeInline extends StatelessWidget {
  final double height;

  const GazetteerBadgeInline({super.key, this.height = 16});

  @override
  Widget build(BuildContext context) {
    const stampColor = Color(0xFF3B6DB5);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: height * 0.4,
        vertical: height * 0.15,
      ),
      decoration: BoxDecoration(
        color: stampColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(height * 0.25),
        border: Border.all(color: stampColor.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: height * 0.7, color: stampColor),
          SizedBox(width: height * 0.15),
          Text(
            'GAZETTEER',
            style: TextStyle(
              color: stampColor,
              fontSize: height * 0.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SIMPLE VERIFIED BADGE - Blue checkmark
// ============================================================================

class VerifiedBadge extends StatelessWidget {
  final double size;

  const VerifiedBadge({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.verified, size: size, color: const Color(0xFF1DA1F2));
  }
}
