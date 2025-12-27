import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ============================================================================
/// MUTE SERVICE
/// ============================================================================
/// Handles muting/unmuting users:
/// - ✅ Mute user (hide their posts from feed)
/// - ✅ Unmute user
/// - ✅ Check if muted
/// - ✅ Get muted users list
/// - ✅ Filter content from muted users
///
/// Note: Unlike blocking, muting is one-way and private.
/// The muted user doesn't know they're muted.
/// ============================================================================
class MuteService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Cache for quick lookups
  final Map<String, bool> _muteCache = {};
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  MuteService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ===========================================================================
  // MUTE USER
  // ===========================================================================
  
  /// Mute a user (hide their posts from your feed)
  Future<bool> muteUser(String targetUserId) async {
    final uid = _uid;
    if (uid == null || uid == targetUserId) return false;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('muted')
          .doc(targetUserId)
          .set({
        'mutedUserId': targetUserId,
        'mutedAt': FieldValue.serverTimestamp(),
      });

      // Update cache
      _muteCache[targetUserId] = true;

      debugPrint('✅ Muted user: $targetUserId');
      return true;
    } catch (e) {
      debugPrint('❌ Error muting user: $e');
      return false;
    }
  }

  // ===========================================================================
  // UNMUTE USER
  // ===========================================================================
  
  /// Unmute a user
  Future<bool> unmuteUser(String targetUserId) async {
    final uid = _uid;
    if (uid == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('muted')
          .doc(targetUserId)
          .delete();

      // Update cache
      _muteCache[targetUserId] = false;

      debugPrint('✅ Unmuted user: $targetUserId');
      return true;
    } catch (e) {
      debugPrint('❌ Error unmuting user: $e');
      return false;
    }
  }

  // ===========================================================================
  // CHECK MUTE STATUS
  // ===========================================================================
  
  /// Check if current user has muted a specific user
  Future<bool> hasMuted(String targetUserId) async {
    final uid = _uid;
    if (uid == null) return false;

    // Check cache first
    if (_isCacheValid() && _muteCache.containsKey(targetUserId)) {
      return _muteCache[targetUserId]!;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('muted')
          .doc(targetUserId)
          .get();

      final isMuted = doc.exists;
      _muteCache[targetUserId] = isMuted;

      return isMuted;
    } catch (e) {
      debugPrint('❌ Error checking mute status: $e');
      return false;
    }
  }

  // ===========================================================================
  // GET MUTED USERS LIST
  // ===========================================================================
  
  /// Get list of users I've muted
  Future<List<MutedUser>> getMutedUsers() async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('muted')
          .orderBy('mutedAt', descending: true)
          .get();

      final List<MutedUser> mutedUsers = [];

      for (final doc in snap.docs) {
        final mutedUserId = doc.id;

        // Fetch user details
        final userDoc = await _firestore.collection('users').doc(mutedUserId).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          mutedUsers.add(MutedUser(
            userId: mutedUserId,
            displayName: userData['displayName'] ?? 'Unknown',
            handle: userData['handle'] ?? userData['username'] ?? mutedUserId,
            avatarUrl: userData['profileImageUrl'] ?? userData['photoUrl'],
            mutedAt: (doc.data()['mutedAt'] as Timestamp?)?.toDate(),
          ));

          // Update cache
          _muteCache[mutedUserId] = true;
        }
      }

      _cacheTime = DateTime.now();
      return mutedUsers;
    } catch (e) {
      debugPrint('❌ Error getting muted users: $e');
      return [];
    }
  }

  /// Stream of muted user IDs for real-time filtering
  Stream<Set<String>> watchMutedUserIds() {
    final uid = _uid;
    if (uid == null) return Stream.value({});

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('muted')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  // ===========================================================================
  // FILTER CONTENT
  // ===========================================================================
  
  /// Get set of all muted user IDs (for filtering)
  Future<Set<String>> getMutedUserIds() async {
    final uid = _uid;
    if (uid == null) return {};

    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('muted')
          .get();

      return snap.docs.map((d) => d.id).toSet();
    } catch (e) {
      return {};
    }
  }

  // ===========================================================================
  // CACHE MANAGEMENT
  // ===========================================================================
  
  bool _isCacheValid() {
    if (_cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheDuration;
  }

  void clearCache() {
    _muteCache.clear();
    _cacheTime = null;
  }
}

/// ============================================================================
/// MUTED USER MODEL
/// ============================================================================
class MutedUser {
  final String userId;
  final String displayName;
  final String handle;
  final String? avatarUrl;
  final DateTime? mutedAt;

  MutedUser({
    required this.userId,
    required this.displayName,
    required this.handle,
    this.avatarUrl,
    this.mutedAt,
  });
}

/// ============================================================================
/// CONTENT FILTER SERVICE
/// ============================================================================
/// Combines block and mute filters for feed filtering
/// ============================================================================
class ContentFilterService {
  final MuteService _muteService;
  
  // Block service reference would be injected
  // final BlockService _blockService;

  ContentFilterService({
    MuteService? muteService,
    // BlockService? blockService,
  }) : _muteService = muteService ?? MuteService();
        // _blockService = blockService ?? BlockService();

  /// Get all user IDs that should be filtered from feed
  Future<Set<String>> getFilteredUserIds() async {
    final muted = await _muteService.getMutedUserIds();
    // final blocked = await _blockService.getAllBlockedIds();
    // return muted.union(blocked);
    return muted;
  }

  /// Filter a list of posts, removing those from filtered users
  Future<List<T>> filterPosts<T>(
    List<T> posts,
    String Function(T) getAuthorId,
  ) async {
    final filteredIds = await getFilteredUserIds();
    
    if (filteredIds.isEmpty) return posts;

    return posts.where((post) {
      final authorId = getAuthorId(post);
      return !filteredIds.contains(authorId);
    }).toList();
  }

  /// Stream that combines muted and blocked for real-time filtering
  Stream<Set<String>> watchFilteredUserIds() {
    return _muteService.watchMutedUserIds();
    // Could combine with block stream:
    // return Rx.combineLatest2(
    //   _muteService.watchMutedUserIds(),
    //   _blockService.watchBlockedUserIds(),
    //   (muted, blocked) => muted.union(blocked),
    // );
  }
}
