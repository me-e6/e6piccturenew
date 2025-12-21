/* import 'package:cloud_firestore/cloud_firestore.dart';
import '../../profile/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // UPSERT USER (REQUIRED FOR SEARCH INDEXING)
  // ------------------------------------------------------------
  Future<void> upsertUser({
    required String uid,
    required String handle,
    required String displayName,
    String? profileImageUrl,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,

      'handle': handle,
      'handle_lower': handle.toLowerCase(),

      'displayName': displayName,
      'displayName_lower': displayName.toLowerCase(),

      'profileImageUrl': profileImageUrl,

      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ------------------------------------------------------------
  // SEARCH USERS (PURE — INDEXED)
  // ------------------------------------------------------------
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final q = query.toLowerCase();

    final snap = await _firestore
        .collection('users')
        .orderBy('handle_lower')
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .limit(20)
        .get();

    return snap.docs.map((d) => UserModel.fromDocument(d)).toList();
  }

  // ------------------------------------------------------------
  // GET SINGLE USER
  // ------------------------------------------------------------
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDocument(doc);
  }
}
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../profile/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // CREATE / UPDATE USER (CANONICAL)
  // ------------------------------------------------------------
  Future<void> upsertUser({
    required String uid,
    required String email,
    required String displayName,
    String? profileImageUrl,
  }) async {
    final handle = _generateHandle(displayName);

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,

      // Identity
      'displayName': displayName,
      'displayName_lower': displayName.toLowerCase(),

      'handle': handle,
      'handle_lower': handle.toLowerCase(),

      'profileImageUrl': profileImageUrl ?? '',

      // Social
      'followersCount': 0,
      'followingCount': 0,

      // Flags
      'isVerified': false,

      // Audit
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ------------------------------------------------------------
  // SEARCH (INDEXED)
  // ------------------------------------------------------------
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final q = query.toLowerCase();

    final snap = await _firestore
        .collection('users')
        .where('handle_lower', isGreaterThanOrEqualTo: q)
        .where('handle_lower', isLessThan: '$q\uf8ff')
        .limit(20)
        .get();

    return snap.docs.map((d) => UserModel.fromDocument(d)).toList();
  }

  // ------------------------------------------------------------
  // GET SINGLE USER
  // ------------------------------------------------------------
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDocument(doc);
  }

  // ------------------------------------------------------------
  // HANDLE GENERATION (STABLE)
  // ------------------------------------------------------------
  String _generateHandle(String name) {
    final base = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return base.length >= 4 ? base : '${base}user';
  }
}
