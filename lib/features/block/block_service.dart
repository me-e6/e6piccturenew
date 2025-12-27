import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ============================================================================
/// BLOCK SERVICE
/// ============================================================================
/// Handles blocking/unblocking users:
/// - ✅ Block user (bidirectional hide)
/// - ✅ Unblock user
/// - ✅ Check if blocked
/// - ✅ Get blocked users list
/// - ✅ Filter content from blocked users
/// ============================================================================
class BlockService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Cache for quick lookups
  final Map<String, bool> _blockCache = {};
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  BlockService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ===========================================================================
  // BLOCK USER
  // ===========================================================================
  
  /// Block a user
  /// Creates entries in both users' blocked subcollections
  Future<bool> blockUser(String targetUserId) async {
    final uid = _uid;
    if (uid == null || uid == targetUserId) return false;

    try {
      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      // Add to my blocked list
      final myBlockRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('blocked')
          .doc(targetUserId);

      batch.set(myBlockRef, {
        'blockedUserId': targetUserId,
        'blockedAt': now,
      });

      // Add to their blocked_by list (for reverse lookups)
      final theirBlockedByRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('blocked_by')
          .doc(uid);

      batch.set(theirBlockedByRef, {
        'blockedByUserId': uid,
        'blockedAt': now,
      });

      // Also unfollow each other
      final myFollowingRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('following')
          .doc(targetUserId);

      final theirFollowingRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('following')
          .doc(uid);

      batch.delete(myFollowingRef);
      batch.delete(theirFollowingRef);

      // Update follower counts
      final myUserRef = _firestore.collection('users').doc(uid);
      final targetUserRef = _firestore.collection('users').doc(targetUserId);

      // Note: These might fail if not following, but that's ok
      try {
        batch.update(myUserRef, {'followingCount': FieldValue.increment(-1)});
        batch.update(targetUserRef, {'followersCount': FieldValue.increment(-1)});
        batch.update(targetUserRef, {'followingCount': FieldValue.increment(-1)});
        batch.update(myUserRef, {'followersCount': FieldValue.increment(-1)});
      } catch (_) {}

      await batch.commit();

      // Update cache
      _blockCache[targetUserId] = true;

      debugPrint('✅ Blocked user: $targetUserId');
      return true;
    } catch (e) {
      debugPrint('❌ Error blocking user: $e');
      return false;
    }
  }

  // ===========================================================================
  // UNBLOCK USER
  // ===========================================================================
  
  /// Unblock a user
  Future<bool> unblockUser(String targetUserId) async {
    final uid = _uid;
    if (uid == null) return false;

    try {
      final batch = _firestore.batch();

      // Remove from my blocked list
      final myBlockRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('blocked')
          .doc(targetUserId);

      batch.delete(myBlockRef);

      // Remove from their blocked_by list
      final theirBlockedByRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('blocked_by')
          .doc(uid);

      batch.delete(theirBlockedByRef);

      await batch.commit();

      // Update cache
      _blockCache[targetUserId] = false;

      debugPrint('✅ Unblocked user: $targetUserId');
      return true;
    } catch (e) {
      debugPrint('❌ Error unblocking user: $e');
      return false;
    }
  }

  // ===========================================================================
  // CHECK BLOCK STATUS
  // ===========================================================================
  
  /// Check if current user has blocked a specific user
  Future<bool> hasBlocked(String targetUserId) async {
    final uid = _uid;
    if (uid == null) return false;

    // Check cache first
    if (_isCacheValid() && _blockCache.containsKey(targetUserId)) {
      return _blockCache[targetUserId]!;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('blocked')
          .doc(targetUserId)
          .get();

      final isBlocked = doc.exists;
      _blockCache[targetUserId] = isBlocked;

      return isBlocked;
    } catch (e) {
      debugPrint('❌ Error checking block status: $e');
      return false;
    }
  }

  /// Check if current user is blocked by a specific user
  Future<bool> isBlockedBy(String targetUserId) async {
    final uid = _uid;
    if (uid == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('blocked_by')
          .doc(targetUserId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error checking blocked_by status: $e');
      return false;
    }
  }

  /// Check if there's any block relationship (either direction)
  Future<bool> hasBlockRelationship(String targetUserId) async {
    final hasBlockedThem = await hasBlocked(targetUserId);
    if (hasBlockedThem) return true;

    final blockedByThem = await isBlockedBy(targetUserId);
    return blockedByThem;
  }

  // ===========================================================================
  // GET BLOCKED USERS LIST
  // ===========================================================================
  
  /// Get list of users I've blocked
  Future<List<BlockedUser>> getBlockedUsers() async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('blocked')
          .orderBy('blockedAt', descending: true)
          .get();

      final List<BlockedUser> blockedUsers = [];

      for (final doc in snap.docs) {
        final blockedUserId = doc.id;

        // Fetch user details
        final userDoc = await _firestore.collection('users').doc(blockedUserId).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          blockedUsers.add(BlockedUser(
            userId: blockedUserId,
            displayName: userData['displayName'] ?? 'Unknown',
            handle: userData['handle'] ?? userData['username'] ?? blockedUserId,
            avatarUrl: userData['profileImageUrl'] ?? userData['photoUrl'],
            blockedAt: (doc.data()['blockedAt'] as Timestamp?)?.toDate(),
          ));

          // Update cache
          _blockCache[blockedUserId] = true;
        }
      }

      _cacheTime = DateTime.now();
      return blockedUsers;
    } catch (e) {
      debugPrint('❌ Error getting blocked users: $e');
      return [];
    }
  }

  /// Stream of blocked user IDs for real-time filtering
  Stream<Set<String>> watchBlockedUserIds() {
    final uid = _uid;
    if (uid == null) return Stream.value({});

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('blocked')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  // ===========================================================================
  // FILTER CONTENT
  // ===========================================================================
  
  /// Get set of all blocked user IDs (for filtering)
  Future<Set<String>> getBlockedUserIds() async {
    final uid = _uid;
    if (uid == null) return {};

    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('blocked')
          .get();

      return snap.docs.map((d) => d.id).toSet();
    } catch (e) {
      return {};
    }
  }

  /// Get set of users who blocked me (for filtering)
  Future<Set<String>> getBlockedByUserIds() async {
    final uid = _uid;
    if (uid == null) return {};

    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('blocked_by')
          .get();

      return snap.docs.map((d) => d.id).toSet();
    } catch (e) {
      return {};
    }
  }

  /// Get all blocked relationships (both directions)
  Future<Set<String>> getAllBlockedIds() async {
    final blocked = await getBlockedUserIds();
    final blockedBy = await getBlockedByUserIds();
    return blocked.union(blockedBy);
  }

  // ===========================================================================
  // CACHE MANAGEMENT
  // ===========================================================================
  
  bool _isCacheValid() {
    if (_cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheDuration;
  }

  void clearCache() {
    _blockCache.clear();
    _cacheTime = null;
  }
}

/// ============================================================================
/// BLOCKED USER MODEL
/// ============================================================================
class BlockedUser {
  final String userId;
  final String displayName;
  final String handle;
  final String? avatarUrl;
  final DateTime? blockedAt;

  BlockedUser({
    required this.userId,
    required this.displayName,
    required this.handle,
    this.avatarUrl,
    this.blockedAt,
  });
}
