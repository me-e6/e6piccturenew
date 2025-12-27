import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../user/user_avatar_controller.dart';

// Core
import '../feed/day_feed_controller.dart';
import '../feed/day_feed_service.dart';

// Screens
import '../home/home_screen_v3.dart';
import '../pics/pics_gallery_screen.dart';
import '../post/create/create_post_screen.dart';
import '../post/create/media_picker_service.dart';
import '../profile/profile_screen.dart';

// Controllers
import '../profile/profile_controller.dart';
import '../follow/mutual_controller.dart';
import '../follow/follow_controller.dart';

/// ============================================================================
/// MAIN NAVIGATION V2 - FLOATING PILL DESIGN
/// ============================================================================
///
/// FEATURES:
/// ✅ Compact floating pill navigation (saves ~30px vertical space)
/// ✅ Glassmorphism effect with blur
/// ✅ Minimal icon-only design
/// ✅ Elevated center FAB for create
/// ✅ Haptic feedback on tap
/// ✅ Smooth animations
///
/// LAYOUT:
/// ┌──────────────────────────────────────────┐
/// │                                          │
/// │              CONTENT AREA                │
/// │                                          │
/// │    ┌──────────────────────────────┐      │
/// │    │  🏠   🤖   ➕   🖼️   👤  │      │  ← Floating Pill
/// │    └──────────────────────────────┘      │
/// └──────────────────────────────────────────┘
/// ============================================================================

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isPlusExpanded = false;

  final MediaPickerService _mediaPicker = MediaPickerService();
  late final DayFeedController _dayFeedController;

  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotationAnimation;

  // Constants for the compact nav bar
  static const double _navBarHeight = 57.0;
  static const double _navBarMargin = 10.0;
  static const double _navBarBottomPadding = 6.0;
  static const double _fabSize = 40.0;

  @override
  void initState() {
    super.initState();
    _dayFeedController = DayFeedController(DayFeedService())..init();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.125,
    ).animate(_expandAnimation);
  }

  @override
  void dispose() {
    _animController.dispose();
    _dayFeedController.dispose();
    super.dispose();
  }

  void _togglePlus() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isPlusExpanded = !_isPlusExpanded;
      _isPlusExpanded ? _animController.forward() : _animController.reverse();
    });
  }

  void _closePlus() {
    if (!_isPlusExpanded) return;
    setState(() {
      _isPlusExpanded = false;
      _animController.reverse();
    });
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      _togglePlus();
      return;
    }
    _closePlus();
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      // Make body extend behind the nav bar
      extendBody: true,
      body: Stack(
        children: [
          // Current tab content with bottom padding for nav bar
          Padding(
            padding: EdgeInsets.only(
              bottom: _navBarHeight + _navBarBottomPadding + bottomPadding,
            ),
            child: _buildCurrentTab(),
          ),

          // Overlay when plus is expanded
          if (_isPlusExpanded)
            GestureDetector(
              onTap: _closePlus,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),

          // Floating Navigation Bar
          Positioned(
            left: _navBarMargin,
            right: _navBarMargin,
            bottom: _navBarBottomPadding + bottomPadding,
            child: _buildFloatingNavBar(),
          ),

          // Plus expansion menu (above nav bar)
          if (_isPlusExpanded)
            Positioned(
              left: 0,
              right: 0,
              bottom: _navBarHeight + _navBarBottomPadding + bottomPadding + 16,
              child: _PlusExpansionMenu(
                animation: _expandAnimation,
                onCamera: _handleCamera,
                onUpload: _handleUpload,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return ChangeNotifierProvider.value(
          value: _dayFeedController,
          child: const HomeScreenV3(),
        );

      case 1:
        return const _AIPlaceholderScreen();

      case 3:
        return const PicsGalleryScreen();

      case 4:
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return const SizedBox.shrink();

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  ProfileController()..loadProfileData(targetUserId: uid),
            ),
            ChangeNotifierProvider(
              create: (_) => MutualController()..loadMutual(targetUserId: uid),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  FollowController()..loadFollower(targetUserId: uid),
            ),
          ],
          child: ProfileScreen(userId: uid),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOATING NAVIGATION BAR - GLASSMORPHISM PILL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFloatingNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: _navBarHeight,
      decoration: BoxDecoration(
        // Glassmorphism background
        color: isDark
            ? Colors.grey.shade900.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(_navBarHeight / 2),
        // Subtle border
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        // Shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_navBarHeight / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Home
              _CompactNavItem(
                icon: Icons.home_rounded,
                isActive: _currentIndex == 0,
                onTap: () => _onTabTapped(0),
              ),

              // AI
              _CompactNavItem(
                icon: Icons.auto_awesome_rounded,
                isActive: _currentIndex == 1,
                onTap: () => _onTabTapped(1),
              ),

              // Plus Button (elevated)
              _FloatingPlusButton(
                isExpanded: _isPlusExpanded,
                animation: _rotationAnimation,
                onTap: _togglePlus,
                size: _fabSize,
              ),

              // Pictures
              _CompactNavItem(
                icon: Icons.grid_view_rounded,
                isActive: _currentIndex == 3,
                onTap: () => _onTabTapped(3),
              ),

              // Profile
              _ProfileNavItem(
                isActive: _currentIndex == 4,
                onTap: () => _onTabTapped(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAMERA / UPLOAD HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _handleCamera() async {
    debugPrint('📸 Camera tapped');
    _closePlus();

    try {
      final file = await _mediaPicker.pickImage(source: ImageSource.camera);

      if (file == null) {
        debugPrint('Camera cancelled or failed');
        return;
      }

      if (!mounted) return;

      final xFile = XFile(file.path);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreatePostScreen(files: [xFile])),
      );
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to take photo: $e')));
    }
  }

  Future<void> _handleUpload() async {
    debugPrint('🖼 Upload tapped');
    _closePlus();

    try {
      final files = await _mediaPicker.pickMultipleImages();

      if (files.isEmpty) {
        debugPrint('Gallery picker cancelled or no images selected');
        return;
      }

      if (!mounted) return;

      final xFiles = files.map((file) => XFile(file.path)).toList();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreatePostScreen(files: xFiles)),
      );
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
    }
  }
}

