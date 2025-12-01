import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/profile_screen.dart';

class SettingsSnapOutScreen extends StatelessWidget {
  const SettingsSnapOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Drawer(
      backgroundColor: const Color(0xFFF5EDE3),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP PROFILE CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage(
                      "assets/profile_placeholder.png",
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Profile",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade800,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(uid: uid),
                              ),
                            );
                          },
                          child: const Text(
                            "View Profile >",
                            style: TextStyle(
                              color: Color(0xFF6C7A4C),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // MENU ITEMS
            _menuItem(context, Icons.settings, "Settings"),
            _menuItem(context, Icons.notifications, "Notifications"),
            _menuItem(context, Icons.lock, "Privacy"),
            _menuItem(context, Icons.people, "Your Connections"),

            const Divider(),

            _menuItem(context, Icons.help, "Help"),
            _menuItem(context, Icons.info, "About"),

            const Divider(),

            _menuItem(context, Icons.logout, "Log Out", isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label, {
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : const Color(0xFF6C7A4C),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isLogout ? Colors.red : const Color(0xFF2F2F2F),
          fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context);

        if (isLogout) {
          FirebaseAuth.instance.signOut();
          Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
        }
      },
    );
  }
}
