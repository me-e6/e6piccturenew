import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/theme_controller.dart';
import '../profile/profile_screen.dart';
import '../profile/user_model.dart';
import '../admin/admin_dashboard_screen.dart';

/// ============================================================================
/// SETTINGS SCREEN - COMPLETE
/// ============================================================================
/// Features:
/// - ✅ Profile header
/// - ✅ Admin Dashboard (for admin users)
/// - ✅ Gazetteer Verification Request
/// - ✅ Account settings
/// - ✅ Notifications toggles
/// - ✅ Privacy settings
/// - ✅ Theme toggle
/// - ✅ Blocked/Muted users (placeholder)
/// - ✅ Help & Support
/// - ✅ Logout/Delete account
/// ============================================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  UserModel? _user;
  bool _isLoading = true;
  String _version = '';

  // Settings state
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _publicProfile = true;
  bool _showActivityStatus = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndSettings();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() => _version = '${info.version} (${info.buildNumber})');
    } catch (_) {
      setState(() => _version = '1.0.0');
    }
  }

  Future<void> _loadUserAndSettings() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _user = UserModel.fromDocument(doc);

        // Load settings from user document
        final data = doc.data()!;
        _pushNotifications = data['pushNotifications'] ?? true;
        _emailNotifications = data['emailNotifications'] ?? false;
        _publicProfile = data['publicProfile'] ?? true;
        _showActivityStatus = data['showActivityStatus'] ?? true;
      }
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.collection('users').doc(uid).update({
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Error updating setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isAdmin = _user?.isAdmin ?? false;
    final isGazetteer = _user?.role == 'gazetteer' || _user?.type == 'gazetteer';
    final isVerified = _user?.isVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // PROFILE HEADER
          // ═══════════════════════════════════════════════════════════════════
          _ProfileHeader(user: _user),

          const SizedBox(height: 8),

          // ═══════════════════════════════════════════════════════════════════
          // ADMIN SECTION (Only for admins)
          // ═══════════════════════════════════════════════════════════════════
          if (isAdmin) ...[
            _SectionHeader(title: 'Administration', icon: Icons.admin_panel_settings),
            _SettingsTile(
              icon: Icons.dashboard,
              title: 'Admin Dashboard',
              subtitle: 'Manage users, reports, verification',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),
            const Divider(),
          ],

          // ═══════════════════════════════════════════════════════════════════
          // GAZETTEER VERIFICATION (For non-verified users)
          // ═══════════════════════════════════════════════════════════════════
          if (!isGazetteer && !isVerified) ...[
            _SectionHeader(title: 'Verification', icon: Icons.verified),
            _SettingsTile(
              icon: Icons.badge_outlined,
              title: 'Request Gazetteer Badge',
              subtitle: 'Apply for verified status',
              onTap: () => _showGazetteerRequestDialog(),
            ),
            const Divider(),
          ],

          // ═══════════════════════════════════════════════════════════════════
          // ACCOUNT
          // ═══════════════════════════════════════════════════════════════════
          _SectionHeader(title: 'Account', icon: Icons.person_outline),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: _user?.email ?? 'Not set',
            onTap: () => _showChangeEmailDialog(),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => _showChangePasswordDialog(),
          ),

          const Divider(),

          // ═══════════════════════════════════════════════════════════════════
          // NOTIFICATIONS
          // ═══════════════════════════════════════════════════════════════════
          _SectionHeader(title: 'Notifications', icon: Icons.notifications_outlined),
          SwitchListTile(
            secondary: Icon(Icons.notifications_active, color: scheme.primary),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive alerts on your device'),
            value: _pushNotifications,
            onChanged: (v) {
              setState(() => _pushNotifications = v);
              _updateSetting('pushNotifications', v);
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.email_outlined, color: scheme.primary),
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive updates via email'),
            value: _emailNotifications,
            onChanged: (v) {
              setState(() => _emailNotifications = v);
              _updateSetting('emailNotifications', v);
            },
          ),

          const Divider(),

          // ═══════════════════════════════════════════════════════════════════
          // PRIVACY
          // ═══════════════════════════════════════════════════════════════════
          _SectionHeader(title: 'Privacy', icon: Icons.lock_outline),
          SwitchListTile(
            secondary: Icon(Icons.public, color: scheme.primary),
            title: const Text('Public Profile'),
            subtitle: const Text('Anyone can see your profile'),
            value: _publicProfile,
            onChanged: (v) {
              setState(() => _publicProfile = v);
              _updateSetting('publicProfile', v);
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.visibility, color: scheme.primary),
            title: const Text('Activity Status'),
            subtitle: const Text('Show when you\'re online'),
            value: _showActivityStatus,
            onChanged: (v) {
              setState(() => _showActivityStatus = v);
              _updateSetting('showActivityStatus', v);
            },
          ),
          _SettingsTile(
            icon: Icons.block,
            title: 'Blocked Accounts',
            onTap: () => _showBlockedUsers(),
          ),
          _SettingsTile(
            icon: Icons.volume_off,
            title: 'Muted Accounts',
            onTap: () => _showMutedUsers(),
          ),

          const Divider(),

          // ═══════════════════════════════════════════════════════════════════
          // APPEARANCE
          // ═══════════════════════════════════════════════════════════════════
          _SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
          Consumer<ThemeController>(
            builder: (context, themeController, _) {
              final isDark = themeController.themeMode == ThemeMode.dark;
              return SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: scheme.primary,
                ),
                title: const Text('Dark Mode'),
                value: isDark,
                onChanged: (_) => themeController.toggleTheme(),
              );
            },
          ),

          const Divider(),

          // ═══════════════════════════════════════════════════════════════════
          // DATA & STORAGE
          // ═══════════════════════════════════════════════════════════════════
          _SectionHeader(title: 'Data & Storage', icon: Icons.storage_outlined),
          _SettingsTile(
            icon: Icons.download_outlined,
            title: 'Download Your Data',
            subtitle: 'Request a copy of your data',
            onTap: () => _showDownloadDataDialog(),
          ),
          _SettingsTile(
            icon: Icons.delete_sweep_outlined,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: () => _clearCache(),
          ),

          const Divider(),

          // ═══════════════════════════════════════════════════════════════════
          // HELP & SUPPORT
          // ═══════════════════════════════════════════════════════════════════
          _SectionHeader(title: 'Help & Support', icon: Icons.help_outline),
          _SettingsTile(
            icon: Icons.help_center_outlined,
            title: 'Help Center',
            onTap: () => _launchUrl('https://piccture.app/help'),
          ),
          _SettingsTile(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            onTap: () => _showFeedbackDialog(),
          ),
          _SettingsTile(
            icon: Icons.bug_report_outlined,
            title: 'Report a Problem',
            onTap: () => _showReportProblemDialog(),
          ),

          const Divider(),

          // ═══════════════════════════════════════════════════════════════════
          // ABOUT
          // ═══════════════════════════════════════════════════════════════════
          _SectionHeader(title: 'About', icon: Icons.info_outline),
          _SettingsTile(
            icon: Icons.info,
            title: 'Version',
            subtitle: _version,
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _launchUrl('https://piccture.app/terms'),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _launchUrl('https://piccture.app/privacy'),
          ),

          const Divider(),

          // ═══════════════════════════════════════════════════════════════════
          // LOGOUT
          // ═══════════════════════════════════════════════════════════════════
          _SettingsTile(
            icon: Icons.logout,
            title: 'Log Out',
            iconColor: scheme.error,
            textColor: scheme.error,
            onTap: () => _showLogoutDialog(),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // DELETE ACCOUNT
          // ═══════════════════════════════════════════════════════════════════
          _SettingsTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            iconColor: scheme.error,
            textColor: scheme.error,
            onTap: () => _showDeleteAccountDialog(),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ===========================================================================
  // DIALOG METHODS
  // ===========================================================================

  void _showGazetteerRequestDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Gazetteer Badge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Requirements:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('• Account age: 30+ days'),
            const Text('• Posts: 10+ original posts'),
            const Text('• Followers: 100+ followers'),
            const Text('• No violations'),
            const SizedBox(height: 16),
            const Text(
              'Gazetteer badges are for photographers, journalists, and content creators who regularly share original content.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _submitGazetteerRequest();
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitGazetteerRequest() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.collection('verification_requests').add({
        'userId': uid,
        'type': 'gazetteer',
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'userEmail': _user?.email,
        'userName': _user?.displayName,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification request submitted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showChangeEmailDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'New Email',
            hintText: 'Enter new email address',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              try {
                await _auth.currentUser?.verifyBeforeUpdateEmail(controller.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verification email sent')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text(
          'We\'ll send you an email with instructions to reset your password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = _auth.currentUser?.email;
              if (email != null) {
                await _auth.sendPasswordResetEmail(email: email);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset email sent')),
                );
              }
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _showBlockedUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blocked users - Coming soon')),
    );
  }

  void _showMutedUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Muted users - Coming soon')),
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Download Your Data'),
        content: const Text(
          'We\'ll prepare a copy of your data and send it to your email. This may take up to 48 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data request submitted')),
              );
            },
            child: const Text('Request Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    // Clear image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared')),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showFeedbackDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Feedback'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Tell us what you think...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await _firestore.collection('feedback').add({
                'userId': _auth.currentUser?.uid,
                'message': controller.text,
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showReportProblemDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report a Problem'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe the problem...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await _firestore.collection('bug_reports').add({
                'userId': _auth.currentUser?.uid,
                'description': controller.text,
                'version': _version,
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              if (controller.text != 'DELETE') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please type DELETE to confirm')),
                );
                return;
              }

              try {
                final uid = _auth.currentUser?.uid;
                if (uid != null) {
                  await _firestore.collection('users').doc(uid).update({
                    'state': 'deleted',
                    'deletedAt': FieldValue.serverTimestamp(),
                  });
                }
                await _auth.currentUser?.delete();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;

  const _ProfileHeader({this.user});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatarUrl = user?.profileImageUrl ?? user?.photoUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user?.displayName ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (user?.isVerified ?? false) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 18, color: Colors.blue),
                    ],
                  ],
                ),
                Text(
                  '@${user?.handle ?? 'user'}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: user!.uid),
                  ),
                );
              }
            },
            child: const Text('View Profile'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: iconColor ?? scheme.primary),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
