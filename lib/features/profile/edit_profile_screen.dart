import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;

  late String _initialDisplayName;
  late String _initialBio;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final profile = context.read<ProfileController>();
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
    setState(() {}); // 🔥 THIS WAS MISSING
  }

  bool _hasChanges(ProfileController profile) {
    return _displayNameController.text.trim() != _initialDisplayName ||
        _bioController.text.trim() != _initialBio;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
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
                      displayName: _displayNameController.text.trim(),
                      bio: _bioController.text.trim(),
                    );

                    if (!mounted) return;
                    Navigator.pop(context);
                  }
                : null,

            /* onPressed: _hasChanges()
                ? () async {
                    await profile.saveProfile(
                      context: context,
                      displayName: _displayNameController.text.trim(),
                      bio: _bioController.text.trim(),
                    );

                    if (mounted) Navigator.pop(context);
                  }
                : null, */
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// BANNER
            GestureDetector(
              onTap: profile.isUpdatingBanner
                  ? null
                  : () => profile.updateBanner(context),

              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  image: user.profileBannerUrl != null
                      ? DecorationImage(
                          image: NetworkImage(user.profileBannerUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profile.isUpdatingBanner
                    ? const Center(child: CircularProgressIndicator())
                    : user.profileBannerUrl == null
                    ? const Center(child: Icon(Icons.add_photo_alternate))
                    : null,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Display Name',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _displayNameController,
              maxLength: 30,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 16),

            const Text(
              'Bio (max 20 words)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 120,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }
}
