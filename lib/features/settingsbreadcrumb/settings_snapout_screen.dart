// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/theme_controller.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_controller.dart';
import '../follow/mutual_controller.dart';
import '../follow/follow_controller.dart';
import 'settings_services.dart';

/// ============================================================================
/// SETTINGS SNAPOUT SCREEN - v2 (Enhanced Menu)
/// ============================================================================
/// Full settings drawer with all menu options.
/// 
/// Features:
/// - ✅ Profile header with avatar
/// - ✅ Settings (Under Construction)
/// - ✅ Privacy (Reset Password option)
/// - ✅ Delete Profile (Under Construction)
/// - ✅ About Us (Under Construction)
/// - ✅ Request Gazetteer Role (Under Construction)
/// - ✅ Version display
/// - ✅ Day/Night toggle
/// - ✅ Logout
/// ============================================================================
class SettingsSnapOutScreen extends StatelessWidget {
  const SettingsSnapOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final user = FirebaseAuth.instance.currentUser;
    final settingsService = SettingsService();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Drawer(
      backgroundColor: scheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ══════════════════════════════════════════════════════════════════
            // PROFILE HEADER
            // ══════════════════════════════════════════════════════════════════
            _ProfileHeader(uid: uid, email: user?.email),

            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ══════════════════════════════════════════════════════════════
                    // MAIN MENU ITEMS
                    // ══════════════════════════════════════════════════════════════
                    _MenuItem(
                      icon: Icons.settings,
                      label: "Settings",
                      onTap: () => _showUnderConstruction(context, 'Settings'),
                    ),
                    _MenuItem(
                      icon: Icons.notifications,
                      label: "Notifications",
                      onTap: () => _showUnderConstruction(context, 'Notifications'),
                    ),
                    _MenuItem(
                      icon: Icons.lock,
                      label: "Privacy",
                      onTap: () => _showPrivacyOptions(context),
                    ),
                    _MenuItem(
                      icon: Icons.people,
                      label: "Your Connections",
                      onTap: () => _showUnderConstruction(context, 'Connections'),
                    ),

                    Divider(color: scheme.outlineVariant, height: 24),

                    // ══════════════════════════════════════════════════════════════
                    // GAZETTEER SECTION
                    // ══════════════════════════════════════════════════════════════
                    _MenuItem(
                      icon: Icons.verified,
                      label: "Request Gazetteer Role",
                      subtitle: "Get verified as a Gazetteer",
                      iconColor: Colors.blue,
                      onTap: () => _showGazetteerRequest(context),
                    ),

                    Divider(color: scheme.outlineVariant, height: 24),

                    // ══════════════════════════════════════════════════════════════
                    // INFO SECTION
                    // ══════════════════════════════════════════════════════════════
                    _MenuItem(
                      icon: Icons.help_outline,
                      label: "Help",
                      onTap: () => _showUnderConstruction(context, 'Help'),
                    ),
                    _MenuItem(
                      icon: Icons.info_outline,
                      label: "About Us",
                      onTap: () => _showAboutUs(context),
                    ),

                    Divider(color: scheme.outlineVariant, height: 24),

                    // ══════════════════════════════════════════════════════════════
                    // DAY / NIGHT TOGGLE
                    // ══════════════════════════════════════════════════════════════
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
                            onChanged: (_) => themeController.toggleTheme(),
                          ),
                        );
                      },
                    ),

                    Divider(color: scheme.outlineVariant, height: 24),

                    // ══════════════════════════════════════════════════════════════
                    // DANGER ZONE
                    // ══════════════════════════════════════════════════════════════
                    _MenuItem(
                      icon: Icons.delete_forever,
                      label: "Delete Account",
                      iconColor: scheme.error,
                      textColor: scheme.error,
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ],
                ),
              ),
            ),

            // ══════════════════════════════════════════════════════════════════
            // FOOTER: VERSION & LOGOUT
            // ══════════════════════════════════════════════════════════════════
            Divider(color: scheme.outlineVariant),

            // Version info
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '...';
                final buildNumber = snapshot.data?.buildNumber ?? '';
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Piccture v$version ($buildNumber)',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                );
              },
            ),

            // Logout
            _MenuItem(
              icon: Icons.logout,
              label: "Log Out",
              iconColor: scheme.error,
              textColor: scheme.error,
              onTap: () async {
                Navigator.pop(context); // close drawer
                await settingsService.logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/login",
                  (_) => false,
                );
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DIALOGS & ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  void _showUnderConstruction(BuildContext context, String feature) {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.construction, size: 48, color: scheme.primary),
        title: Text('$feature'),
        content: const Text(
          'This feature is under construction and will be available soon!',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyOptions(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Privacy Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              // Reset Password
              ListTile(
                leading: Icon(Icons.key, color: scheme.primary),
                title: const Text('Reset Password'),
                subtitle: const Text('Send password reset email'),
                onTap: () {
                  Navigator.pop(ctx);
                  _sendPasswordResetEmail(context);
                },
              ),

              // Other privacy options (under construction)
              ListTile(
                leading: Icon(Icons.visibility_off, color: scheme.onSurfaceVariant),
                title: const Text('Account Privacy'),
                subtitle: const Text('Coming soon'),
                enabled: false,
              ),

              ListTile(
                leading: Icon(Icons.block, color: scheme.onSurfaceVariant),
                title: const Text('Blocked Accounts'),
                subtitle: const Text('Coming soon'),
                enabled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendPasswordResetEmail(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email associated with this account'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to ${user.email}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showGazetteerRequest(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.verified, size: 48, color: Colors.blue),
        title: const Text('Request Gazetteer Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gazetteers are verified content creators who help maintain quality on Piccture.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Requirements:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• Active account for 30+ days'),
                  Text('• 10+ quality posts'),
                  Text('• 50+ followers'),
                  Text('• No policy violations'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showUnderConstruction(context, 'Gazetteer Request');
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showAboutUs(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.camera_alt, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            const Text('Piccture'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A photo-first social platform for sharing moments with your community.',
            ),
            const SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            const Text('• Share photos with Mutuals'),
            const Text('• Quote & Repic posts'),
            const Text('• Gazetteer verification'),
            const Text('• Day/Night themes'),
            const SizedBox(height: 16),
            Text(
              '© 2024 Piccture. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.warning, size: 48, color: scheme.error),
        title: const Text('Delete Account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action is permanent and cannot be undone.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This will delete:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• All your posts and photos'),
                  Text('• All your followers/following'),
                  Text('• All your likes and saves'),
                  Text('• Your profile permanently'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showUnderConstruction(context, 'Account Deletion');
            },
            child: Text(
              'Delete',
              style: TextStyle(color: scheme.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// PROFILE HEADER WIDGET
/// ============================================================================
class _ProfileHeader extends StatelessWidget {
  final String uid;
  final String? email;

  const _ProfileHeader({required this.uid, this.email});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.person, size: 28, color: scheme.primary),
          ),
          const SizedBox(width: 14),

          // Info
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
                if (email != null)
                  Text(
                    email!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiProvider(
                          providers: [
                            ChangeNotifierProvider(
                              create: (_) => ProfileController()
                                ..loadProfileData(targetUserId: uid),
                            ),
                            ChangeNotifierProvider(
                              create: (_) => MutualController()
                                ..loadMutual(targetUserId: uid),
                            ),
                            ChangeNotifierProvider(
                              create: (_) => FollowController()
                                ..loadFollower(targetUserId: uid),
                            ),
                          ],
                          child: ProfileScreen(userId: uid),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    "View Profile →",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
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
}

/// ============================================================================
/// MENU ITEM WIDGET
/// ============================================================================
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.iconColor,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: iconColor ?? scheme.primary),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: textColor ?? scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: scheme.onSurfaceVariant.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }
}
