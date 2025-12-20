import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../post/create/post_model.dart';
import 'user_model.dart';

class ProfileService {
  // --------------------------------------------------
  // FIRESTORE & STORAGE
  // --------------------------------------------------
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProfileService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  // --------------------------------------------------
  // FETCH USER
  // --------------------------------------------------
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    return UserModel.fromDocument(doc);
  }

  // --------------------------------------------------
  // FETCH USER POSTS
  // --------------------------------------------------
  Future<List<PostModel>> getUserPosts(String uid) async {
    final snap = await _firestore
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  // --------------------------------------------------
  // FETCH USER REPOSTS
  // --------------------------------------------------
  Future<List<PostModel>> getUserReposts(String uid) async {
    final snap = await _firestore
        .collection('posts')
        .where('isRepost', isEqualTo: true)
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  // --------------------------------------------------
  // FETCH SAVED POSTS (OWNER ONLY)
  // --------------------------------------------------
  Future<List<PostModel>> getSavedPosts(String uid) async {
    final savedSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('saved')
        .get();

    if (savedSnap.docs.isEmpty) return [];

    final ids = savedSnap.docs.map((d) => d.id).toList();

    // Firestore whereIn safeguard
    if (ids.length > 10) return [];

    final postsSnap = await _firestore
        .collection('posts')
        .where(FieldPath.documentId, whereIn: ids)
        .get();

    return postsSnap.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  // --------------------------------------------------
  // UPDATE PROFILE PHOTO (DP)
  // --------------------------------------------------
  Future<String?> updateProfilePhoto({
    required String uid,
    required File file,
  }) async {
    final ref = _storage
        .ref()
        .child('profile_pictures')
        .child(uid)
        .child('dp.jpg');

    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

    final url = await ref.getDownloadURL();

    await _firestore.collection('users').doc(uid).update({
      'profileImageUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return url;
  }

  // --------------------------------------------------
  // 🔐 ADMIN — TOGGLE GAZETTER (VERIFIED)
  // --------------------------------------------------
  Future<void> toggleGazetter({
    required String targetUid,
    required bool makeVerified,
  }) async {
    await _firestore.collection('users').doc(targetUid).update({
      'isVerified': makeVerified,
      'verifiedLabel': makeVerified ? 'Gazetter' : '',
    });
  }

  // --------------------------------------------------
  //  Profiel Identity Banner
  // --------------------------------------------------
  Future<String?> updateProfileBanner({
    required String uid,
    required File file,
  }) async {
    final ref = _storage
        .ref()
        .child('profile_banners')
        .child(uid)
        .child('banner.jpg');

    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();

    await _firestore.collection('users').doc(uid).update({
      'profileBannerUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    //--------------------------------------------------
    //  -Update Profile Details
    // --------------------------------------------------

    return url;
  }

  // --------------------------------------------------
  // UPDATE PROFILE DETAILS (EDIT PROFILE)
  // --------------------------------------------------
  Future<void> updateProfileDetails({
    required String uid,
    required String displayName,
    required String bio,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'displayName': displayName,
      'bio': bio,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
