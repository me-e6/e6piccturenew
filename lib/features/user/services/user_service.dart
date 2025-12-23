import 'package:cloud_firestore/cloud_firestore.dart';
import '../../profile/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createUserIfNotExists({
    required String uid,
    required String email,
    required String displayName,
    String? profileImageUrl,
  }) async {
    final ref = _firestore.collection('users').doc(uid);
    final snap = await ref.get();

    if (snap.exists) return;

    final handle = _generateHandle(displayName);

    await ref.set({
      'uid': uid,
      'email': email,
      'username': handle,
      'handle': handle,
      'handle_lower': handle.toLowerCase(),

      'displayName': displayName,
      'displayName_lower': displayName.toLowerCase(),

      'photoUrl': profileImageUrl ?? '',
      'profileImageUrl': profileImageUrl,
      'profileBannerUrl': null,
      'bio': '',

      'role': 'citizen',
      'type': 'citizen',
      'isVerified': false,
      'verifiedLabel': '',
      'isAdmin': false,
      'state': 'active',

      'followersCount': 0,
      'followingCount': 0,
      'mutualCount': 0,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? profileImageUrl,
    String? profileBannerUrl,
    String? videoDpUrl,
    String? videoDpThumbUrl,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (displayName != null) {
      updates['displayName'] = displayName;
      updates['displayName_lower'] = displayName.toLowerCase();
    }

    if (bio != null) updates['bio'] = bio;
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
    if (profileBannerUrl != null) {
      updates['profileBannerUrl'] = profileBannerUrl;
    }
    if (videoDpUrl != null) updates['videoDpUrl'] = videoDpUrl;
    if (videoDpThumbUrl != null) {
      updates['videoDpThumbUrl'] = videoDpThumbUrl;
    }

    await _firestore.collection('users').doc(uid).update(updates);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final q = query.toLowerCase();

    final snap = await _firestore
        .collection('users')
        .where('handle_lower', isGreaterThanOrEqualTo: q)
        .where('handle_lower', isLessThan: '$q\uf8ff')
        .limit(20)
        .get();

    return snap.docs.map(UserModel.fromDocument).toList();
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDocument(doc);
  }

  String _generateHandle(String name) {
    final base = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return base.length >= 4 ? base : '${base}user';
  }
}
