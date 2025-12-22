import 'package:cloud_firestore/cloud_firestore.dart';

/// ------------------------------------------------------------
/// POST VISIBILITY (CANONICAL ENUM)
/// ------------------------------------------------------------
/// Stored in Firestore as STRING:
///
/// "public" | "followers" | "mutuals" | "private"
enum PostVisibility { public, followers, mutuals, private } // --Futre Plan

enum ImpactReason {
  // Future Plan
  highLikes,
  highReplies,
  highRepics,
  gazetterAcknowledged,
  communityAcknowledged,
}

/// ------------------------------------------------------------
/// POST MODEL (API-READY, DENORMALIZED, SAFE)
/// ------------------------------------------------------------
/// Design principles:
/// - Flat author snapshot (NO nested user objects)
/// - Defensive Firestore parsing
/// - Client-safe mutable engagement flags
/// - Ready for REST / GraphQL mapping later
class PostModel {
  // -------------------------
  // CORE IDENTITY
  // -------------------------
  final String postId;

  // -------------------------
  // AUTHOR SNAPSHOT (DENORMALIZED)
  // -------------------------
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
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
  // ENGAGEMENT COUNTS (SERVER-OWNED)
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
    this.authorAvatarUrl,
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

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();

    if (raw == null || raw is! Map<String, dynamic>) {
      throw StateError('Post document ${doc.id} has invalid data');
    }

    final Map<String, dynamic> data = raw;

    // createdAt (safe)
    final rawCreatedAt = data['createdAt'];
    final DateTime createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : DateTime.now();

    // visibility (backward-safe)
    final String visibilityRaw =
        (data['visibility'] as String?)?.toLowerCase() ?? 'public';

    final PostVisibility visibility =
        PostVisibility.values.any((v) => v.name == visibilityRaw)
        ? PostVisibility.values.byName(visibilityRaw)
        : PostVisibility.public;

    // authorName (immutable snapshot, backward-safe)
    final String authorName =
        (data['authorName'] as String?)?.trim().isNotEmpty == true
        ? data['authorName'] as String
        : (data['displayName'] as String?) ?? 'Unknown';

    return PostModel(
      postId: data['postId'] as String? ?? doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: authorName,
      authorAvatarUrl: data['authorAvatarUrl'] as String?,
      isVerifiedOwner: data['isVerifiedOwner'] as bool? ?? false,
      visibility: visibility,
      imageUrls:
          (data['imageUrls'] as List?)?.whereType<String>().toList() ??
          const [],
      isRepost: data['isRepost'] as bool? ?? false,
      createdAt: createdAt,
      likeCount: data['likeCount'] as int? ?? 0,
      replyCount: data['replyCount'] as int? ?? 0,
      quoteReplyCount: data['quoteReplyCount'] as int? ?? 0,
    );
  }

  // ------------------------------------------------------------
  // COPY WITH — OPTIMISTIC UI SAFE
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
      authorAvatarUrl: authorAvatarUrl,
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

  // ------------------------------------------------------------
  // IMPACT EXPLANATION (CLIENT-DERIVED, API-READY) ---Future Plan
  // ------------------------------------------------------------
  List<ImpactReason> get impactReasons {
    final reasons = <ImpactReason>[];

    if (likeCount >= 50) {
      reasons.add(ImpactReason.highLikes);
    }

    if (replyCount >= 10) {
      reasons.add(ImpactReason.highReplies);
    }

    if (quoteReplyCount >= 5) {
      reasons.add(ImpactReason.highRepics);
    }

    if (isVerifiedOwner) {
      reasons.add(ImpactReason.gazetterAcknowledged);
    }

    // future: civic acknowledgement
    // if (acknowledgedByCitizens) ...

    return reasons;
  }

  bool get isImpact => impactReasons.isNotEmpty;
}
