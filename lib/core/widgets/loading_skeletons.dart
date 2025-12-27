import 'package:flutter/material.dart';

/// ============================================================================
/// SHIMMER LOADING WIDGET
/// ============================================================================
/// Creates a shimmering effect for loading states
/// ============================================================================
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: isDark
                  ? [
                      Colors.grey.shade800,
                      Colors.grey.shade600,
                      Colors.grey.shade800,
                    ]
                  : [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                      Colors.grey.shade300,
                    ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// ============================================================================
/// SKELETON BOX
/// ============================================================================
/// Basic skeleton placeholder box
/// ============================================================================
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

/// ============================================================================
/// SKELETON LINE
/// ============================================================================
/// Text line placeholder
/// ============================================================================
class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(4),
    );
  }
}

/// ============================================================================
/// SKELETON CIRCLE
/// ============================================================================
/// Avatar placeholder
/// ============================================================================
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }
}

/// ============================================================================
/// POST CARD SKELETON
/// ============================================================================
/// Loading skeleton for post cards
/// ============================================================================
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const SkeletonCircle(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(width: 120, height: 14),
                        const SizedBox(height: 6),
                        SkeletonLine(width: 80, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Image
            const AspectRatio(
              aspectRatio: 1,
              child: SkeletonBox(borderRadius: BorderRadius.zero),
            ),

            // Caption
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLine(height: 14),
                  const SizedBox(height: 8),
                  SkeletonLine(width: 200, height: 14),
                ],
              ),
            ),

            // Engagement bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (_) => SkeletonBox(width: 40, height: 24, borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// USER TILE SKELETON
/// ============================================================================
/// Loading skeleton for user list items
/// ============================================================================
class UserTileSkeleton extends StatelessWidget {
  const UserTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SkeletonCircle(size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(width: 120, height: 14),
                  const SizedBox(height: 6),
                  SkeletonLine(width: 80, height: 12),
                ],
              ),
            ),
            SkeletonBox(
              width: 80,
              height: 32,
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// PROFILE SKELETON
/// ============================================================================
/// Loading skeleton for profile screen
/// ============================================================================
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          // Banner
          const SkeletonBox(
            width: double.infinity,
            height: 150,
            borderRadius: BorderRadius.zero,
          ),

          // Avatar and info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 4,
                      ),
                    ),
                    child: const SkeletonCircle(size: 80),
                  ),
                ),
                const Spacer(),
                SkeletonBox(
                  width: 100,
                  height: 36,
                  borderRadius: BorderRadius.circular(18),
                ),
              ],
            ),
          ),

          // Name and bio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 150, height: 20),
                const SizedBox(height: 8),
                SkeletonLine(width: 100, height: 14),
                const SizedBox(height: 16),
                const SkeletonLine(height: 14),
                const SizedBox(height: 6),
                SkeletonLine(width: 250, height: 14),
              ],
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (_) => Column(
                  children: [
                    SkeletonLine(width: 40, height: 20),
                    const SizedBox(height: 4),
                    SkeletonLine(width: 60, height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// GRID SKELETON
/// ============================================================================
/// Loading skeleton for photo grids
/// ============================================================================
class GridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const GridSkeleton({
    super.key,
    this.itemCount = 9,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(2),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => const SkeletonBox(
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}

/// ============================================================================
/// NOTIFICATION SKELETON
/// ============================================================================
class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonCircle(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLine(height: 14),
                  const SizedBox(height: 6),
                  SkeletonLine(width: 150, height: 12),
                  const SizedBox(height: 4),
                  SkeletonLine(width: 60, height: 10),
                ],
              ),
            ),
            SkeletonBox(
              width: 50,
              height: 50,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// SKELETON LIST
/// ============================================================================
/// Helper to generate a list of skeletons
/// ============================================================================
class SkeletonList extends StatelessWidget {
  final Widget Function(BuildContext, int) itemBuilder;
  final int itemCount;

  const SkeletonList({
    super.key,
    required this.itemBuilder,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  /// Create list of post card skeletons
  static Widget postCards({int count = 3}) {
    return SkeletonList(
      itemCount: count,
      itemBuilder: (_, __) => const PostCardSkeleton(),
    );
  }

  /// Create list of user tile skeletons
  static Widget userTiles({int count = 5}) {
    return SkeletonList(
      itemCount: count,
      itemBuilder: (_, __) => const UserTileSkeleton(),
    );
  }

  /// Create list of notification skeletons
  static Widget notifications({int count = 5}) {
    return SkeletonList(
      itemCount: count,
      itemBuilder: (_, __) => const NotificationSkeleton(),
    );
  }
}
