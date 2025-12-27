import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_entry.dart';

/// ============================================================================
/// SETTINGS DRAWER - COMPLETE WITH ALL FEATURES
/// ============================================================================
/// Used as: Scaffold.endDrawer
///
/// Features:
/// - ✅ Profile header with View Profile
/// - ✅ Admin Dashboard (for admins only)
/// - ✅ Gazetteer Request (for non-verified users)
/// - ✅ Settings sections
/// - ✅ Dark mode toggle
/// - ✅ Blocked/Muted users access
/// - ✅ Logout
/// ============================================================================
class SettingsSnapOutScreen extends StatelessWidget {
  const SettingsSnapOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Drawer(
      backgroundColor: scheme.surface,
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            final isAdmin = userData['isAdmin'] ?? false;
            final isVerified = userData['isVerified'] ?? false;
            final role = userData['role'] ?? 'citizen';
            final displayName = userData['displayName'] ?? 'User';
            final handle = userData['handle'] ?? userData['username'] ?? '';
            final avatarUrl = userData['profileImageUrl'] ?? userData['photoUrl'];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ══════════════════════════════════════════════════════════════
                // PROFILE HEADER
                // ══════════════════════════════════════════════════════════════
                _ProfileHeader(
                  uid: uid,
                  displayName: displayName,
                  handle: handle,
                  avatarUrl: avatarUrl,
                  isVerified: isVerified,
                ),

                const SizedBox(height: 8),

                // ══════════════════════════════════════════════════════════════
                // ADMIN SECTION (Admins only)
                // ══════════════════════════════════════════════════════════════
                if (isAdmin) ...[
                  _SectionTitle(title: 'Administration'),
                  _MenuItem(
                    icon: Icons.admin_panel_settings,
                    label: 'Admin Dashboard',
                    iconColor: Colors.deepPurple,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/admin');
                    },
                  ),
                  const Divider(),
                ],

                // ══════════════════════════════════════════════════════════════
                // GAZETTEER REQUEST (Non-verified users only)
                // ══════════════════════════════════════════════════════════════
                if (!isVerified && role != 'gazetteer') ...[
                  _MenuItem(
                    icon: Icons.verified_outlined,
                    label: 'Request Verification',
                    iconColor: Colors.blue,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showVerificationDialog(context, uid, displayName);
                    },
                  ),
                  const Divider(),
                ],

                // ══════════════════════════════════════════════════════════════
                // MAIN MENU
                // ══════════════════════════════════════════════════════════════
                _MenuItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to full settings screen if exists
                    // Navigator.pushNamed(context, '/settings');
                  },
                ),
                _MenuItem(
                  icon: Icons.notifications,
                  label: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to notification settings
                  },
                ),
                _MenuItem(
                  icon: Icons.lock,
                  label: 'Privacy',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),

                const Divider(),

                // ══════════════════════════════════════════════════════════════
                // BLOCKED / MUTED
                // ══════════════════════════════════════════════════════════════
                _MenuItem(
                  icon: Icons.block,
                  label: 'Blocked Accounts',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/blocked');
                  },
                ),
                _MenuItem(
                  icon: Icons.volume_off,
                  label: 'Muted Accounts',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/muted');
                  },
                ),

                const Divider(),

                // ══════════════════════════════════════════════════════════════
                // DAY / NIGHT TOGGLE
                // ══════════════════════════════════════════════════════════════
                Consumer<ThemeController>(
                  builder: (context, themeController, _) {
                    final isDark = themeController.themeMode == ThemeMode.dark;

                    return ListTile(
                      leading: Icon(
                        isDark ? Icons.nightlight_round : Icons.wb_sunny,
                        color: isDark ? Colors.indigo : Colors.orange,
                      ),
                      title: Text(
                        isDark ? 'Dark Mode' : 'Light Mode',
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

                const Divider(),

                // ══════════════════════════════════════════════════════════════
                // HELP & SUPPORT
                // ══════════════════════════════════════════════════════════════
                _MenuItem(
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  onTap: () => Navigator.pop(context),
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  label: 'About',
                  onTap: () => Navigator.pop(context),
                ),

                const Spacer(),

                // ══════════════════════════════════════════════════════════════
                // LOGOUT
                // ══════════════════════════════════════════════════════════════
                _MenuItem(
                  icon: Icons.logout,
                  label: 'Log Out',
                  iconColor: scheme.error,
                  textColor: scheme.error,
                  onTap: () async {
                    Navigator.pop(context);
                    await _showLogoutDialog(context);
                  },
                ),

                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showVerificationDialog(BuildContext context, String uid, String displayName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Request Verification'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gazetteer badges are for:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Photographers & content creators'),
            const Text('• Journalists & reporters'),
            const Text('• Notable public figures'),
            const SizedBox(height: 16),
            const Text(
              'Requirements:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• 30+ days account age'),
            const Text('• 10+ original posts'),
            const Text('• 100+ followers'),
            const Text('• Clean record (no violations)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Submit Request'),
            onPressed: () async {
              Navigator.pop(ctx);
              await _submitVerificationRequest(context, uid, displayName);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitVerificationRequest(
    BuildContext context,
    String uid,
    String displayName,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('verification_requests').add({
        'userId': uid,
        'userName': displayName,
        'type': 'gazetteer',
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Verification request submitted!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _ProfileHeader extends StatelessWidget {
  final String uid;
  final String displayName;
  final String handle;
  final String? avatarUrl;
  final bool isVerified;

  const _ProfileHeader({
    required this.uid,
    required this.displayName,
    required this.handle,
    this.avatarUrl,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl == null || avatarUrl!.isEmpty
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          
          // Name & Handle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 16, color: Colors.blue),
                    ],
                  ],
                ),
                Text(
                  '@$handle',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // View Profile
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileEntry(userId: uid),
                ),
              );
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.iconColor,
    this.textColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: iconColor ?? scheme.primary),
      title: Text(
        label,
        style: TextStyle(
          color: textColor ?? scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
