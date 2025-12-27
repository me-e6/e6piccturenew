import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/profile/profile_controller.dart';
import '../../features/settingsbreadcrumb/settings_snapout_screen.dart';
import '../../features/profile/user_model.dart';

/// ----------------------------------
/// AppScaffold (CANONICAL)
/// ----------------------------------
/// Responsibilities:
/// - AppBar
/// - Left Drawer (Main Navigation)
/// - Right Drawer (Settings)
/// - Body (pure content)
/// - Bottom Navigation Bar (optional)
///
/// ❌ No Stack
/// ❌ No Positioned
/// ❌ No custom snapout animation
///
/// ✅ Uses Scaffold.drawer / endDrawer
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      // --------------------------------------------------
      // APP BAR
      // --------------------------------------------------
      appBar:
          appBar ??
          AppBar(
            title: const Text('PICCTURE'),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
          ),

      // --------------------------------------------------
      // LEFT DRAWER — MAIN MENU
      // --------------------------------------------------
      //drawer: const _LeftDrawer(),

      // --------------------------------------------------
      // RIGHT DRAWER — SETTINGS
      // --------------------------------------------------
      //  endDrawer: const SettingsSnapOutScreen(),

      // --------------------------------------------------
      // BODY (PURE CONTENT ONLY)
      // --------------------------------------------------
      body: SafeArea(bottom: false, child: body),

      // --------------------------------------------------
      // BOTTOM NAV (FLOATING SAFE)
      // --------------------------------------------------
      bottomNavigationBar: bottomNavigationBar,

      backgroundColor: scheme.surface,
    );
  }
}

/// ----------------------------------
/// LEFT DRAWER (MAIN NAVIGATION)
/// ----------------------------------
class _LeftDrawer extends StatelessWidget {
  const _LeftDrawer();

  @override
  Widget build(BuildContext context) {
    final profileController = context.watch<ProfileController>();
    final user = profileController.user;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Drawer(
      backgroundColor: scheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // USER HEADER
            // --------------------------------------------------
            _UserHeader(user: user),

            const Divider(),

            _NavItem(title: 'Timeline', icon: Icons.home),
            _NavItem(title: 'Bookmarks', icon: Icons.bookmark_border),
            _NavItem(title: 'Impact Picctures', icon: Icons.rocket_launch),
            _NavItem(title: 'Messenger', icon: Icons.chat_bubble_outline),
            _NavItem(title: 'Piccture Analytics', icon: Icons.bar_chart),

            const Spacer(),

            _NavItem(title: 'About', icon: Icons.info, enabled: true),
            _NavItem(title: 'Help', icon: Icons.help_outline, enabled: true),

            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('v0.4.0', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------------
/// USER HEADER
/// ----------------------------------
class _UserHeader extends StatelessWidget {
  final UserModel? user;

  const _UserHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: user?.profileImageUrl != null
                ? NetworkImage(user!.profileImageUrl!)
                : null,
            child: user?.profileImageUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.username ?? 'User',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@${user?.handle ?? 'handle'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------
/// NAV ITEM
/// ----------------------------------
class _NavItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool enabled;

  const _NavItem({
    required this.title,
    required this.icon,
    this.enabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      enabled: enabled,
      onTap: () {
        Navigator.pop(context);

        if (!enabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming in a future update')),
          );
        }
      },
    );
  }
}
