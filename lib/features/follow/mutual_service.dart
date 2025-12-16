import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ------------------------------------------------------------
/// MUTUAL SERVICE (CANONICAL, DERIVED LOGIC ONLY)
/// ------------------------------------------------------------
/// - Reads followers & following from users/{uid}
/// - Computes mutuals via set intersection
/// - NEVER writes data
/// - NEVER stores mutuals
/// - NEVER swallows errors silently
class MutualService {
  MutualService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// ------------------------------------------------------------
  /// Fetch mutual user IDs for a given user
  /// ------------------------------------------------------------
  /// Mutual = users who are BOTH:
  /// - in my followers
  /// - in my following
  ///
  /// This method:
  /// - Is deterministic
  /// - Uses canonical schema only
  /// - Throws on unexpected failures (caller decides UX)
  Future<List<String>> getMutualUids(String uid) async {
    try {
      final followersSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followers')
          .get();

      final followingSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('following')
          .get();

      final Set<String> followers = followersSnap.docs
          .map((doc) => doc.id)
          .toSet();

      final Set<String> following = followingSnap.docs
          .map((doc) => doc.id)
          .toSet();

      // Intersection = mutuals
      return followers.intersection(following).toList();
    } catch (e, st) {
      // DO NOT swallow errors silently
      debugPrint('MutualService.getMutualUids failed for uid=$uid');
      debugPrint('Error: $e');
      debugPrint('Stack: $st');
      rethrow;
    }
  }

  /// ------------------------------------------------------------
  /// Optimized mutual count
  /// ------------------------------------------------------------
  /// NOTE:
  /// - We intentionally reuse getMutualUids
  /// - This avoids divergence bugs
  /// - Can be optimized later with counters if needed
  Future<int> getMutualCount(String uid) async {
    final mutuals = await getMutualUids(uid);
    return mutuals.length;
  }
}
