import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreatePostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ------------------------------------------------------------
  // CREATE IMAGE POST (MULTI-IMAGE)
  // ------------------------------------------------------------
  Future<void> createImagePost({
    required String authorId,
    required List<File> images,
  }) async {
    if (images.isEmpty) {
      throw Exception('No images provided');
    }

    final postRef = _firestore.collection('posts').doc();
    final postId = postRef.id;

    // ------------------------------------------------------------
    // UPLOAD IMAGES (SEQUENTIAL, ORDER PRESERVED)
    // ------------------------------------------------------------
    final List<String> imageUrls = [];

    for (int i = 0; i < images.length; i++) {
      final file = images[i];

      final ref = _storage
          .ref()
          .child('posts')
          .child(authorId)
          .child(postId)
          .child('image_$i.jpg');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    // ------------------------------------------------------------
    // CREATE POST DOCUMENT
    // ------------------------------------------------------------
    await postRef.set({
      'postId': postId,
      'authorId': authorId,
      'authorName': '', // populate later from user profile
      'imageUrls': imageUrls,
      'isRepost': false,
      'visibility': 'public',
      'createdAt': FieldValue.serverTimestamp(),

      // Engagement counters
      'likeCount': 0,
      'replyCount': 0,
      'quoteReplyCount': 0,

      // Verification (resolved at read time if needed)
      'isVerifiedOwner': false,
    });
  }
}
