import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ============================================================================
/// REPIC SERVICE - v2 (FIXED IMAGE URLS)
/// ============================================================================
/// Creates repic posts that:
/// - Appear in the repiccer's feed
/// - Appear in followers' feeds
/// - Reference the original post (denormalized)
/// - Show "User repicced" header
/// 
/// FIX: Now reads both 'imageUrls' and 'images' keys for compatibility
/// ============================================================================
class RepicService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RepicService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // --------------------------------------------------------------------------
  // HELPER: Parse image URLs from data (handles both keys)
  // --------------------------------------------------------------------------
  List<String> _parseImageUrls(Map<String, dynamic> data) {
    final urls = data['imageUrls'] ?? data['images'];
    if (urls is List) {
      return urls.map((e) => e.toString()).toList();
    }
    return [];
  }

  // --------------------------------------------------------------------------
  // CREATE REPIC POST
  // --------------------------------------------------------------------------
  Future<String?> createRepicPost(String originalPostId) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Cannot repic: No user logged in');
      return null;
    }

    try {
      // 1. Fetch original post
      final originalDoc = await _firestore
          .collection('posts')
          .doc(originalPostId)
          .get();

      if (!originalDoc.exists) {
        debugPrint('❌ Cannot repic: Original post not found');
        return null;
      }

      final originalData = originalDoc.data()!;

      // 2. Prevent repiccing your own post
      if (originalData['authorId'] == user.uid) {
        debugPrint('⚠️ Cannot repic your own post');
        return null;
      }

      // 3. Check if user already repicced this post
      final existingRepic = await _firestore
          .collection('posts')
          .where('isRepic', isEqualTo: true)
          .where('originalPostId', isEqualTo: originalPostId)
          .where('repicAuthorId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existingRepic.docs.isNotEmpty) {
        debugPrint('⚠️ Already repicced this post');
        return existingRepic.docs.first.id;
      }

      // 4. Fetch current user data for repic header
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // ✅ FIX: Parse image URLs properly (handles both 'imageUrls' and 'images')
      final originalImageUrls = _parseImageUrls(originalData);

      // 5. Create repic post document
      final repicRef = _firestore.collection('posts').doc();
      final now = FieldValue.serverTimestamp();

      final repicData = {
        'postId': repicRef.id,
        'isRepic': true,
        'originalPostId': originalPostId,
        'createdAt': now,
        
        // Repic author (who clicked repic)
        'repicAuthorId': user.uid,
        'repicAuthorName': userData['displayName'] ?? user.displayName ?? 'User',
        'repicAuthorHandle': userData['handle'] ?? userData['username'],
        'repicAuthorAvatarUrl': userData['profileImageUrl'] ?? userData['photoUrl'],
        'repicAuthorIsVerified': userData['isVerified'] ?? false,

        // Original post author (for display)
        'authorId': originalData['authorId'],
        'authorName': originalData['authorName'] ?? 'Unknown',
        'authorHandle': originalData['authorHandle'],
        'authorAvatarUrl': originalData['authorAvatarUrl'],
        'authorIsVerified': originalData['authorIsVerified'] ?? false,

        // Original post content (denormalized for fast reads)
        'originalPost': {
          'postId': originalPostId,
          'authorId': originalData['authorId'],
          'authorName': originalData['authorName'],
          'authorHandle': originalData['authorHandle'],
          'authorAvatarUrl': originalData['authorAvatarUrl'],
          'authorIsVerified': originalData['authorIsVerified'] ?? false,
          'imageUrls': originalImageUrls, // ✅ FIXED
          'caption': originalData['caption'] ?? '',
          'likeCount': originalData['likeCount'] ?? 0,
          'replyCount': originalData['replyCount'] ?? 0,
          'repicCount': originalData['repicCount'] ?? 0,
        },

        // ✅ FIXED: Copy image URLs for grid display (using parsed list)
        'imageUrls': originalImageUrls,
        'caption': originalData['caption'] ?? '',

        // Initialize counters
        'likeCount': 0,
        'saveCount': 0,
        'repicCount': 0,
        'replyCount': 0,
        'quoteReplyCount': 0,
      };

      // 6. Run transaction to create repic and update counter
      await _firestore.runTransaction((tx) async {
        // Create repic post
        tx.set(repicRef, repicData);

        // Increment repicCount on original post
        tx.update(
          _firestore.collection('posts').doc(originalPostId),
          {'repicCount': FieldValue.increment(1)},
        );

        // Add to user's repics subcollection
        tx.set(
          _firestore
              .collection('users')
              .doc(user.uid)
              .collection('repics')
              .doc(originalPostId),
          {
            'postId': originalPostId,
            'repicPostId': repicRef.id,
            'repickedAt': now,
          },
        );

        // Add to post's repics subcollection
        tx.set(
          _firestore
              .collection('posts')
              .doc(originalPostId)
              .collection('repics')
              .doc(user.uid),
          {
            'uid': user.uid,
            'repicPostId': repicRef.id,
            'repickedAt': now,
          },
        );
      });

      debugPrint('✅ Created repic post: ${repicRef.id} with ${originalImageUrls.length} images');
      return repicRef.id;
    } catch (e) {
      debugPrint('❌ Error creating repic: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // UNDO REPIC
  // --------------------------------------------------------------------------
  Future<bool> undoRepic(String originalPostId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // 1. Find the repic post
      final repicQuery = await _firestore
          .collection('posts')
          .where('isRepic', isEqualTo: true)
          .where('originalPostId', isEqualTo: originalPostId)
          .where('repicAuthorId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (repicQuery.docs.isEmpty) {
        debugPrint('⚠️ No repic found to undo');
        return true; // Idempotent
      }

      final repicPostId = repicQuery.docs.first.id;

      // 2. Run transaction to delete repic and update counter
      await _firestore.runTransaction((tx) async {
        // Delete repic post
        tx.delete(_firestore.collection('posts').doc(repicPostId));

        // Decrement repicCount on original post
        tx.update(
          _firestore.collection('posts').doc(originalPostId),
          {'repicCount': FieldValue.increment(-1)},
        );

        // Remove from user's repics subcollection
        tx.delete(
          _firestore
              .collection('users')
              .doc(user.uid)
              .collection('repics')
              .doc(originalPostId),
        );

        // Remove from post's repics subcollection
        tx.delete(
          _firestore
              .collection('posts')
              .doc(originalPostId)
              .collection('repics')
              .doc(user.uid),
        );
      });

      debugPrint('✅ Undid repic for post: $originalPostId');
      return true;
    } catch (e) {
      debugPrint('❌ Error undoing repic: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // CHECK IF REPICCED
  // --------------------------------------------------------------------------
  Future<bool> hasRepicced(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('repics')
        .doc(user.uid)
        .get();

    return doc.exists;
  }

  // --------------------------------------------------------------------------
  // GET REPIC USERS (for list)
  // --------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getRepicUsers(String postId) async {
    final snap = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('repics')
        .orderBy('repickedAt', descending: true)
        .limit(50)
        .get();

    final List<Map<String, dynamic>> users = [];

    for (final doc in snap.docs) {
      final uid = doc.id;
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        users.add({
          'uid': uid,
          'displayName': userData['displayName'] ?? 'User',
          'handle': userData['handle'] ?? userData['username'],
          'avatarUrl': userData['profileImageUrl'] ?? userData['photoUrl'],
          'isVerified': userData['isVerified'] ?? false,
          'repickedAt': doc.data()['repickedAt'],
        });
      }
    }

    return users;
  }

  // --------------------------------------------------------------------------
  // GET QUOTE POSTS (for list)
  // --------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getQuotePosts(String postId) async {
    final snap = await _firestore
        .collection('posts')
        .where('isQuote', isEqualTo: true)
        .where('quotedPostId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        'postId': doc.id,
        'authorId': data['authorId'],
        'authorName': data['authorName'] ?? 'User',
        'authorHandle': data['authorHandle'],
        'authorAvatarUrl': data['authorAvatarUrl'],
        'authorIsVerified': data['authorIsVerified'] ?? false,
        'commentary': data['commentary'] ?? data['caption'] ?? '',
        'createdAt': data['createdAt'],
      };
    }).toList();
  }
}
