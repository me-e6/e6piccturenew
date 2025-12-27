import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'profile_controller.dart';

/// ============================================================================
/// EDIT PROFILE SCREEN - FIXED
/// ============================================================================
/// ✅ FIX: Added null check for user before initialization
/// ✅ FIX: Shows loading state if user not yet loaded
/// ============================================================================
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  TextEditingController? _displayNameController;
  TextEditingController? _bioController;

  String? _initialDisplayName;
  String? _initialBio;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final profile = context.read<ProfileController>();
    
    // ✅ FIX: Check if user is null before accessing
    if (profile.user == null) {
      debugPrint('⚠️ EditProfileScreen: User not loaded yet');
      return;
    }

    final user = profile.user!;

    _initialDisplayName = user.displayName;
    _initialBio = user.bio;

    _displayNameController = TextEditingController(text: user.displayName)
      ..addListener(_onChanged);

    _bioController = TextEditingController(text: user.bio)
      ..addListener(_onChanged);

    _initialized = true;
  }

  void _onChanged() {
    setState(() {});
  }

  bool _hasChanges(ProfileController profile) {
    if (_displayNameController == null || _bioController == null) return false;
    
    return _displayNameController!.text.trim() != _initialDisplayName ||
        _bioController!.text.trim() != _initialBio;
  }

  @override
  void dispose() {
    _displayNameController?.dispose();
    _bioController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final scheme = Theme.of(context).colorScheme;

    // ✅ FIX: Show loading if user is null
    if (profile.user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ✅ FIX: Initialize controllers if not already done (user just loaded)
    if (!_initialized) {
      // Trigger rebuild on next frame to initialize controllers
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = profile.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _hasChanges(profile)
                ? () async {
                    await profile.saveProfile(
                      context: context,
                      displayName: _displayNameController!.text.trim(),
                      bio: _bioController!.text.trim(),
                    );

                    if (!mounted) return;
                    Navigator.pop(context);
                  }
                : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: _hasChanges(profile) 
                    ? scheme.primary 
                    : scheme.onSurfaceVariant.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════════════════════════
            // BANNER
            // ═══════════════════════════════════════════════════════════════
            GestureDetector(
              onTap: profile.isUpdatingBanner
                  ? null
                  : () => profile.updateBanner(context),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  image: user.profileBannerUrl != null
                      ? DecorationImage(
                          image: NetworkImage(user.profileBannerUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profile.isUpdatingBanner
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : user.profileBannerUrl == null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 32,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add Banner',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
              ),
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // PROFILE PHOTO (overlapping banner)
            // ═══════════════════════════════════════════════════════════════
            Center(
              child: GestureDetector(
                onTap: profile.isUpdatingPhoto
                    ? null
                    : () => profile.updatePhoto(context),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: scheme.surfaceContainerHighest,
                      backgroundImage: user.profileImageUrl != null
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      child: user.profileImageUrl == null
                          ? Icon(Icons.person, size: 40, color: scheme.onSurfaceVariant)
                          : null,
                    ),
                    if (profile.isUpdatingPhoto)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ═══════════════════════════════════════════════════════════════
            // DISPLAY NAME
            // ═══════════════════════════════════════════════════════════════
            Text(
              'Display Name',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _displayNameController,
              maxLength: 30,
              decoration: InputDecoration(
                hintText: 'Enter your display name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),

            const SizedBox(height: 16),

            // ═══════════════════════════════════════════════════════════════
            // BIO
            // ═══════════════════════════════════════════════════════════════
            Text(
              'Bio',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Max 20 words',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 120,
              decoration: InputDecoration(
                hintText: 'Tell people about yourself',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withOpacity(0.3),
              ),
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // HANDLE (Read-only)
            // ═══════════════════════════════════════════════════════════════
            Text(
              'Handle',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              enabled: false,
              controller: TextEditingController(text: '@${user.handle}'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withOpacity(0.2),
                helperText: 'Handles cannot be changed',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
