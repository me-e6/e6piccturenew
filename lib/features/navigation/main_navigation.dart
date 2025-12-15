import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/widgets/app_scaffold.dart';

import '../home/home_screen.dart';
import '../post/create/create_post_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final String _currentUid;
  late final List<Widget> _screens;

  bool _showMenu = false;
  late AnimationController _menuAnimation;

  @override
  void initState() {
    super.initState();

    _currentUid = FirebaseAuth.instance.currentUser!.uid;

    _screens = [
      const HomeScreen(),
      const CreatePostScreen(),
      ProfileScreen(uid: _currentUid),
    ];

    _menuAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  void _togglePlusMenu() {
    setState(() {
      _showMenu = !_showMenu;
      _showMenu ? _menuAnimation.forward() : _menuAnimation.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        AppScaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: _buildNavBar(context),
        ),

        // ------------------------------------------------
        // DIM BACKDROP
        // ------------------------------------------------
        if (_showMenu)
          GestureDetector(
            onTap: _togglePlusMenu,
            child: Container(color: Colors.black54),
          ),

        // ------------------------------------------------
        // PLUS MENU
        // ------------------------------------------------
        Positioned(
          bottom: 95,
          left: 0,
          right: 0,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: _menuAnimation,
              curve: Curves.easeOutBack,
            ),
            child: _buildPlusMenu(context),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------
  // BOTTOM NAV BAR (THEME-DRIVEN)
  // ------------------------------------------------
  Widget _buildNavBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, Icons.home, 0),

            _navAction(
              context,
              Icons.search,
              () => Navigator.pushNamed(context, "/search"),
            ),

            _centerPlusButton(context),

            _navAction(context, Icons.favorite_border, () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Likes coming soon")),
              );
            }),

            _navItem(context, Icons.person, 2),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------
  // NAV ITEMS
  // ------------------------------------------------
  Widget _navItem(BuildContext context, IconData icon, int index) {
    final scheme = Theme.of(context).colorScheme;
    final active = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? scheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 28,
          color: active ? scheme.primary : scheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _navAction(BuildContext context, IconData icon, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 28, color: scheme.onSurface),
      ),
    );
  }

  // ------------------------------------------------
  // CENTER PLUS BUTTON
  // ------------------------------------------------
  Widget _centerPlusButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _togglePlusMenu,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: scheme.background,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.primary, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.add, size: 30, color: scheme.primary),
      ),
    );
  }

  // ------------------------------------------------
  // PLUS MENU
  // ------------------------------------------------
  Widget _buildPlusMenu(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuItem(
              context,
              icon: Icons.camera_alt,
              label: "Take Photo",
              onTap: () {
                _togglePlusMenu();
                setState(() => _currentIndex = 1);
              },
            ),
            const SizedBox(height: 12),
            _menuItem(
              context,
              icon: Icons.photo_library,
              label: "Upload Photo",
              onTap: () {
                _togglePlusMenu();
                setState(() => _currentIndex = 1);
              },
            ),
            const SizedBox(height: 12),
            _menuItem(
              context,
              icon: Icons.qr_code_scanner,
              label: "Scan",
              onTap: () {
                _togglePlusMenu();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Scan coming soon")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 26, color: scheme.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
