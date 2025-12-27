import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ============================================================================
/// NOTIFICATION MODEL
/// ============================================================================
/// Types of notifications:
/// - like: Someone liked your post
/// - reply: Someone replied to your post
/// - quote: Someone quoted your post
/// - repic: Someone repicced your post
/// - follow: Someone followed you
/// - mention: Someone mentioned you
/// - share: Someone shared a post with you
/// ============================================================================
class NotificationModel {
  final String id;
  final String type;
  final String recipientId;
  final String actorId;
  final String actorName;
  final String? actorHandle;
  final String? actorAvatarUrl;
  final bool actorIsVerified;
  final String? postId;
  final String? postThumbnail;
  final String? message;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.recipientId,
    required this.actorId,
    required this.actorName,
    this.actorHandle,
    this.actorAvatarUrl,
    this.actorIsVerified = false,
    this.postId,
    this.postThumbnail,
    this.message,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return NotificationModel(
      id: doc.id,
      type: data['type'] ?? 'unknown',
      recipientId: data['recipientId'] ?? '',
      actorId: data['actorId'] ?? '',
      actorName: data['actorName'] ?? 'User',
      actorHandle: data['actorHandle'],
      actorAvatarUrl: data['actorAvatarUrl'],
      actorIsVerified: data['actorIsVerified'] ?? false,
      postId: data['postId'],
      postThumbnail: data['postThumbnail'],
      message: data['message'],
      createdAt: parseTimestamp(data['createdAt']),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'recipientId': recipientId,
      'actorId': actorId,
      'actorName': actorName,
      'actorHandle': actorHandle,
      'actorAvatarUrl': actorAvatarUrl,
      'actorIsVerified': actorIsVerified,
      'postId': postId,
      'postThumbnail': postThumbnail,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  /// Get notification title based on type
  String get title {
    switch (type) {
      case 'like':
        return '$actorName liked your post';
      case 'reply':
        return '$actorName replied to your post';
      case 'quote':
        return '$actorName quoted your post';
      case 'repic':
        return '$actorName repicced your post';
      case 'follow':
        return '$actorName started following you';
      case 'mention':
        return '$actorName mentioned you';
      case 'share':
        return '$actorName shared a post with you';
      default:
        return 'New notification';
    }
  }

  /// Get icon for notification type
  String get iconName {
    switch (type) {
      case 'like':
        return 'favorite';
      case 'reply':
        return 'chat_bubble';
      case 'quote':
        return 'format_quote';
      case 'repic':
        return 'repeat';
      case 'follow':
        return 'person_add';
      case 'mention':
        return 'alternate_email';
      case 'share':
        return 'send';
      default:
        return 'notifications';
    }
  }
}

/// ============================================================================
/// NOTIFICATION SERVICE
/// ============================================================================
class NotificationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // --------------------------------------------------------------------------
  // GET NOTIFICATIONS
  // --------------------------------------------------------------------------
  Future<List<NotificationModel>> getNotifications({int limit = 50}) async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final snap = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snap.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // WATCH NOTIFICATIONS (Real-time)
  // --------------------------------------------------------------------------
  Stream<List<NotificationModel>> watchNotifications({int limit = 50}) {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // --------------------------------------------------------------------------
  // GET UNREAD COUNT
  // --------------------------------------------------------------------------
  Future<int> getUnreadCount() async {
    final uid = _uid;
    if (uid == null) return 0;

    try {
      final snap = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snap.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }

  // --------------------------------------------------------------------------
  // WATCH UNREAD COUNT (Real-time)
  // --------------------------------------------------------------------------
  Stream<int> watchUnreadCount() {
    final uid = _uid;
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // --------------------------------------------------------------------------
  // MARK AS READ
  // --------------------------------------------------------------------------
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  // --------------------------------------------------------------------------
  // MARK ALL AS READ
  // --------------------------------------------------------------------------
  Future<void> markAllAsRead() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final snap = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      debugPrint('✅ Marked ${snap.docs.length} notifications as read');
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
    }
  }

  // --------------------------------------------------------------------------
  // CREATE NOTIFICATION (Internal use)
  // --------------------------------------------------------------------------
  Future<void> createNotification({
    required String type,
    required String recipientId,
    String? postId,
    String? postThumbnail,
    String? message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Don't notify yourself
    if (recipientId == user.uid) return;

    try {
      // Get actor details
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      await _firestore.collection('notifications').add({
        'type': type,
        'recipientId': recipientId,
        'actorId': user.uid,
        'actorName': userData['displayName'] ?? user.displayName ?? 'User',
        'actorHandle': userData['handle'] ?? userData['username'],
        'actorAvatarUrl': userData['profileImageUrl'] ?? userData['photoUrl'],
        'actorIsVerified': userData['isVerified'] ?? false,
        'postId': postId,
        'postThumbnail': postThumbnail,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      debugPrint('✅ Created $type notification for $recipientId');
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
    }
  }

  // --------------------------------------------------------------------------
  // DELETE OLD NOTIFICATIONS (Cleanup)
  // --------------------------------------------------------------------------
  Future<void> deleteOldNotifications({int daysOld = 30}) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final cutoff = DateTime.now().subtract(Duration(days: daysOld));
      
      final snap = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
          .get();

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('✅ Deleted ${snap.docs.length} old notifications');
    } catch (e) {
      debugPrint('❌ Error deleting old notifications: $e');
    }
  }
}
