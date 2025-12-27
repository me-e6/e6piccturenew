import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Core
import '../feed/day_feed_controller.dart';
import '../feed/day_feed_service.dart';

// Screens
import '../home/home_screen_v3.dart';
import '../search/search_screen.dart';
import '../post/create/create_post_screen.dart';
import '../post/create/media_picker_service.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_entry.dart';

// Controllers
import '../profile/profile_controller.dart';
import '../follow/mutual_controller.dart';
import '../follow/follow_controller.dart';

/// ============================================================================
/// MAIN NAVIGATION - NO DRAWER VERSION
/// ============================================================================
/// 5-tab navigation:
///
/// Tab 0: Home Feed (includes ProfileBottomSheet for settings)
/// Tab 1: Search
/// Tab 2: Create Post (Plus button)
/// Tab 3: Notifications
/// Tab 4: Profile
///
/// Settings are accessed via ProfileBottomSheet in HomeScreenV3
/// ============================================================================
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isPlusExpanded = false;

  final MediaPickerService _mediaPicker = MediaPickerService();
  late final DayFeedController _dayFeedController;

  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotationAnimation;

  // Notification badge count
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _dayFeedController = DayFeedController(DayFeedService())..init();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.125,
    ).animate(_expandAnimation);

    _listenToNotifications();
  }

  void _listenToNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snap) {
          if (mounted) {
            setState(() => _unreadNotifications = snap.docs.length);
          }
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    _dayFeedController.dispose();
    super.dispose();
  }

  void _togglePlus() {
    setState(() {
      _isPlusExpanded = !_isPlusExpanded;
      _isPlusExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  void _closePlus() {
    if (!_isPlusExpanded) return;
    setState(() {
      _isPlusExpanded = false;
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // NO DRAWER - Settings are in ProfileBottomSheet
      body: Stack(
        children: [
          _buildCurrentTab(),

          // Overlay when plus is expanded
          if (_isPlusExpanded)
            GestureDetector(
              onTap: _closePlus,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withOpacity(0.15)),
            ),

          // Bottom navigation
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNavigation(),
          ),

          // Plus expansion menu
          if (_isPlusExpanded)
            Align(
              alignment: Alignment.bottomCenter,
              child: _PlusExpansion(
                animation: _expandAnimation,
                onCamera: _handleCamera,
                onUpload: _handleUpload,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      // ═══════════════════════════════════════════════════════════════════════
      // TAB 0: HOME FEED (contains ProfileBottomSheet for settings)
      // ═══════════════════════════════════════════════════════════════════════
      case 0:
        return ChangeNotifierProvider.value(
          value: _dayFeedController,
          child: const HomeScreenV3(),
        );

      // ═══════════════════════════════════════════════════════════════════════
      // TAB 1: SEARCH
      // ═══════════════════════════════════════════════════════════════════════
      case 1:
        return const SearchScreen();

      // ═══════════════════════════════════════════════════════════════════════
      // TAB 3: NOTIFICATIONS
      // ═══════════════════════════════════════════════════════════════════════
      case 3:
        return const _NotificationsTab();

      // ═══════════════════════════════════════════════════════════════════════
      // TAB 4: PROFILE
      // ═══════════════════════════════════════════════════════════════════════
      case 4:
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return const SizedBox.shrink();

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  ProfileController()..loadProfileData(targetUserId: uid),
            ),
            ChangeNotifierProvider(
              create: (_) => MutualController()..loadMutual(targetUserId: uid),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  FollowController()..loadFollower(targetUserId: uid),
            ),
          ],
          child: ProfileScreen(userId: uid),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNavigation() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                isActive: _currentIndex == 0,
                onTap: () => _onTabTapped(0),
              ),

              // Search
              _NavItem(
                icon: Icons.search,
                activeIcon: Icons.search,
                isActive: _currentIndex == 1,
                onTap: () => _onTabTapped(1),
              ),

              // Plus (Create)
              _PlusButton(
                isExpanded: _isPlusExpanded,
                animation: _rotationAnimation,
                onTap: _togglePlus,
              ),

              // Notifications
              _NavItem(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                isActive: _currentIndex == 3,
                badge: _unreadNotifications > 0 ? _unreadNotifications : null,
                onTap: () => _onTabTapped(3),
              ),

              // Profile
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                isActive: _currentIndex == 4,
                onTap: () => _onTabTapped(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      _togglePlus();
      return;
    }

    _closePlus();
    setState(() => _currentIndex = index);
  }

  Future<void> _handleCamera() async {
    debugPrint('📸 Camera tapped');
    _closePlus();

    try {
      final file = await _mediaPicker.pickImage(source: ImageSource.camera);

      if (file == null) {
        debugPrint('Camera cancelled or failed');
        return;
      }

      if (!mounted) return;

      final xFile = XFile(file.path);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreatePostScreen(files: [xFile])),
      );
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to take photo: $e')));
    }
  }

  Future<void> _handleUpload() async {
    debugPrint('🖼 Upload tapped');
    _closePlus();

    try {
      final files = await _mediaPicker.pickMultipleImages();

      if (files.isEmpty) {
        debugPrint('Gallery picker cancelled or no images selected');
        return;
      }

      if (!mounted) return;

      final xFiles = files.map((file) => XFile(file.path)).toList();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreatePostScreen(files: xFiles)),
      );
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
    }
  }
}

