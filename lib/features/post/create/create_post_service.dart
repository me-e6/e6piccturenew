import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreatePostService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CreatePostService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  /// Creates a multi-image post with full rollback safety.
  /// - Uploads all images to Storage
  /// - Rolls back partial uploads on failure
  /// - Writes Firestore document only after success
  Future<void> createImagePost({required List<File> images}) async {
    if (images.isEmpty) {
      throw Exception('No images provided');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final String authorId = user.uid;
    final String? avatarUrl = user.photoURL;

    final postRef = _firestore.collection('posts').doc();
    final postId = postRef.id;

    final List<String> imageUrls = [];
    final List<Reference> uploadedRefs = [];

    try {
      // ------------------------------------------------------------
      // 1. UPLOAD ALL IMAGES
      // ------------------------------------------------------------
      for (int i = 0; i < images.length; i++) {
        final ref = _storage
            .ref()
            .child('posts')
            .child(authorId)
            .child(postId)
            .child('image_$i.jpg');

        await ref.putFile(
          images[i],
          SettableMetadata(contentType: 'image/jpeg'),
        );

        uploadedRefs.add(ref);
        imageUrls.add(await ref.getDownloadURL());
      }

      // ------------------------------------------------------------
      // 2. WRITE FIRESTORE (ATOMIC FROM UI PERSPECTIVE)
      // ------------------------------------------------------------
      await postRef.set({
        'postId': postId,
        'authorId': authorId,
        'authorName': '', // resolved later via profile
        'authorAvatarUrl': avatarUrl,
        'imageUrls': imageUrls,
        'isRepost': false,
        'visibility': 'public',
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'replyCount': 0,
        'quoteReplyCount': 0,
        'isVerifiedOwner': false,
      });
    } catch (e) {
      // ------------------------------------------------------------
      // 3. ROLLBACK STORAGE (BEST EFFORT)
      // ------------------------------------------------------------
      for (final ref in uploadedRefs) {
        try {
          await ref.delete();
        } catch (_) {
          // Swallow cleanup failures (non-fatal)
        }
      }
      rethrow;
    }
  }
}
