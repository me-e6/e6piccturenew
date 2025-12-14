class UserModel {
  final String uid;
  final String email;
  final String name;
  final String type; // citizen / admin
  final String photoUrl;

  // ✅ Gazetter
  final bool isVerified;
  final String verifiedLabel;

  final List<String> followersList;
  final List<String> followingList;

  final int followersCount;
  final int followingCount;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.type,
    required this.photoUrl,
    required this.isVerified,
    required this.verifiedLabel,
    required this.followersList,
    required this.followingList,
    required this.followersCount,
    required this.followingCount,
  });

  UserModel copyWith({
    String? photoUrl,
    bool? isVerified,
    String? verifiedLabel,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      name: name,
      type: type,
      photoUrl: photoUrl ?? this.photoUrl,
      isVerified: isVerified ?? this.isVerified,
      verifiedLabel: verifiedLabel ?? this.verifiedLabel,
      followersList: followersList,
      followingList: followingList,
      followersCount: followersCount,
      followingCount: followingCount,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map["uid"] ?? "",
      email: map["email"] ?? "",
      name: map["name"] ?? "",
      type: map["type"] ?? "citizen",
      photoUrl: map["photoUrl"] ?? "",
      isVerified: map["isVerified"] ?? false,
      verifiedLabel: map["verifiedLabel"] ?? "",
      followersList: List<String>.from(map["followersList"] ?? []),
      followingList: List<String>.from(map["followingList"] ?? []),
      followersCount: map["followersCount"] ?? 0,
      followingCount: map["followingCount"] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "email": email,
      "name": name,
      "type": type,
      "photoUrl": photoUrl,
      "isVerified": isVerified,
      "verifiedLabel": verifiedLabel,
      "followersList": followersList,
      "followingList": followingList,
      "followersCount": followersCount,
      "followingCount": followingCount,
    };
  }
}