/// ============================================================================
/// COMPACT NAV ITEM - Icon Only
/// ============================================================================
class _CompactNavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _CompactNavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? scheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isActive ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// ============================================================================
/// PROFILE NAV ITEM - Avatar
/// ============================================================================
class _ProfileNavItem extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _ProfileNavItem({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? scheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: uid == null
              ? Icon(
                  Icons.person_rounded,
                  size: 24,
                  color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                )
              : ChangeNotifierProvider(
                  create: (_) => UserAvatarController(uid),
                  child: Consumer<UserAvatarController>(
                    builder: (_, controller, __) {
                      return Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive
                                ? scheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: controller.avatarUrl != null
                              ? Image.network(
                                  controller.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildFallback(scheme),
                                )
                              : _buildFallback(scheme),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFallback(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.person, size: 16, color: scheme.onSurfaceVariant),
    );
  }
}

/// ============================================================================
/// FLOATING PLUS BUTTON - Elevated FAB
/// ============================================================================
class _FloatingPlusButton extends StatelessWidget {
  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onTap;
  final double size;

  const _FloatingPlusButton({
    required this.isExpanded,
    required this.animation,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -6), // Elevate above the bar
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary,
                Color.fromRGBO(
                  (scheme.primary.r * 255).round(),
                  (scheme.primary.g * 255).round(),
                  ((scheme.primary.b * 255) * 0.8).round(),
                  1.0,
                ),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: RotationTransition(
            turns: animation,
            child: Icon(Icons.add_rounded, color: scheme.onPrimary, size: 28),
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// PLUS EXPANSION MENU - Camera / Gallery Options
/// ============================================================================
class _PlusExpansionMenu extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onCamera;
  final VoidCallback onUpload;

  const _PlusExpansionMenu({
    required this.animation,
    required this.onCamera,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ScaleTransition(
        scale: animation,
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.grey.shade800.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ExpansionOption(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                onTap: onCamera,
              ),
              const SizedBox(width: 32),
              _ExpansionOption(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: onUpload,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpansionOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ExpansionOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.primary, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// AI PLACEHOLDER SCREEN
/// ============================================================================
class _AIPlaceholderScreen extends StatelessWidget {
  const _AIPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AI Assistant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 48,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'AI-powered features will help you discover and create amazing content',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
