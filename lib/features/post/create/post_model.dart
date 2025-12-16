import 'package:cloud_firestore/cloud_firestore.dart';

/// ------------------------------------------------------------
/// POST VISIBILITY (CANONICAL ENUM)
/// ------------------------------------------------------------
/// Stored in Firestore as STRING:
/// "public" | "followers" | "mutuals" | "private"
enum PostVisibility { public, followers, mutuals, private }

/// ------------------------------------------------------------
/// POST MODEL (PRODUCTION-GRADE, DEFENSIVE)
/// ------------------------------------------------------------
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
  // VISIBILITY
  // -------------------------
  final PostVisibility visibility;

  // -------------------------
  // MEDIA (MULTI-IMAGE)
  // -------------------------
  final List<String> imageUrls;

  // -------------------------
  // POST TYPE
  // -------------------------
  final bool isRepost;

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
  // PER-USER FLAGS (CLIENT ONLY)
  // -------------------------
  bool hasLiked;
  bool hasSaved;

  PostModel({
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.isVerifiedOwner,
    required this.visibility,
    required this.imageUrls,
    required this.isRepost,
    required this.createdAt,
    this.likeCount = 0,
    this.replyCount = 0,
    this.quoteReplyCount = 0,
    this.hasLiked = false,
    this.hasSaved = false,
  });

  // ------------------------------------------------------------
  // FIRESTORE → MODEL (DEFENSIVE, NON-BREAKING)
  // ------------------------------------------------------------
  factory PostModel.fromDocument(DocumentSnapshot doc) {
    final raw = doc.data();

    if (raw == null || raw is! Map<String, dynamic>) {
      throw Exception('Invalid post document: ${doc.id}');
    }

    final Map<String, dynamic> data = raw;

    // -------------------------
    // createdAt (DEFENSIVE)
    // -------------------------
    final rawCreatedAt = data['createdAt'];
    final DateTime createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : DateTime.now();

    // -------------------------
    // visibility (BACKWARD-SAFE)
    // -------------------------
    final String visibilityRaw =
        (data['visibility'] as String?)?.toLowerCase() ?? 'public';

    final PostVisibility visibility =
        PostVisibility.values.any((v) => v.name == visibilityRaw)
        ? PostVisibility.values.byName(visibilityRaw)
        : PostVisibility.public;

    return PostModel(
      postId: (data['postId'] as String?) ?? doc.id,

      authorId: (data['authorId'] as String?) ?? '',

      // Never force-cast strings from Firestore
      authorName: (data['authorName'] as String?) ?? 'Unknown',

      isVerifiedOwner: (data['isVerifiedOwner'] as bool?) ?? false,

      visibility: visibility,

      imageUrls:
          (data['imageUrls'] as List?)?.whereType<String>().toList() ??
          const [],

      isRepost: (data['isRepost'] as bool?) ?? false,

      likeCount: (data['likeCount'] as int?) ?? 0,
      replyCount: (data['replyCount'] as int?) ?? 0,
      quoteReplyCount: (data['quoteReplyCount'] as int?) ?? 0,

      createdAt: createdAt,
    );
  }

  // ------------------------------------------------------------
  // COPY WITH — OPTIMISTIC / UI-SAFE
  // ------------------------------------------------------------
  PostModel copyWith({
    int? likeCount,
    int? replyCount,
    int? quoteReplyCount,
    bool? hasLiked,
    bool? hasSaved,
  }) {
    return PostModel(
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      isVerifiedOwner: isVerifiedOwner,
      visibility: visibility,
      imageUrls: imageUrls,
      isRepost: isRepost,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      quoteReplyCount: quoteReplyCount ?? this.quoteReplyCount,
      hasLiked: hasLiked ?? this.hasLiked,
      hasSaved: hasSaved ?? this.hasSaved,
    );
  }

  // ------------------------------------------------------------
  // SAFE IMAGE ACCESS (CAROUSEL-READY)
  // ------------------------------------------------------------
  List<String> get resolvedImages => imageUrls;
}
