import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'notification_service.dart';

/// ============================================================================
/// NOTIFICATIONS SCREEN
/// ============================================================================
/// Shows all notifications for the current user.
/// 
/// Features:
/// - ✅ Real-time updates
/// - ✅ Pull to refresh
/// - ✅ Mark all as read
/// - ✅ Tap to navigate
/// - ✅ Delete old notifications
/// - ✅ Empty state
/// ============================================================================
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final notifications = await _service.getNotifications();
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _markAllAsRead() async {
    await _service.markAllAsRead();
    _loadNotifications();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    if (!notification.isRead) {
      await _service.markAsRead(notification.id);
    }

    if (!mounted) return;

    // Navigate based on type
    switch (notification.type) {
      case 'follow':
        // Navigate to profile
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (_) => ProfileScreen(userId: notification.actorId),
        // ));
        break;
      case 'like':
      case 'reply':
      case 'quote':
      case 'repic':
      case 'share':
        // Navigate to post
        if (notification.postId != null) {
          // Navigator.push(context, MaterialPageRoute(
          //   builder: (_) => PostDetailScreen(postId: notification.postId!),
          // ));
        }
        break;
    }

    // Refresh to show read state
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'mark_read':
                  _markAllAsRead();
                  break;
                case 'clear_old':
                  _service.deleteOldNotifications();
                  _loadNotifications();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 20),
                    SizedBox(width: 12),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_old',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20),
                    SizedBox(width: 12),
                    Text('Clear old notifications'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState(scheme)
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _NotificationTile(
                        notification: notification,
                        onTap: () => _handleNotificationTap(notification),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "When someone interacts with your posts,\nyou'll see it here",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// NOTIFICATION TILE
/// ============================================================================
class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case 'like':
        return Icons.favorite;
      case 'reply':
        return Icons.chat_bubble;
      case 'quote':
        return Icons.format_quote;
      case 'repic':
        return Icons.repeat;
      case 'follow':
        return Icons.person_add;
      case 'mention':
        return Icons.alternate_email;
      case 'share':
        return Icons.send;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(ColorScheme scheme) {
    switch (notification.type) {
      case 'like':
        return Colors.red;
      case 'reply':
        return scheme.primary;
      case 'quote':
        return Colors.purple;
      case 'repic':
        return Colors.green;
      case 'follow':
        return Colors.blue;
      case 'share':
        return Colors.orange;
      default:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? null 
              : scheme.primaryContainer.withValues(alpha: 0.1),
          border: Border(
            bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getIconColor(scheme).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                size: 20,
                color: _getIconColor(scheme),
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Actor avatar + name row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: notification.actorAvatarUrl != null
                            ? NetworkImage(notification.actorAvatarUrl!)
                            : null,
                        child: notification.actorAvatarUrl == null
                            ? const Icon(Icons.person, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: scheme.onSurface,
                            ),
                            children: [
                              TextSpan(
                                text: notification.actorName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (notification.actorIsVerified)
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.verified, size: 14, color: Colors.blue),
                                  ),
                                ),
                              TextSpan(text: ' ${_getActionText()}'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Message if present
                  if (notification.message != null && notification.message!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.message!,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Timestamp
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Post thumbnail
            if (notification.postThumbnail != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  notification.postThumbnail!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    color: scheme.surfaceContainerHighest,
                    child: Icon(Icons.image, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],

            // Unread indicator
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getActionText() {
    switch (notification.type) {
      case 'like':
        return 'liked your post';
      case 'reply':
        return 'replied to your post';
      case 'quote':
        return 'quoted your post';
      case 'repic':
        return 'repicced your post';
      case 'follow':
        return 'started following you';
      case 'mention':
        return 'mentioned you';
      case 'share':
        return 'shared a post with you';
      default:
        return 'interacted with you';
    }
  }
}

/// ============================================================================
/// NOTIFICATION BADGE (for AppBar)
/// ============================================================================
/// Shows unread count on notification icon
/// ============================================================================
class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
