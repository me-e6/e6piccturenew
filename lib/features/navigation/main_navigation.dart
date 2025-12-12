/* /* import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../post/create/create_post_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CreatePostScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE3),

      body: _screens[_currentIndex],

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE8E2D2),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFFE8E2D2),
          selectedItemColor: const Color(0xFFC56A45),
          unselectedItemColor: const Color(0xFF6C7A4C),
          currentIndex: _currentIndex,
          elevation: 0,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: "Create",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
 */

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

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final String _currentUid;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // 🔥 Get logged-in UID safely
    _currentUid = FirebaseAuth.instance.currentUser!.uid;

    // 🔥 Build screens list AFTER UID is available
    _screens = [
      const HomeScreen(),
      const CreatePostScreen(),
      ProfileScreen(uid: _currentUid),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE3),

      body: _screens[_currentIndex],

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE8E2D2),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFFE8E2D2),
          selectedItemColor: const Color(0xFFC56A45),
          unselectedItemColor: const Color(0xFF6C7A4C),
          currentIndex: _currentIndex,
          elevation: 0,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: "Create",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
 */

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

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final String _currentUid;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _currentUid = FirebaseAuth.instance.currentUser!.uid;

    _screens = [
      const HomeScreen(),
      const CreatePostScreen(), // You can change to custom modal later
      ProfileScreen(uid: _currentUid),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE3),

      body: _screens[_currentIndex],

      // Custom Floating Navigation Bar
      bottomNavigationBar: Padding(
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
              _navIcon(icon: Icons.home, index: 0, active: _currentIndex == 0),

              _navIcon(
                icon: Icons.search,
                index: 10,
                isAction: true,
                onTapOverride: () {
                  Navigator.pushNamed(context, "/search");
                },
              ),

              _centerPlusButton(),

              _navIcon(
                icon: Icons.favorite_border,
                index: 11,
                isAction: true,
                onTapOverride: () {
                  // Future Feature: Likes page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Likes coming soon")),
                  );
                },
              ),

              _navIcon(
                icon: Icons.person,
                index: 2,
                active: _currentIndex == 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------
  // SINGLE NAV ICON
  // --------------------------
  Widget _navIcon({
    required IconData icon,
    required int index,
    bool active = false,
    bool isAction = false,
    VoidCallback? onTapOverride,
  }) {
    return GestureDetector(
      onTap:
          onTapOverride ??
          () {
            if (!isAction) {
              setState(() => _currentIndex = index);
            }
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

  // --------------------------
  // CENTER PLUS BUTTON
  // --------------------------
  Widget _centerPlusButton() {
    return GestureDetector(
      onTap: () {
        // Future: open take photo / upload menu
        setState(() => _currentIndex = 1);
      },
      child: Container(
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
}
