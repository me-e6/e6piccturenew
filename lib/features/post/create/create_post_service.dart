import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreatePostService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CreatePostService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  Future<void> createImagePost({
    required String authorId,
    required List<File> images,
  }) async {
    if (images.isEmpty) {
      throw Exception('No images provided');
    }

    final postRef = _firestore.collection('posts').doc();
    final postId = postRef.id;

    final List<String> imageUrls = [];

    for (int i = 0; i < images.length; i++) {
      final ref = _storage
          .ref()
          .child('posts')
          .child(authorId)
          .child(postId)
          .child('image_$i.jpg');

      await ref.putFile(images[i], SettableMetadata(contentType: 'image/jpeg'));

      imageUrls.add(await ref.getDownloadURL());
    }

    await postRef.set({
      'postId': postId,
      'authorId': authorId,
      'authorName': '',
      'imageUrls': imageUrls,
      'isRepost': false,
      'visibility': 'public',
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'replyCount': 0,
      'quoteReplyCount': 0,
      'isVerifiedOwner': false,
    });
  }
}
