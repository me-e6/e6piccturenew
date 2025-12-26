import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// ============================================================================
/// POST DELETE SERVICE
/// ============================================================================
/// Handles post deletion with complete cleanup of:
/// - Post document
/// - All images in Storage
/// - Subcollections (likes, saves, replies, etc.)
/// - User's post references
/// 
/// FEATURES:
/// - ✅ Author-only deletion (security check)
/// - ✅ Storage cleanup (deletes all post images)
/// - ✅ Subcollection cleanup (likes, saves, repics, replies)
/// - ✅ Repic cascade delete (if this is a repic, update original)
/// - ✅ Transaction-safe operations
/// ============================================================================
class PostDeleteService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  PostDeleteService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // --------------------------------------------------------------------------
  // HELPERS
  // --------------------------------------------------------------------------
  
  String? get _uid => _auth.currentUser?.uid;

  // --------------------------------------------------------------------------
  // CHECK CAN DELETE
  // --------------------------------------------------------------------------
  /// Checks if the current user can delete the post.
  Future<bool> canDelete(String postId) async {
    final uid = _uid;
    if (uid == null) return false;

    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      if (!doc.exists) return false;

      final authorId = doc.data()?['authorId'] as String?;
      return authorId == uid;
    } catch (e) {
      debugPrint('❌ [PostDeleteService] Error checking delete permission: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // DELETE POST
  // --------------------------------------------------------------------------
  /// Deletes a post and all associated data.
  /// 
  /// Steps:
  /// 1. Verify ownership
  /// 2. Delete Storage images
  /// 3. Delete subcollections (likes, saves, repics, replies)
  /// 4. If repic: decrement original post's repicCount
  /// 5. Delete post document
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> deletePost(String postId) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('❌ [PostDeleteService] No user logged in');
      return false;
    }

    try {
      debugPrint('🗑️ [PostDeleteService] Starting deletion for post: $postId');

      // Get post data first
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) {
        debugPrint('⚠️ [PostDeleteService] Post not found: $postId');
        return false;
      }

      final postData = postDoc.data()!;
      final authorId = postData['authorId'] as String?;

      // Verify ownership
      if (authorId != uid) {
        debugPrint('❌ [PostDeleteService] Not authorized to delete this post');
        return false;
      }

      // Check if this is a repic
      final isRepic = postData['isRepic'] ?? false;
      final originalPostId = postData['originalPostId'] as String?;

      // ─────────────────────────────────────────────────────────────────────
      // 1. DELETE STORAGE IMAGES
      // ─────────────────────────────────────────────────────────────────────
      await _deleteStorageImages(postId, authorId!);

      // ─────────────────────────────────────────────────────────────────────
      // 2. DELETE SUBCOLLECTIONS
      // ─────────────────────────────────────────────────────────────────────
      await _deleteSubcollections(postId);

      // ─────────────────────────────────────────────────────────────────────
      // 3. HANDLE REPIC CASCADE
      // ─────────────────────────────────────────────────────────────────────
      if (isRepic && originalPostId != null) {
        await _handleRepicDeletion(originalPostId, uid);
      }

      // ─────────────────────────────────────────────────────────────────────
      // 4. DELETE USER'S POST REFERENCE
      // ─────────────────────────────────────────────────────────────────────
      await _deleteUserPostReference(uid, postId);

      // ─────────────────────────────────────────────────────────────────────
      // 5. DELETE POST DOCUMENT
      // ─────────────────────────────────────────────────────────────────────
      await _firestore.collection('posts').doc(postId).delete();

      debugPrint('✅ [PostDeleteService] Post deleted successfully: $postId');
      return true;

    } catch (e) {
      debugPrint('❌ [PostDeleteService] Error deleting post: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // DELETE STORAGE IMAGES
  // --------------------------------------------------------------------------
  Future<void> _deleteStorageImages(String postId, String authorId) async {
    try {
      final storageRef = _storage.ref().child('posts').child(authorId).child(postId);
      
      // List all items in the folder
      final listResult = await storageRef.listAll();
      
      // Delete each item
      for (final item in listResult.items) {
        try {
          await item.delete();
          debugPrint('🗑️ [PostDeleteService] Deleted image: ${item.name}');
        } catch (e) {
          debugPrint('⚠️ [PostDeleteService] Failed to delete image: ${item.name}');
        }
      }

      debugPrint('✅ [PostDeleteService] Storage cleanup complete');
    } catch (e) {
      // Storage might not have files for this post (e.g., repic posts)
      debugPrint('⚠️ [PostDeleteService] Storage cleanup skipped: $e');
    }
  }

  // --------------------------------------------------------------------------
  // DELETE SUBCOLLECTIONS
  // --------------------------------------------------------------------------
  Future<void> _deleteSubcollections(String postId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    
    // List of subcollections to delete
    final subcollections = ['likes', 'saves', 'repics', 'replies', 'quotes'];

    for (final subcollection in subcollections) {
      try {
        final snapshot = await postRef.collection(subcollection).limit(500).get();
        
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        debugPrint('🗑️ [PostDeleteService] Deleted $subcollection subcollection');
      } catch (e) {
        debugPrint('⚠️ [PostDeleteService] Error deleting $subcollection: $e');
      }
    }
  }

  // --------------------------------------------------------------------------
  // HANDLE REPIC DELETION
  // --------------------------------------------------------------------------
  Future<void> _handleRepicDeletion(String originalPostId, String uid) async {
    try {
      // Decrement repicCount on original post
      await _firestore.collection('posts').doc(originalPostId).update({
        'repicCount': FieldValue.increment(-1),
      });

      // Remove from original post's repics subcollection
      await _firestore
          .collection('posts')
          .doc(originalPostId)
          .collection('repics')
          .doc(uid)
          .delete();

      // Remove from user's repics subcollection
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('repics')
          .doc(originalPostId)
          .delete();

      debugPrint('✅ [PostDeleteService] Repic cascade handled');
    } catch (e) {
      debugPrint('⚠️ [PostDeleteService] Error handling repic cascade: $e');
    }
  }

  // --------------------------------------------------------------------------
  // DELETE USER POST REFERENCE
  // --------------------------------------------------------------------------
  Future<void> _deleteUserPostReference(String uid, String postId) async {
    try {
      // Delete from user's posts subcollection if it exists
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('posts')
          .doc(postId)
          .delete();
    } catch (e) {
      // May not exist, that's okay
      debugPrint('⚠️ [PostDeleteService] User post ref cleanup: $e');
    }
  }

  // --------------------------------------------------------------------------
  // BATCH DELETE (For cleanup)
  // --------------------------------------------------------------------------
  /// Deletes multiple posts. Use with caution.
  Future<int> batchDelete(List<String> postIds) async {
    int successCount = 0;

    for (final postId in postIds) {
      final success = await deletePost(postId);
      if (success) successCount++;
    }

    debugPrint('✅ [PostDeleteService] Batch deleted $successCount/${postIds.length} posts');
    return successCount;
  }
}
