// ============================================================================
// FILE: lib/features/common/widgets/gazetteer_badge.dart
// ============================================================================
// Production-grade Gazetteer verification badge
// Based on the official stamp design
//
// USAGE:
//   GazetteerBadge.large()      - 80px for profile headers
//   GazetteerBadge.medium()     - 48px for cards/lists
//   GazetteerBadge.small()      - 24px for inline text
//   GazetteerBadge.micro()      - 16px for compact spaces
//
// ASSET VERSION (for highest quality):
//   GazetteerBadgeAsset(size: 80)
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:e6piccturenew/features/common/widgets/gazetteer_badge.dart';

// ============================================================================
// MAIN BADGE WIDGET - VECTOR VERSION
// ============================================================================

class GazetteerBadge extends StatelessWidget {
  final double size;
  final bool showGlow;
  final bool animated;

  const GazetteerBadge({
    super.key,
    required this.size,
    this.showGlow = false,
    this.animated = false,
  });

  // Factory constructors for standard sizes
  factory GazetteerBadge.large({bool showGlow = true}) =>
      GazetteerBadge(size: 80, showGlow: showGlow);

  factory GazetteerBadge.medium({bool showGlow = false}) =>
      GazetteerBadge(size: 48, showGlow: showGlow);

  factory GazetteerBadge.small() => const GazetteerBadge(size: 24);

  factory GazetteerBadge.micro() => const GazetteerBadge(size: 16);

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      width: size,
      height: size,
      decoration: showGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: GazetteerColors.primary.withValues(alpha: 0.3),
                  blurRadius: size * 0.2,
                  spreadRadius: size * 0.05,
                ),
              ],
            )
          : null,
      child: CustomPaint(
        size: Size(size, size),
        painter: _GazetteerStampPainter(),
      ),
    );

    if (animated) {
      badge = _AnimatedGazetteerBadge(size: size, child: badge);
    }

    return badge;
  }
}

// ============================================================================
// COLORS
// ============================================================================

abstract class GazetteerColors {
  static const Color primary = Color(0xFF3B6DB5); // Royal blue from image
  static const Color primaryLight = Color(0xFF5A8AD4);
  static const Color primaryDark = Color(0xFF2A5090);
}

// ============================================================================
// CUSTOM PAINTER - DRAWS THE STAMP
// ============================================================================

