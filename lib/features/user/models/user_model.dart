import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { citizen, officer, admin, superAdmin }

enum UserState { active, suspended, readOnly, deleted }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  final UserRole role;
  final UserState state;

  final bool isVerified;
  final String? jurisdictionId;

  final int followersCount;
  final int followingCount;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    required this.state,
    required this.isVerified,
    required this.jurisdictionId,
    required this.followersCount,
    required this.followingCount,
    required this.createdAt,
    required this.updatedAt,
  });

  // --------------------------------------------------
  // FACTORY: NEW USER (WRITE TO FIRESTORE)
  // --------------------------------------------------
  static Map<String, dynamic> newCitizenMap({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': UserRole.citizen.name,
      'state': UserState.active.name,
      'isVerified': false,
      'jurisdictionId': null,
      'followersCount': 0,
      'followingCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // --------------------------------------------------
  // FACTORY: FROM FIRESTORE
  // --------------------------------------------------
  factory UserModel.fromMap(Map<String, dynamic> map) {
    final createdTs = map['createdAt'];
    final updatedTs = map['updatedAt'];

    return UserModel(
      uid: map['uid'],
      email: map['email'],
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      role: _parseRole(map['role']),
      state: _parseState(map['state']),
      isVerified: map['isVerified'] ?? false,
      jurisdictionId: map['jurisdictionId'],
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      createdAt: createdTs is Timestamp ? createdTs.toDate() : DateTime.now(),
      updatedAt: updatedTs is Timestamp ? updatedTs.toDate() : DateTime.now(),
    );
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------
  static UserRole _parseRole(String? value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.citizen,
    );
  }

  static UserState _parseState(String? value) {
    return UserState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserState.active,
    );
  }
}
