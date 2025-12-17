import 'package:flutter/material.dart';
import '../feed/day_feed_controller.dart';
import '../feed/day_feed_service.dart';
import 'package:provider/provider.dart';
import '../home/home_screen_v3.dart';
import '../post/create/create_post_screen.dart';
import '../post/create/media_picker_service.dart';
import '../home/home_screen_v3.dart';

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
      end: 0.125, // 45°
    ).animate(_expandAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
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

          /// TAP OUTSIDE (BLOCKS BACKGROUND ONLY)
          if (_isPlusExpanded)
            GestureDetector(
              onTap: _closePlus,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.15)),
            ),

          /// BOTTOM NAV (BELOW PLUS)
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNavigation(),
          ),

          /// PLUS EXPANSION (TOPMOST — MUST BE LAST)
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

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: (index) {
        if (index == 2) {
          _togglePlus();
          return;
        }
        _closePlus();
        setState(() => _currentIndex = index);
      },
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI'),
        BottomNavigationBarItem(
          icon: RotationTransition(
            turns: _rotationAnimation,
            child: const Icon(Icons.add),
          ),
          label: '',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.photo),
          label: 'Pictures',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PLUS ACTION HANDLERS
  // ---------------------------------------------------------------------------

  Future<void> _handleCamera() async {
    debugPrint('📸 Camera tapped');
    _closePlus();

    final file = await _mediaPicker.pickFromCamera();
    if (file == null) return;
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatePostScreen(files: [file])),
    );
  }

  Future<void> _handleUpload() async {
    debugPrint('🖼 Upload tapped');
    _closePlus();

    final files = await _mediaPicker.pickFromGallery();
    if (files.isEmpty) return;
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatePostScreen(files: files)),
    );
  }
}

/// ---------------------------------------------------------------------------
/// PLUS EXPANSION (NO IgnorePointer — TOPMOST)
// ---------------------------------------------------------------------------

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
          offset: Offset(0, -120 * animation.value),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              margin: EdgeInsets.only(bottom: 56 + bottomPadding),
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: 140,
              decoration: BoxDecoration(
                color:
                    Theme.of(
                      context,
                    ).bottomNavigationBarTheme.backgroundColor ??
                    Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
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
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: onCamera,
                  ),
                  const SizedBox(height: 8),
                  _PlusAction(
                    icon: Icons.upload,
                    label: 'Upload',
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
