import 'package:flutter/material.dart';
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
/// MAIN NAVIGATION - STABLE VERSION
/// ============================================================================
///
/// CORRECT 5-TAB LAYOUT:
/// ┌─────┬─────┬─────┬─────┬─────┐
/// │ 🏠  │ 🤖  │ ➕  │ 🖼️  │ 👤  │
/// │Home │ AI  │Plus │Pics │Prof │
/// └─────┴─────┴─────┴─────┴─────┘
///
/// Tab 0: Home Feed (with bell icon in AppBar)
/// Tab 1: AI Placeholder (Coming Soon)
/// Tab 2: Create Post (Plus button with camera/gallery)
/// Tab 3: Pictures Gallery (view/delete posts, repics, quotes, saved)
/// Tab 4: Profile (with settings bottom sheet)
///
/// NOTE: Notifications bell icon is in HomeScreenV3 AppBar, NOT in bottom nav
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Current tab content
          _buildCurrentTab(),

          // Overlay when plus is expanded
          if (_isPlusExpanded)
            GestureDetector(
              onTap: _closePlus,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.15)),
            ),

          // Bottom navigation bar
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNavigation(),
          ),

          // Plus expansion menu
          if (_isPlusExpanded)
            Align(
              alignment: Alignment.bottomCenter,
              child: _PlusExpansion(
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
      // ═══════════════════════════════════════════════════════════════════════
      // TAB 0: HOME FEED
      // ═══════════════════════════════════════════════════════════════════════
      case 0:
        return ChangeNotifierProvider.value(
          value: _dayFeedController,
          child: const HomeScreenV3(),
        );

      // ═══════════════════════════════════════════════════════════════════════
      // TAB 1: AI PLACEHOLDER
      // ═══════════════════════════════════════════════════════════════════════
      case 1:
        return const _AIPlaceholderScreen();

      // ═══════════════════════════════════════════════════════════════════════
      // TAB 3: PICTURES GALLERY
      // ═══════════════════════════════════════════════════════════════════════
      case 3:
        return const PicsGalleryScreen();

      // ═══════════════════════════════════════════════════════════════════════
      // TAB 4: PROFILE
      // ═══════════════════════════════════════════════════════════════════════
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

  Widget _buildBottomNavigation() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ═══════════════════════════════════════════════════════════════
              // TAB 0: HOME
              // ═══════════════════════════════════════════════════════════════
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                isActive: _currentIndex == 0,
                onTap: () => _onTabTapped(0),
              ),

              // ═══════════════════════════════════════════════════════════════
              // TAB 1: AI (Placeholder)
              // ═══════════════════════════════════════════════════════════════
              _NavItem(
                icon: Icons.smart_toy_outlined,
                activeIcon: Icons.smart_toy,
                isActive: _currentIndex == 1,
                onTap: () => _onTabTapped(1),
              ),

              // ═══════════════════════════════════════════════════════════════
              // TAB 2: PLUS (Create)
              // ═══════════════════════════════════════════════════════════════
              _PlusButton(
                isExpanded: _isPlusExpanded,
                animation: _rotationAnimation,
                onTap: _togglePlus,
              ),

              // ═══════════════════════════════════════════════════════════════
              // TAB 3: PICTURES GALLERY
              // ═══════════════════════════════════════════════════════════════
              _NavItem(
                icon: Icons.photo_library_outlined,
                activeIcon: Icons.photo_library,
                isActive: _currentIndex == 3,
                onTap: () => _onTabTapped(3),
              ),

              // ═══════════════════════════════════════════════════════════════
              // TAB 4: PROFILE
              // ═══════════════════════════════════════════════════════════════
              /*  _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                isActive: _currentIndex == 4,
                onTap: () => _onTabTapped(4),
              ), */
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

  void _onTabTapped(int index) {
    if (index == 2) {
      _togglePlus();
      return;
    }

    _closePlus();
    setState(() => _currentIndex = index);
  }

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
/// AI PLACEHOLDER SCREEN
/// ============================================================================
class _AIPlaceholderScreen extends StatelessWidget {
  const _AIPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Features'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.smart_toy, size: 64, color: scheme.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'AI Features Coming Soon',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We\'re working on exciting AI-powered features to enhance your Piccture experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Stay tuned!',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// NAV ITEM
/// ============================================================================
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 26,
              color: isActive ? scheme.primary : scheme.onSurfaceVariant,
            ),
            if (badge != null && badge! > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge! > 99 ? '99+' : badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: uid == null
              ? Icon(
                  Icons.person_outline,
                  size: 26,
                  color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                )
              : ChangeNotifierProvider(
                  create: (_) => UserAvatarController(uid),
                  child: Consumer<UserAvatarController>(
                    builder: (_, controller, __) {
                      return Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isActive
                              ? Border.all(color: scheme.primary, width: 2)
                              : null,
                        ),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: scheme.surfaceContainerHighest,
                          backgroundImage: controller.avatarUrl != null
                              ? NetworkImage(controller.avatarUrl!)
                              : null,
                          child: controller.avatarUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 16,
                                  color: scheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// PLUS BUTTON
/// ============================================================================
class _PlusButton extends StatelessWidget {
  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _PlusButton({
    required this.isExpanded,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: RotationTransition(
          turns: animation,
          child: Icon(Icons.add, color: scheme.onPrimary, size: 28),
        ),
      ),
    );
  }
}

/// ============================================================================
/// PLUS EXPANSION
/// ============================================================================
class _PlusExpansion extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onCamera;
  final VoidCallback onUpload;

  const _PlusExpansion({
    required this.animation,
    required this.onCamera,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: ScaleTransition(
        scale: animation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PlusOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: onCamera,
              ),
              const SizedBox(width: 24),
              _PlusOption(
                icon: Icons.photo_library,
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

class _PlusOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlusOption({
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.primary, size: 24),
          ),
          const SizedBox(height: 4),
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
