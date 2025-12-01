import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String uid;
  final String imageUrl;

  // Repost info
  final bool isRepost;
  final String? originalOwnerUid;
  final String? originalOwnerName;
  final String? repostedByUid;
  final String? repostedByName;

  // Meta
  final DateTime createdAt;

  // Engagement – these are per-user flags (not stored directly in doc)
  int likeCount;
  bool hasLiked;
  bool hasSaved;

  PostModel({
    required this.postId,
    required this.uid,
    required this.imageUrl,
    required this.isRepost,
    this.originalOwnerUid,
    this.originalOwnerName,
    this.repostedByUid,
    this.repostedByName,
    required this.createdAt,
    this.likeCount = 0,
    this.hasLiked = false,
    this.hasSaved = false,
  });

  factory PostModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawCreatedAt = data["createdAt"];
    DateTime created;
    if (rawCreatedAt is Timestamp) {
      created = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      created = rawCreatedAt;
    } else {
      created = DateTime.now();
    }

    return PostModel(
      postId: (data["postId"] as String?) ?? doc.id,
      uid: (data["uid"] as String?) ?? "",
      imageUrl: (data["imageUrl"] as String?) ?? "",
      isRepost: (data["isRepost"] as bool?) ?? false,
      originalOwnerUid: data["originalOwnerUid"] as String?,
      originalOwnerName: data["originalOwnerName"] as String?,
      repostedByUid: data["repostedByUid"] as String?,
      repostedByName: data["repostedByName"] as String?,
      createdAt: created,
      likeCount: (data["likeCount"] as int?) ?? 0,
      // hasLiked/hasSaved are runtime-only flags (not read from Firestore)
      hasLiked: false,
      hasSaved: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "postId": postId,
      "uid": uid,
      "imageUrl": imageUrl,
      "isRepost": isRepost,
      "originalOwnerUid": originalOwnerUid,
      "originalOwnerName": originalOwnerName,
      "repostedByUid": repostedByUid,
      "repostedByName": repostedByName,
      "createdAt": createdAt,
      "likeCount": likeCount,
    };
  }
}
