import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../post/create/post_model.dart';
import 'user_model.dart';

class ProfileService {
  // --------------------------------------------------
  // FIRESTORE & STORAGE
  // --------------------------------------------------
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --------------------------------------------------
  // FETCH USER
  // --------------------------------------------------
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // --------------------------------------------------
  // FETCH POSTS
  // --------------------------------------------------
  Future<List<PostModel>> getUserPosts(String uid) async {
    final snap = await _firestore
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) => PostModel.fromDocument(d)).toList();
  }

  Future<List<PostModel>> getUserReposts(String uid) async {
    final snap = await _firestore
        .collection('posts')
        .where('repostedByUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) => PostModel.fromDocument(d)).toList();
  }

  Future<List<PostModel>> getSavedPosts(String uid) async {
    final savedSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('saved')
        .get();

    if (savedSnap.docs.isEmpty) return [];

    final ids = savedSnap.docs.map((d) => d.id).toList();

    final postsSnap = await _firestore
        .collection('posts')
        .where(FieldPath.documentId, whereIn: ids)
        .get();

    return postsSnap.docs.map((d) => PostModel.fromDocument(d)).toList();
  }

  // --------------------------------------------------
  // UPDATE PROFILE PHOTO
  // --------------------------------------------------
  Future<String?> updateProfilePhoto(String uid, File file) async {
    final ref = _storage.ref().child('profiles').child('$uid.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await _firestore.collection('users').doc(uid).update({'photoUrl': url});

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
}
