import 'package:cloud_firestore/cloud_firestore.dart';

/// ------------------------------------------------------------
/// USER MODEL — CANONICAL /users/{uid}
/// ------------------------------------------------------------
/// Represents ONLY the user document.
/// Relationship lists live in subcollections.
class UserModel {
  // -------------------------
  // CORE IDENTITY
  // -------------------------
  final String uid;
  final String email;
  final String username; // @handle (unique, lowercase)
  final String displayName;

  // -------------------------
  // PROFILE
  // -------------------------
  final String photoUrl;
  final String? profileImageUrl;
  final String? videoDpUrl;
  final String? videoDpThumbUrl;
  final String bio;
  // ------------------------------------------------------------
  // UI ALIAS (CANONICAL HANDLE)
  // ------------------------------------------------------------
  /// `handle` is the canonical UI identifier.
  /// Maps to existing username / displayName safely.
  String get handle => username.isNotEmpty ? username : displayName;

  // -------------------------
  // ROLE / STATE
  // -------------------------
  final String role; // citizen | gazetter | admin | superAdmin
  final String type; // citizen | gazetter (UI-facing)
  final bool isVerified;
  final String verifiedLabel;
  final bool isAdmin;
  final String state; // active | suspended | readOnly | deleted
  final String? jurisdictionId;

  // -------------------------
  // SOCIAL GRAPH
  // -------------------------
  final int followersCount;
  final int followingCount;
  final int mutualCount;

  // -------------------------
  // AUDIT
  // -------------------------
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    required this.photoUrl,
    required this.profileImageUrl,
    required this.bio,
    required this.role,
    required this.type,
    required this.isVerified,
    required this.verifiedLabel,
    required this.isAdmin,
    required this.state,
    required this.followersCount,
    required this.followingCount,
    required this.mutualCount,
    required this.createdAt,
    required this.updatedAt,
    this.videoDpUrl,
    this.videoDpThumbUrl,
    this.jurisdictionId,
  });

  // ------------------------------------------------------------
  // FIRESTORE → MODEL (DEFENSIVE, CANONICAL)
  // ------------------------------------------------------------
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final raw = doc.data();
    if (raw == null || raw is! Map<String, dynamic>) {
      throw Exception('Invalid user document: ${doc.id}');
    }

    final data = raw;

    DateTime _parseTs(dynamic v) =>
        v is Timestamp ? v.toDate() : DateTime.now();

    return UserModel(
      uid: data['uid'] ?? doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      videoDpUrl: data['videoDpUrl'],
      videoDpThumbUrl: data['videoDpThumbUrl'],
      bio: data['bio'] ?? '',
      role: data['role'] ?? 'citizen',
      type: data['type'] ?? 'citizen',
      isVerified: data['isVerified'] ?? false,
      verifiedLabel: data['verifiedLabel'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      state: data['state'] ?? 'active',
      jurisdictionId: data['jurisdictionId'],
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      mutualCount: data['mutualCount'] ?? 0,
      createdAt: _parseTs(data['createdAt']),
      updatedAt: _parseTs(data['updatedAt']),
    );
  }

  // ------------------------------------------------------------
  // COPY WITH (SAFE PROFILE UPDATES)
  // ------------------------------------------------------------
  UserModel copyWith({
    String? photoUrl,
    String? videoDpUrl,
    String? profileImageUrl,
    String? videoDpThumbUrl,
    String? bio,
    bool? isVerified,
    String? verifiedLabel,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      username: username,
      displayName: displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      videoDpUrl: videoDpUrl ?? this.videoDpUrl,
      videoDpThumbUrl: videoDpThumbUrl ?? this.videoDpThumbUrl,
      bio: bio ?? this.bio,
      role: role,
      type: type,
      isVerified: isVerified ?? this.isVerified,
      verifiedLabel: verifiedLabel ?? this.verifiedLabel,
      isAdmin: isAdmin,
      state: state,
      jurisdictionId: jurisdictionId,
      followersCount: followersCount,
      followingCount: followingCount,
      mutualCount: mutualCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