/// ============================================================================
/// NOTIFICATIONS TAB
/// ============================================================================
class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final scheme = Theme.of(context).colorScheme;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(uid),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: scheme.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              final notifId = notifications[index].id;

              return _NotificationTile(
                notificationId: notifId,
                userId: uid,
                type: data['type'] ?? 'unknown',
                fromUserId: data['fromUserId'],
                fromUserName: data['fromUserName'],
                fromUserAvatar: data['fromUserAvatar'],
                isRead: data['read'] ?? false,
                createdAt: data['createdAt'],
              );
            },
          );
        },
      ),
    );
  }

  void _markAllAsRead(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final notifications = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    for (final doc in notifications.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }
}

class _NotificationTile extends StatelessWidget {
  final String notificationId;
  final String userId;
  final String type;
  final String? fromUserId;
  final String? fromUserName;
  final String? fromUserAvatar;
  final bool isRead;
  final dynamic createdAt;

  const _NotificationTile({
    required this.notificationId,
    required this.userId,
    required this.type,
    this.fromUserId,
    this.fromUserName,
    this.fromUserAvatar,
    required this.isRead,
    this.createdAt,
  });

  IconData _getIcon() {
    switch (type) {
      case 'follow':
        return Icons.person_add;
      case 'like':
        return Icons.favorite;
      case 'reply':
        return Icons.chat_bubble;
      case 'repic':
        return Icons.repeat;
      case 'quote':
        return Icons.format_quote;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case 'follow':
        return Colors.blue;
      case 'like':
        return Colors.red;
      case 'repic':
        return Colors.green;
      case 'quote':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getMessage() {
    final name = fromUserName ?? 'Someone';
    switch (type) {
      case 'follow':
        return '$name started following you';
      case 'like':
        return '$name liked your post';
      case 'reply':
        return '$name replied to your post';
      case 'repic':
        return '$name repicced your post';
      case 'quote':
        return '$name quoted your post';
      default:
        return 'New notification';
    }
  }

  String _getTimeAgo() {
    if (createdAt == null) return '';
    DateTime time;
    if (createdAt is Timestamp) {
      time = (createdAt as Timestamp).toDate();
    } else {
      return '';
    }
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      tileColor: isRead ? null : scheme.primaryContainer.withOpacity(0.1),
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: fromUserAvatar != null
                ? NetworkImage(fromUserAvatar!)
                : null,
            child: fromUserAvatar == null ? const Icon(Icons.person) : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(_getIcon(), size: 12, color: _getIconColor()),
            ),
          ),
        ],
      ),
      title: Text(
        _getMessage(),
        style: TextStyle(
          fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: Text(_getTimeAgo()),
      trailing: !isRead
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () async {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .update({'read': true});

        if (type == 'follow' && fromUserId != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileEntry(userId: fromUserId!),
            ),
          );
        }
      },
    );
  }
}

/// ============================================================================
/// NAV ITEM
/// ============================================================================
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 26,
              color: isActive ? scheme.primary : scheme.onSurfaceVariant,
            ),
            if (badge != null && badge! > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge! > 99 ? '99+' : badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// PLUS BUTTON
/// ============================================================================
class _PlusButton extends StatelessWidget {
  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _PlusButton({
    required this.isExpanded,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: RotationTransition(
          turns: animation,
          child: Icon(Icons.add, color: scheme.onPrimary, size: 28),
        ),
      ),
    );
  }
}

/// ============================================================================
/// PLUS EXPANSION
/// ============================================================================
class _PlusExpansion extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onCamera;
  final VoidCallback onUpload;

  const _PlusExpansion({
    required this.animation,
    required this.onCamera,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: ScaleTransition(
        scale: animation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PlusOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: onCamera,
              ),
              const SizedBox(width: 24),
              _PlusOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: onUpload,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlusOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlusOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.primary, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
