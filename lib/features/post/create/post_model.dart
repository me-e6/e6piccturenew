import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String uid;

  // MULTI-IMAGE
  final List<String> imageUrls;

  final bool isRepost;
  final String? originalOwnerUid;
  final String? originalOwnerName;
  final String? repostedByUid;
  final String? repostedByName;

  final DateTime createdAt;

  // -------------------------
  // VERIFIED / GAZETTER
  // -------------------------
  final bool isVerifiedOwner;

  // ENGAGEMENT COUNTS
  int likeCount;
  int replyCount;
  int quoteReplyCount;

  // PER-USER FLAGS
  bool hasLiked;
  bool hasSaved;

  PostModel({
    required this.postId,
    required this.uid,
    required this.imageUrls,
    required this.isRepost,
    required this.createdAt,
    required this.isVerifiedOwner,
    this.originalOwnerUid,
    this.originalOwnerName,
    this.repostedByUid,
    this.repostedByName,
    this.likeCount = 0,
    this.replyCount = 0,
    this.quoteReplyCount = 0,
    this.hasLiked = false,
    this.hasSaved = false,
  });

  factory PostModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawCreatedAt = data["createdAt"];
    final created = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : DateTime.now();

    return PostModel(
      postId: data["postId"] ?? doc.id,
      uid: data["uid"] ?? "",
      imageUrls: List<String>.from(data["imageUrls"] ?? []),
      isRepost: data["isRepost"] ?? false,

      // ✅ VERIFIED OWNER
      isVerifiedOwner: data["isVerifiedOwner"] ?? false,

      originalOwnerUid: data["originalOwnerUid"],
      originalOwnerName: data["originalOwnerName"],
      repostedByUid: data["repostedByUid"],
      repostedByName: data["repostedByName"],

      createdAt: created,
      likeCount: data["likeCount"] ?? 0,
      replyCount: data["replyCount"] ?? 0,
      quoteReplyCount: data["quoteReplyCount"] ?? 0,
    );
  }

  // SAFE IMAGE ACCESS
  List<String> get resolvedImages => imageUrls;
}
