import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Plus menu controller
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
      if (_showMenu) {
        _menuAnimation.forward();
      } else {
        _menuAnimation.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5EDE3),
          body: _screens[_currentIndex],

          bottomNavigationBar: _buildNavBar(),
        ),

        // DIM BACKDROP
        if (_showMenu)
          GestureDetector(
            onTap: _togglePlusMenu,
            child: Container(color: Colors.black38),
          ),

        // POP-UP MENU
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
  // BOTTOM NAVIGATION BAR
  // ------------------------------------------------
  Widget _buildNavBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E2D2),
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
            _navItem(Icons.home, 0),
            _navSearch(),

            _centerPlusButton(),

            _navIconAction(Icons.favorite_border, () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Likes coming soon")),
              );
            }),

            _navItem(Icons.person, 2),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------
  // ICONS
  // ------------------------------------------------

  Widget _navItem(IconData icon, int index) {
    bool active = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFC56A45).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 28,
          color: active ? const Color(0xFFC56A45) : const Color(0xFF6C7A4C),
        ),
      ),
    );
  }

  Widget _navIconAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.all(10),
        child: Icon(Icons.favorite_border, size: 28, color: Color(0xFF6C7A4C)),
      ),
    );
  }

  Widget _navSearch() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, "/search"),
      child: const Padding(
        padding: EdgeInsets.all(10),
        child: Icon(Icons.search, size: 28, color: Color(0xFF6C7A4C)),
      ),
    );
  }

  // ------------------------------------------------
  // CENTER PLUS BUTTON
  // ------------------------------------------------
  Widget _centerPlusButton() {
    return GestureDetector(
      onTap: _togglePlusMenu,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: const Color(0xFFF5EDE3),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFC56A45), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, size: 30, color: Color(0xFFC56A45)),
      ),
    );
  }

  // ------------------------------------------------
  // PLUS POP-UP MENU
  // ------------------------------------------------
  Widget _buildPlusMenu(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E2D2),
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
              icon: Icons.camera_alt,
              label: "Take Photo",
              onTap: () {
                _togglePlusMenu();
                setState(() => _currentIndex = 1);
              },
            ),

            const SizedBox(height: 12),

            _menuItem(
              icon: Icons.photo_library,
              label: "Upload Photo",
              onTap: () {
                _togglePlusMenu();
                setState(() => _currentIndex = 1);
              },
            ),

            const SizedBox(height: 12),

            _menuItem(
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

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 26, color: const Color(0xFF6C7A4C)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2F2F2F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
