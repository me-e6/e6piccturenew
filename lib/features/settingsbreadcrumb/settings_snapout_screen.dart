// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../profile/profile_screen.dart';
import 'settings_services.dart';
import '../../core/theme/theme_controller.dart';

class SettingsSnapOutScreen extends StatelessWidget {
  const SettingsSnapOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final settingsService = SettingsService();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Drawer(
      backgroundColor: scheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // PROFILE HEADER
            // --------------------------------------------------
            _profileHeader(context, uid),

            const SizedBox(height: 8),

            _menuItem(context, Icons.settings, "Settings"),
            _menuItem(context, Icons.notifications, "Notifications"),
            _menuItem(context, Icons.lock, "Privacy"),
            _menuItem(context, Icons.people, "Your Connections"),

            Divider(color: scheme.outlineVariant),

            _menuItem(context, Icons.help, "Help"),
            _menuItem(context, Icons.info, "About"),

            Divider(color: scheme.outlineVariant),

            // --------------------------------------------------
            // DAY / NIGHT TOGGLE (SIMPLE, DIRECT UX)
            // --------------------------------------------------
            Consumer<ThemeController>(
              builder: (context, themeController, _) {
                final isDark = themeController.themeMode == ThemeMode.dark;

                return ListTile(
                  leading: Icon(
                    isDark ? Icons.nightlight_round : Icons.wb_sunny,
                    color: scheme.primary,
                  ),
                  title: Text(
                    "Day / Night",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Switch(
                    value: isDark,
                    focusColor: scheme.primary,
                    onChanged: (_) {
                      themeController.toggleTheme();
                    },
                  ),
                );
              },
            ),

            // --------------------------------------------------
            // LOGOUT
            // --------------------------------------------------
            _menuItem(
              context,
              Icons.logout,
              "Log Out",
              isLogout: true,
              onLogout: () async {
                Navigator.pop(context);
                await settingsService.logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/login",
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // PROFILE HEADER
  // --------------------------------------------------
  Widget _profileHeader(BuildContext context, String uid) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundImage: AssetImage("assets/profile_placeholder.png"),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Profile",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
                  child: Text(
                    "View Profile >",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // MENU ITEM BUILDER (THEME SAFE)
  // --------------------------------------------------
  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label, {
    bool isLogout = false,
    Future<void> Function()? onLogout,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: isLogout ? scheme.error : scheme.primary),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isLogout ? scheme.error : scheme.onSurface,
          fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () async {
        if (isLogout && onLogout != null) {
          await onLogout();
        } else {
          Navigator.pop(context);
        }
      },
    );
  }
}
