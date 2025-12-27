import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ============================================================================
/// FOLLOW SERVICE - v2 (FIXED)
/// ============================================================================
/// Fixes:
/// - ✅ Uses set() with merge instead of update() for counter fields
/// - ✅ Checks if user documents exist before operations
/// - ✅ Better error messages
/// - ✅ Transaction-safe operations
/// ============================================================================
class FollowService {
  FollowService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // --------------------------------------------------------------------------
  // FOLLOW (FIXED)
  // --------------------------------------------------------------------------
  Future<void> follow({
    required String currentUid,
    required String targetUid,
  }) async {
    if (currentUid == targetUid) {
      debugPrint('⚠️ Cannot follow yourself');
      return;
    }

    final currentUserRef = _firestore.collection('users').doc(currentUid);
    final targetUserRef = _firestore.collection('users').doc(targetUid);

    // Check if already following
    final existingFollow = await currentUserRef
        .collection('following')
        .doc(targetUid)
        .get();

    if (existingFollow.exists) {
      debugPrint('⚠️ Already following $targetUid');
      return;
    }

    try {
      await _firestore.runTransaction((tx) async {
        // Get current user doc to check it exists
        final currentUserDoc = await tx.get(currentUserRef);
        final targetUserDoc = await tx.get(targetUserRef);

        if (!currentUserDoc.exists) {
          throw Exception('Current user does not exist');
        }
        if (!targetUserDoc.exists) {
          throw Exception('Target user does not exist');
        }

        final now = FieldValue.serverTimestamp();

        // Add to current user's following
        tx.set(
          currentUserRef.collection('following').doc(targetUid),
          {'createdAt': now, 'uid': targetUid},
        );

        // Add to target user's followers
        tx.set(
          targetUserRef.collection('followers').doc(currentUid),
          {'createdAt': now, 'uid': currentUid},
        );

        // ✅ FIX: Use set with merge to handle missing fields
        tx.set(
          currentUserRef,
          {'followingCount': FieldValue.increment(1)},
          SetOptions(merge: true),
        );

        tx.set(
          targetUserRef,
          {'followersCount': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      });

      debugPrint('✅ Successfully followed $targetUid');
    } catch (e) {
      debugPrint('❌ Follow failed: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // UNFOLLOW (FIXED)
  // --------------------------------------------------------------------------
  Future<void> unfollow({
    required String currentUid,
    required String targetUid,
  }) async {
    if (currentUid == targetUid) {
      debugPrint('⚠️ Cannot unfollow yourself');
      return;
    }

    final currentUserRef = _firestore.collection('users').doc(currentUid);
    final targetUserRef = _firestore.collection('users').doc(targetUid);

    // Check if actually following
    final existingFollow = await currentUserRef
        .collection('following')
        .doc(targetUid)
        .get();

    if (!existingFollow.exists) {
      debugPrint('⚠️ Not following $targetUid');
      return;
    }

    try {
      await _firestore.runTransaction((tx) async {
        // Remove from current user's following
        tx.delete(currentUserRef.collection('following').doc(targetUid));

        // Remove from target user's followers
        tx.delete(targetUserRef.collection('followers').doc(currentUid));

        // ✅ FIX: Use set with merge to handle missing fields
        tx.set(
          currentUserRef,
          {'followingCount': FieldValue.increment(-1)},
          SetOptions(merge: true),
        );

        tx.set(
          targetUserRef,
          {'followersCount': FieldValue.increment(-1)},
          SetOptions(merge: true),
        );
      });

      debugPrint('✅ Successfully unfollowed $targetUid');
    } catch (e) {
      debugPrint('❌ Unfollow failed: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // CHECK FOLLOWING
  // --------------------------------------------------------------------------
  Future<bool> isFollowing({
    required String currentUid,
    required String targetUid,
  }) async {
    if (currentUid == targetUid) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUid)
          .collection('following')
          .doc(targetUid)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error checking follow status: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // GET FOLLOWING IDS
  // --------------------------------------------------------------------------
  Future<List<String>> getFollowingUids(String uid) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('following')
          .get();

      return snap.docs.map((d) => d.id).toList();
    } catch (e) {
      debugPrint('❌ Error getting following: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // GET FOLLOWER IDS
  // --------------------------------------------------------------------------
  Future<List<String>> getFollowerUids(String uid) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followers')
          .get();

      return snap.docs.map((d) => d.id).toList();
    } catch (e) {
      debugPrint('❌ Error getting followers: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // GET FOLLOWERS COUNT (from subcollection, not field)
  // --------------------------------------------------------------------------
  Future<int> getFollowersCount(String uid) async {
    try {
      // Try to get from user document first (faster)
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final count = userDoc.data()?['followersCount'];
      
      if (count is int && count >= 0) {
        return count;
      }

      // Fallback: count from subcollection
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followers')
          .count()
          .get();

      final actualCount = snap.count ?? 0;

      // Update the field if it was wrong/missing
      if (count != actualCount) {
        await _firestore.collection('users').doc(uid).set(
          {'followersCount': actualCount},
          SetOptions(merge: true),
        );
      }

      return actualCount;
    } catch (e) {
      debugPrint('❌ Error getting followers count: $e');
      return 0;
    }
  }

  // --------------------------------------------------------------------------
  // GET FOLLOWING COUNT (from subcollection, not field)
  // --------------------------------------------------------------------------
  Future<int> getFollowingCount(String uid) async {
    try {
      // Try to get from user document first (faster)
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final count = userDoc.data()?['followingCount'];
      
      if (count is int && count >= 0) {
        return count;
      }

      // Fallback: count from subcollection
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('following')
          .count()
          .get();

      final actualCount = snap.count ?? 0;

      // Update the field if it was wrong/missing
      if (count != actualCount) {
        await _firestore.collection('users').doc(uid).set(
          {'followingCount': actualCount},
          SetOptions(merge: true),
        );
      }

      return actualCount;
    } catch (e) {
      debugPrint('❌ Error getting following count: $e');
      return 0;
    }
  }

  // --------------------------------------------------------------------------
  // GET MUTUALS
  // --------------------------------------------------------------------------
  Future<Set<String>> getMutuals(String uid) async {
    try {
      final followers = await getFollowerUids(uid);
      final following = await getFollowingUids(uid);

      return followers.toSet().intersection(following.toSet());
    } catch (e) {
      debugPrint('❌ Error getting mutuals: $e');
      return {};
    }
  }

  // --------------------------------------------------------------------------
  // CHECK IF MUTUAL
  // --------------------------------------------------------------------------
  Future<bool> isMutual({
    required String currentUid,
    required String targetUid,
  }) async {
    if (currentUid == targetUid) return false;

    try {
      // Check both directions
      final iFollowThem = await isFollowing(
        currentUid: currentUid,
        targetUid: targetUid,
      );

      if (!iFollowThem) return false;

      final theyFollowMe = await isFollowing(
        currentUid: targetUid,
        targetUid: currentUid,
      );

      return theyFollowMe;
    } catch (e) {
      debugPrint('❌ Error checking mutual status: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // SYNC FOLLOW COUNTS (Utility for fixing counts)
  // --------------------------------------------------------------------------
  Future<void> syncFollowCounts(String uid) async {
    try {
      final followersSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followers')
          .count()
          .get();

      final followingSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('following')
          .count()
          .get();

      await _firestore.collection('users').doc(uid).set({
        'followersCount': followersSnap.count ?? 0,
        'followingCount': followingSnap.count ?? 0,
      }, SetOptions(merge: true));

      debugPrint('✅ Synced follow counts for $uid');
    } catch (e) {
      debugPrint('❌ Error syncing follow counts: $e');
    }
  }
}
