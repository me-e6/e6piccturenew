enum UserRole { citizen, officer, admin, superAdmin }

enum UserState { active, suspended, readOnly, deleted }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;

  final UserRole role;
  final UserState state;

  final bool isVerified;
  final String? jurisdictionId;

  final int followersCount;
  final int followingCount;

  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
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

  /// DEFAULT path after OAuth / signup
  factory UserModel.newCitizen({
    required String uid,
    required String email,
    required String displayName,
    required String photoUrl,
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      role: UserRole.citizen,
      state: UserState.active,
      isVerified: false,
      jurisdictionId: null,
      followersCount: 0,
      followingCount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      role: UserRole.values.byName(map['role']),
      state: UserState.values.byName(map['state']),
      isVerified: map['isVerified'] ?? false,
      jurisdictionId: map['jurisdictionId'],
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.name,
      'state': state.name,
      'isVerified': isVerified,
      'jurisdictionId': jurisdictionId,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
