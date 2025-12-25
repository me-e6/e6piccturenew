import 'package:flutter/material.dart';
import '../feed/day_feed_controller.dart';
import '../feed/day_feed_service.dart';
import 'package:provider/provider.dart';
import '../home/home_screen_v3.dart';
import '../post/create/create_post_screen.dart';
import '../post/create/media_picker_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_controller.dart';
import '../follow/mutual_controller.dart';
import '../follow/follow_controller.dart';
import 'package:image_picker/image_picker.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isPlusExpanded = false;
  bool _isProfileActive = false;

  final MediaPickerService _mediaPicker = MediaPickerService();
  late final DayFeedController _dayFeedController;

  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _dayFeedController = DayFeedController(DayFeedService())..init();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.125,
    ).animate(_expandAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
    _dayFeedController.dispose();
    super.dispose();
  }

  void _togglePlus() {
    setState(() {
      _isPlusExpanded = !_isPlusExpanded;
      _isPlusExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  void _closePlus() {
    if (!_isPlusExpanded) return;
    setState(() {
      _isPlusExpanded = false;
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildCurrentTab(),

          if (_isPlusExpanded)
            GestureDetector(
              onTap: _closePlus,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.15)),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNavigation(),
          ),

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
      case 0:
        return ChangeNotifierProvider.value(
          value: _dayFeedController,
          child: const HomeScreenV3(),
        );

      case 4: // ✅ PROFILE TAB (FIXED INITIALIZATION)
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return const SizedBox.shrink();

        return MultiProvider(
          providers: [
            // ✅ FIXED: Initialize controllers with userId
            ChangeNotifierProvider(
              create: (_) =>
                  ProfileController()
                    ..loadProfileData(targetUserId: uid), // ✅ ADDED
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  MutualController()..loadMutual(targetUserId: uid), // ✅ ADDED
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  FollowController()
                    ..loadFollower(targetUserId: uid), // ✅ ADDED
            ),
          ],
          child: ProfileScreen(userId: uid),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      iconSize: 25,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 2) {
          _togglePlus();
          return;
        }

        _closePlus();

        setState(() {
          _currentIndex = index;
          _isProfileActive = index == 4;
        });
      },
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        const BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: ''),
        BottomNavigationBarItem(
          icon: GestureDetector(
            onTap: _togglePlus,
            child: Transform.translate(
              offset: const Offset(0, -6),
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (_, __) {
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: RotationTransition(
                          turns: _rotationAnimation,
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),

                      if (_isPlusExpanded)
                        Positioned(
                          bottom: 50,
                          child: Transform.scale(
                            scale: _expandAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(221, 9, 41, 8),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _PlusActionIcon(
                                    icon: Icons.camera_alt,
                                    label: 'Camera',
                                    onTap: _handleCamera,
                                  ),
                                  const SizedBox(width: 12),
                                  _PlusActionIcon(
                                    icon: Icons.upload,
                                    label: 'Upload',
                                    onTap: _handleUpload,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          label: '',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.photo), label: ''),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person,
            color: _isProfileActive
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          label: '',
        ),
      ],
    );
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(0, 0 * animation.value),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              margin: EdgeInsets.only(bottom: 70 + bottomPadding),
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: 140,
              decoration: BoxDecoration(
                color:
                    Theme.of(
                      context,
                    ).bottomNavigationBarTheme.backgroundColor ??
                    Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: Colors.black.withValues(alpha: 0.15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PlusAction(
                    label: 'Camera',
                    icon: Icons.camera_alt,
                    onTap: onCamera,
                  ),
                  const SizedBox(height: 4),
                  _PlusAction(
                    label: 'Upload',
                    icon: Icons.upload,
                    onTap: onUpload,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlusAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlusAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _PlusActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlusActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
