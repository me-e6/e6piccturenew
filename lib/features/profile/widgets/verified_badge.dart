import 'package:flutter/material.dart';

/// ------------------------------------------------------------
/// VERIFIED BADGE (GAZETTER)
///
/// Usage:
/// VerifiedBadge(isVerified: true)
///
/// Design rules:
/// - Icon + label
/// - Neutral sizing (works in feed, viewer, profile)
/// - No business logic inside
/// ------------------------------------------------------------
class VerifiedBadge extends StatelessWidget {
  final bool isVerified;
  final double iconSize;
  final double fontSize;
  final Color color;

  const VerifiedBadge({
    super.key,
    required this.isVerified,
    this.iconSize = 14,
    this.fontSize = 12,
    this.color = const Color(0xFF1DA1F2), // Twitter-like blue
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified, size: iconSize, color: color),
        const SizedBox(width: 4),
        Text(
          "Gazetter",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
