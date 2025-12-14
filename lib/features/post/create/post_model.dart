import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  // -------------------------
  // CORE IDENTITY
  // -------------------------
  final String postId;
  final String authorId;
  final String authorName;

  // -------------------------
  // VERIFIED / GAZETTER
  // -------------------------
  final bool isVerifiedOwner;

  // -------------------------
  // MEDIA (MULTI-IMAGE)
  // -------------------------
  final List<String> imageUrls;

  // -------------------------
  // POST TYPE
  // -------------------------
  final bool isRepost; // frozen as false for v0.4.0

  // -------------------------
  // TIMESTAMP
  // -------------------------
  final DateTime createdAt;

  // -------------------------
  // ENGAGEMENT COUNTS
  // -------------------------
  int likeCount;
  int replyCount;
  int quoteReplyCount;

  // -------------------------
  // PER-USER FLAGS (CLIENT SIDE)
  // -------------------------
  bool hasLiked;
  bool hasSaved;

  PostModel({
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.isVerifiedOwner,
    required this.imageUrls,
    required this.isRepost,
    required this.createdAt,
    this.likeCount = 0,
    this.replyCount = 0,
    this.quoteReplyCount = 0,
    this.hasLiked = false,
    this.hasSaved = false,
  });

  // -------------------------
  // FIRESTORE → MODEL
  // -------------------------
  factory PostModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawCreatedAt = data['createdAt'];
    final createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : DateTime.now();

    return PostModel(
      postId: data['postId'] ?? doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] as String,
      isVerifiedOwner: data['isVerifiedOwner'] ?? false,
      imageUrls: List<String>.from(data['imageUrls'] ?? const []),
      isRepost: data['isRepost'] ?? false,
      createdAt: createdAt,
      likeCount: data['likeCount'] ?? 0,
      replyCount: data['replyCount'] ?? 0,
      quoteReplyCount: data['quoteReplyCount'] ?? 0,
    );
  }

  // -------------------------
  // SAFE IMAGE ACCESS
  // -------------------------
  List<String> get resolvedImages => imageUrls;
}
