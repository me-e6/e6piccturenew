import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../features/navigation/snapout_controller.dart';
import '../../features/settingsbreadcrumb/settings_controller.dart';
import '../../features/settingsbreadcrumb/settings_snapout_screen.dart';
import '../../features/profile/profile_controller.dart';
import '../../features/profile/user_model.dart';

/// ----------------------------------
/// AppScaffold
/// ----------------------------------
class AppScaffold extends StatefulWidget {
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
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold>
    with TickerProviderStateMixin {
  late final SnapoutController _snapoutController;
  late final SettingsController _settingsController;
  late final ProfileController _profileController;

  bool _showVideoDp = false;

  @override
  void initState() {
    super.initState();
    _snapoutController = SnapoutController()..init(vsync: this);
    _settingsController = SettingsController();
    _profileController = ProfileController();
  }

  @override
  void dispose() {
    _snapoutController.disposeController();
    super.dispose();
  }

  void _openVideoDp() {
    setState(() {
      _showVideoDp = true;
    });
  }

  void _closeVideoDp() {
    setState(() {
      _showVideoDp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _snapoutController),
        ChangeNotifierProvider.value(value: _settingsController),
        ChangeNotifierProvider.value(value: _profileController),
      ],
      child: Scaffold(
        appBar:
            widget.appBar ??
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: _snapoutController.toggleLeft,
              ),
              title: const Text('PICCTURE'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: _snapoutController.toggleRight,
                ),
              ],
            ),
        body: Stack(
          children: [
            widget.body,
            _LeftSnapout(onAvatarTap: _openVideoDp),
            _RightSnapout(),
            if (_showVideoDp)
              _VideoDpOverlay(
                user: _profileController.user,
                onClose: _closeVideoDp,
              ),
          ],
        ),
        bottomNavigationBar: widget.bottomNavigationBar, // ✅ ADD THIS
      ),
    );
  }
}

/// ----------------------------------
/// LEFT SNAPOUT
/// ----------------------------------
class _LeftSnapout extends StatelessWidget {
  final VoidCallback onAvatarTap;

  const _LeftSnapout({required this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final snapout = context.watch<SnapoutController>();
    final profile = context.watch<ProfileController>();

    return AnimatedBuilder(
      animation: snapout.leftAnimation,
      builder: (context, _) {
        return Positioned(
          top: 0,
          bottom: 0,
          left: -300 + (300 * snapout.leftAnimation.value),
          width: 300,
          child: Material(
            elevation: 12,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UserHeader(user: profile.user, onTap: onAvatarTap),
                const Divider(),
                _NavItem('Timeline'),
                _NavItem('Bookmarks'),
                _NavItem('Impact Picctures'),
                _NavItem('Messenger'),
                _NavItem('Piccture Analytics'),
                const Spacer(),
                _NavItem('About', enabled: true),
                _NavItem('Help', enabled: true),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('v0.4.0', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ----------------------------------
/// USER HEADER
/// ----------------------------------
class _UserHeader extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onTap;

  const _UserHeader({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${user?.handle ?? 'handle'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------------
/// VIDEO DP OVERLAY
/// ----------------------------------
class _VideoDpOverlay extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onClose;

  const _VideoDpOverlay({required this.user, required this.onClose});

  @override
  State<_VideoDpOverlay> createState() => _VideoDpOverlayState();
}

class _VideoDpOverlayState extends State<_VideoDpOverlay> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    final videoUrl = widget.user?.videoDpUrl;
    if (videoUrl != null) {
      _controller = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          _controller!
            ..setLooping(false)
            ..play();
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 260,
            height: 360,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _controller != null && _controller!.value.isInitialized
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: VideoPlayer(_controller!),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}

/// ----------------------------------
/// NAV ITEM
/// ----------------------------------
class _NavItem extends StatelessWidget {
  final String title;
  final bool enabled;

  const _NavItem(this.title, {this.enabled = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      enabled: enabled,
      onTap: enabled
          ? () {}
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming in a future update')),
              );
            },
    );
  }
}

/// ----------------------------------
/// RIGHT SNAPOUT — Settings
/// ----------------------------------
class _RightSnapout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapoutController>();

    return AnimatedBuilder(
      animation: controller.rightAnimation,
      builder: (context, _) {
        return Positioned(
          top: 0,
          bottom: 0,
          right: -320 + (320 * controller.rightAnimation.value),
          width: 320,
          child: Material(
            elevation: 12,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const SettingsSnapOutScreen(),
          ),
        );
      },
    );
  }
}
