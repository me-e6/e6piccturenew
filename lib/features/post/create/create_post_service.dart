import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --------------------------------------------------
  // CREATE POST (SINGLE OR MULTI IMAGE)
  // --------------------------------------------------
  Future<String> createPost({
    required List<File> images,
    required String description,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return "auth-error";

      final userDoc = await _firestore.collection('users').doc(uid).get();

      final bool isVerified = userDoc.data()?['isVerified'] ?? false;
      final String ownerName = userDoc.data()?['displayName'] ?? '';

      if (images.isEmpty) return "no-images";

      // --------------------------------------------------
      // STEP 1: UPLOAD ALL IMAGES
      // --------------------------------------------------
      final List<String> uploadedUrls = [];

      for (final image in images) {
        final url = await _uploadSingleImage(uid, image);
        if (url == null) {
          return "storage-error";
        }
        uploadedUrls.add(url);
      }

      // --------------------------------------------------
      // STEP 2: WRITE FIRESTORE ONCE (AUTHORITATIVE SNAPSHOT)
      // --------------------------------------------------
      final postRef = _firestore.collection("posts").doc();

      await postRef.set({
        "postId": postRef.id,
        "authorId": uid,

        // OWNER SNAPSHOT (GAZETTER SUPPORT)
        "ownerName": ownerName,
        "ownerVerified": isVerified,

        // MEDIA
        "imageUrls": uploadedUrls,
        "imageUrl": uploadedUrls.first, // legacy fallback
        // SOCIAL POST
        "isRepost": false,

        // ENGAGEMENT COUNTERS
        "likeCount": 0,
        "replyCount": 0,
        "quoteReplyCount": 0,

        "createdAt": FieldValue.serverTimestamp(),
      });

      return "success";
    } catch (_) {
      return "error";
    }
  }

  // --------------------------------------------------
  // UPLOAD SINGLE IMAGE
  // --------------------------------------------------
  Future<String?> _uploadSingleImage(String uid, File image) async {
    try {
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}";

      final ref = _storage.ref().child("posts").child(uid).child(fileName);

      final taskSnapshot = await ref.putFile(image);
      return await taskSnapshot.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}
