// ============================================================================
// FILE: lib/features/common/widgets/badges_widgets.dart
// ============================================================================
// Version: 2.0.0 - CLEANED
//
// SINGLE SOURCE OF TRUTH for all badge widgets
// Import this file wherever badges are needed
// ============================================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:e6piccturenew/features/common/widgets/gazetteer_badge.dart';

// ============================================================================
// COLORS
// ============================================================================

abstract class BadgeColors {
  static const Color verified = Color(0xFF1DA1F2); // Twitter blue
  static const Color gazetteer = Color(0xFF3B6DB5); // Royal blue (stamp)
  static const Color mutual = Color(0xFF4CAF50); // Green
}

// ============================================================================
// VERIFIED BADGE - Simple blue checkmark
// ============================================================================

class VerifiedBadge extends StatelessWidget {
  final double size;

  const VerifiedBadge({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return GazetteerBadge.small();
  }
}

// ============================================================================
// GAZETTEER BADGE INLINE - For post headers (compact)
// ============================================================================
/* 
class GazetteerBadgeInline extends StatelessWidget {
  final double height;

  const GazetteerBadgeInline({super.key, this.height = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: height * 0.4,
        vertical: height * 0.12,
      ),
      decoration: BoxDecoration(
        color: BadgeColors.gazetteer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(height * 0.25),
        border: Border.all(
          color: BadgeColors.gazetteer.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            size: height * 0.7,
            color: BadgeColors.gazetteer,
          ),
          SizedBox(width: height * 0.15),
          Text(
            'GAZETTEER',
            style: TextStyle(
              color: BadgeColors.gazetteer,
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
 */
// ============================================================================
// GAZETTEER STAMP BADGE - Circular stamp for profiles
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
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final strokePaint = Paint()
      ..color = BadgeColors.gazetteer
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = BadgeColors.gazetteer
      ..style = PaintingStyle.fill;

    // Outer ring
    _drawDistressedCircle(
      canvas,
      center,
      radius * 0.95,
      strokePaint..strokeWidth = size.width * 0.045,
    );
    // Second ring
    _drawDistressedCircle(
      canvas,
      center,
      radius * 0.80,
      strokePaint..strokeWidth = size.width * 0.018,
    );
    // Third ring
    _drawDistressedCircle(
      canvas,
      center,
      radius * 0.72,
      strokePaint..strokeWidth = size.width * 0.012,
    );
    // Inner ring
    _drawDistressedCircle(
      canvas,
      center,
      radius * 0.45,
      strokePaint..strokeWidth = size.width * 0.025,
    );

    // Curved text
    _drawCurvedText(
      canvas,
      center,
      radius * 0.62,
      'GAZETTEER',
      size.width * 0.11,
    );

    // Center G
    _drawCenterG(canvas, center, size.width * 0.35);

    // Stars
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
  }

  void _drawDistressedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final path = Path();
    final random = math.Random(42);
    for (int i = 0; i <= 360; i += 2) {
      final angle = i * math.pi / 180;
      final distress = 1 + (random.nextDouble() - 0.5) * 0.1;
      final r = radius * distress;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
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
      final angle = startAngle + (anglePerChar * i);
      textPainter.text = TextSpan(
        text: text[i],
        style: TextStyle(
          color: BadgeColors.gazetteer,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      );
      textPainter.layout();
      canvas.save();
      canvas.translate(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
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
          color: BadgeColors.gazetteer,
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
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final radius = i.isEven ? size : size * 0.4;
      final angle = (i * math.pi / 4) - math.pi / 2;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0)
        path.moveTo(point.dx, point.dy);
      else
        path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// MUTUAL BADGE
// ============================================================================

class MutualBadge extends StatelessWidget {
  final double fontSize;

  const MutualBadge({super.key, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return Text(
      '· Mutual',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: BadgeColors.mutual,
      ),
    );
  }
}