class _GazetteerStampPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Main paint for stamp elements
    final paint = Paint()
      ..color = GazetteerColors.primary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color.fromARGB(255, 2, 33, 75)
      ..style = PaintingStyle.fill;

    // ─────────────────────────────────────────────────────────────────────────
    // OUTER DISTRESSED RING
    // ─────────────────────────────────────────────────────────────────────────
    _drawDistressedCircle(
      canvas,
      center,
      radius * 0.95,
      paint..strokeWidth = size.width * 0.04,
      distressLevel: 0.10,
    );

    // ─────────────────────────────────────────────────────────────────────────
    // SECOND RING (thinner)
    // ─────────────────────────────────────────────────────────────────────────
    _drawDistressedCircle(
      canvas,
      center,
      radius * 0.9,
      paint..strokeWidth = size.width * 0.015,
      distressLevel: 0.1,
    );

    // ─────────────────────────────────────────────────────────────────────────
    // THIRD RING
    // ─────────────────────────────────────────────────────────────────────────
    _drawDistressedCircle(
      canvas,
      center,
      radius * 0.75,
      paint..strokeWidth = size.width * 0.020,
      distressLevel: 0.08,
    );

    // ─────────────────────────────────────────────────────────────────────────
    // INNER FILLED CIRCLE (for "G" background)
    // ─────────────────────────────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius * 0.45,
      fillPaint..color = GazetteerColors.primary.withValues(alpha: 0.1),
    );

    // Inner circle border
    _drawDistressedCircle(
      canvas,
      center,
      radius * 0.45,
      paint..strokeWidth = size.width * 0.035,
      distressLevel: 0.05,
    );

    // ─────────────────────────────────────────────────────────────────────────
    // CURVED "GAZETTEER" TEXT
    // ─────────────────────────────────────────────────────────────────────────
    _drawCurvedText(
      canvas,
      center,
      radius * 0.68,
      'GAZETTEER',
      size.width * 0.11,
    );

    // ─────────────────────────────────────────────────────────────────────────
    // CENTER "G"
    // ─────────────────────────────────────────────────────────────────────────
    _drawCenterG(canvas, center, size.width * 0.50);

    // ─────────────────────────────────────────────────────────────────────────
    // DECORATIVE STARS
    // ─────────────────────────────────────────────────────────────────────────
    _drawStar(
      canvas,
      Offset(center.dx - radius * 0.55, center.dy + radius * 0.25),
      size.width * 0.04,
      fillPaint,
    );
    _drawStar(
      canvas,
      Offset(center.dx + radius * 0.55, center.dy + radius * 0.25),
      size.width * 0.04,
      fillPaint,
    );

    // ─────────────────────────────────────────────────────────────────────────
    // DISTRESS/GRUNGE SPOTS (for authentic stamp look)
    // ─────────────────────────────────────────────────────────────────────────
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
    final random = math.Random(42); // Fixed seed for consistency

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

    // Calculate total arc length needed
    const startAngle = -math.pi * 0.75; // Start from top-left
    const sweepAngle = math.pi * 0.5; // Sweep to top-right
    final anglePerChar = sweepAngle / (text.length - 1);

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final angle = startAngle + (anglePerChar * i);

      textPainter.text = TextSpan(
        text: char,
        style: TextStyle(
          color: GazetteerColors.primary,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          fontFamily: 'Arial',
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
          color: GazetteerColors.primary,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          fontFamily: 'Arial',
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
    final spots = <Offset>[
      Offset(center.dx + radius * 0.85, center.dy - radius * 0.3),
      Offset(center.dx - radius * 0.8, center.dy - radius * 0.5),
      Offset(center.dx + radius * 0.7, center.dy + radius * 0.7),
      Offset(center.dx - radius * 0.9, center.dy + radius * 0.1),
      Offset(center.dx + radius * 0.3, center.dy - radius * 0.9),
      Offset(center.dx - radius * 0.4, center.dy + radius * 0.85),
    ];

    for (final spot in spots) {
      final spotRadius = radius * 0.02 * (0.5 + random.nextDouble());
      canvas.drawCircle(
        spot,
        spotRadius,
        paint..color = GazetteerColors.primary.withValues(alpha: 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// ANIMATED VERSION
// ============================================================================

class _AnimatedGazetteerBadge extends StatefulWidget {
  final double size;
  final Widget child;

  const _AnimatedGazetteerBadge({required this.size, required this.child});

  @override
  State<_AnimatedGazetteerBadge> createState() =>
      _AnimatedGazetteerBadgeState();
}

class _AnimatedGazetteerBadgeState extends State<_AnimatedGazetteerBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.2,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: GazetteerColors.primary.withValues(
                    alpha: _glowAnimation.value,
                  ),
                  blurRadius: widget.size * 0.3,
                  spreadRadius: widget.size * 0.1,
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// ============================================================================
// ASSET-BASED VERSION (for highest quality)
// ============================================================================

/// Use this version when you have the actual PNG/SVG asset
/// Place the image at: assets/images/gazetteer_badge.png
///
/// Add to pubspec.yaml:
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/gazetteer_badge.png
/// ```
class GazetteerBadgeAsset extends StatelessWidget {
  final double size;
  final bool showGlow;

  const GazetteerBadgeAsset({
    super.key,
    required this.size,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: GazetteerColors.primary.withValues(alpha: 0.3),
                  blurRadius: size * 0.2,
                  spreadRadius: size * 0.05,
                ),
              ],
            )
          : null,
      child: Image.asset(
        'assets/images/gazetteer_badge.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        // Fallback to vector version if asset not found
        errorBuilder: (context, error, stackTrace) {
          return GazetteerBadge(size: size, showGlow: showGlow);
        },
      ),
    );
  }
}

// ============================================================================
// INLINE BADGE (for use next to username in posts)
// ============================================================================

class GazetteerBadgeInline extends StatelessWidget {
  final double height;

  const GazetteerBadgeInline({super.key, this.height = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 0.4),
      decoration: BoxDecoration(
        color: GazetteerColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(height * 0.25),
        border: Border.all(
          color: GazetteerColors.primary.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GazetteerBadge.small(), //Gazetter Icon

          SizedBox(width: height * 0.15),
          Text(
            'GAZETTEER',
            style: TextStyle(
              color: GazetteerColors.primary,
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
// PROFILE BADGE WITH TOOLTIP
// ============================================================================

class GazetteerProfileBadge extends StatelessWidget {
  final double size;

  const GazetteerProfileBadge({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Verified Gazetteer\nTrusted contributor',
      preferBelow: false,
      child: GestureDetector(
        onTap: () => _showBadgeInfo(context),
        child: GazetteerBadge.large(showGlow: true),
      ),
    );
  }

  void _showBadgeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GazetteerBadge(size: 100, showGlow: true),
            const SizedBox(height: 16),
            const Text(
              'Gazetteer Verified',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This account has been verified as a trusted contributor to the Piccture community.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _InfoChip(icon: Icons.check, label: 'Identity Verified'),
                const SizedBox(width: 8),
                _InfoChip(icon: Icons.shield, label: 'Trusted'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: GazetteerColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GazetteerColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: GazetteerColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
