import 'package:cloud_firestore/cloud_firestore.dart';

/// ------------------------------------------------------------
/// POST VISIBILITY (CANONICAL ENUM)
/// ------------------------------------------------------------
enum PostVisibility { public, followers, mutuals, private }

/// ------------------------------------------------------------
/// POST MODEL (DENORMALIZED, COUNTER-FIRST, SAFE)
/// ------------------------------------------------------------
/// ✅ UPDATED: Now includes Quote Post fields
/// ------------------------------------------------------------
class PostModel {
  // -------------------------
  // CORE IDENTITY
  // -------------------------
  final String postId;

  // -------------------------
  // AUTHOR SNAPSHOT
  // -------------------------
  final String authorId;
  final String authorName;
  final String? authorHandle;
  final String? authorAvatarUrl;
  final bool isVerifiedOwner;

  // -------------------------
  // VISIBILITY
  // -------------------------
  final PostVisibility visibility;

  // -------------------------
  // MEDIA
  // -------------------------
  final List<String> imageUrls;

  // -------------------------
  // POST TYPE
  // -------------------------
  final bool isRepost;

  // -------------------------
  // ✅ QUOTE FIELDS (NEW)
  // -------------------------
  final bool isQuote;
  final String? quotedPostId;
  final Map<String, dynamic>? quotedPreview;
  final String? commentary;

  // -------------------------
  // TIMESTAMP
  // -------------------------
  final DateTime createdAt;

  // -------------------------
  // ENGAGEMENT COUNTERS (SERVER OWNED)
  // -------------------------
  int likeCount;
  int saveCount;
  int repicCount;
  int replyCount;
  int quoteReplyCount;

  // -------------------------
  // PER-USER FLAGS (CLIENT SNAPSHOT)
  // -------------------------
  bool hasLiked;
  bool hasSaved;
  bool hasRepicced;

  PostModel({
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorHandle,
    this.authorAvatarUrl,
    required this.isVerifiedOwner,
    required this.visibility,
    required this.imageUrls,
    required this.isRepost,
    required this.createdAt,
    // Quote fields
    this.isQuote = false,
    this.quotedPostId,
    this.quotedPreview,
    this.commentary,
    // Counters
    this.likeCount = 0,
    this.saveCount = 0,
    this.repicCount = 0,
    this.replyCount = 0,
    this.quoteReplyCount = 0,
    // User flags
    this.hasLiked = false,
    this.hasSaved = false,
    this.hasRepicced = false,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();

    if (raw == null || raw is! Map<String, dynamic>) {
      throw StateError('Post document ${doc.id} has invalid data');
    }

    final data = raw;

    final rawCreatedAt = data['createdAt'];
    final createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : DateTime.now();

    final visibilityRaw =
        (data['visibility'] as String?)?.toLowerCase() ?? 'public';

    final visibility = PostVisibility.values.any((v) => v.name == visibilityRaw)
        ? PostVisibility.values.byName(visibilityRaw)
        : PostVisibility.public;

    final authorName =
        (data['authorName'] as String?)?.trim().isNotEmpty == true
        ? data['authorName']
        : (data['displayName'] as String?) ?? 'Unknown';

    return PostModel(
      postId: data['postId'] as String? ?? doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: authorName,
      authorHandle: data['authorHandle'] as String?,
      authorAvatarUrl: data['authorAvatarUrl'] as String?,
      isVerifiedOwner: data['isVerifiedOwner'] as bool? ?? false,
      visibility: visibility,
      imageUrls:
          (data['imageUrls'] as List?)?.whereType<String>().toList() ??
          const [],
      isRepost: data['isRepost'] as bool? ?? false,
      createdAt: createdAt,

      // ✅ QUOTE FIELDS (checks multiple possible field names for compatibility)
      isQuote:
          data['isQuote'] as bool? ??
          data['isQuotePost'] as bool? ??
          (data['quotedPostId'] != null) ||
              (data['originalPostId'] != null) ||
              false,
      quotedPostId:
          data['quotedPostId'] as String? ?? data['originalPostId'] as String?,
      quotedPreview:
          data['quotedPreview'] as Map<String, dynamic>? ??
          data['originalPost'] as Map<String, dynamic>? ??
          data['quotedPost'] as Map<String, dynamic>?,
      commentary:
          data['commentary'] as String? ??
          data['quoteText'] as String? ??
          data['caption'] as String?,

      // Counters
      likeCount: data['likeCount'] as int? ?? 0,
      saveCount: data['saveCount'] as int? ?? 0,
      repicCount: data['repicCount'] as int? ?? 0,
      replyCount: data['replyCount'] as int? ?? 0,
      quoteReplyCount: data['quoteReplyCount'] as int? ?? 0,
    );
  }

  // ------------------------------------------------------------
  // COPY WITH — OPTIMISTIC UI SAFE
  // ------------------------------------------------------------
  PostModel copyWith({
    int? likeCount,
    int? saveCount,
    int? repicCount,
    int? replyCount,
    int? quoteReplyCount,
    bool? hasLiked,
    bool? hasSaved,
    bool? hasRepicced,
  }) {
    return PostModel(
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorHandle: authorHandle,
      authorAvatarUrl: authorAvatarUrl,
      isVerifiedOwner: isVerifiedOwner,
      visibility: visibility,
      imageUrls: imageUrls,
      isRepost: isRepost,
      createdAt: createdAt,
      // Quote fields (preserved)
      isQuote: isQuote,
      quotedPostId: quotedPostId,
      quotedPreview: quotedPreview,
      commentary: commentary,
      // Counters (can be updated)
      likeCount: likeCount ?? this.likeCount,
      saveCount: saveCount ?? this.saveCount,
      repicCount: repicCount ?? this.repicCount,
      replyCount: replyCount ?? this.replyCount,
      quoteReplyCount: quoteReplyCount ?? this.quoteReplyCount,
      // User flags (can be updated)
      hasLiked: hasLiked ?? this.hasLiked,
      hasSaved: hasSaved ?? this.hasSaved,
      hasRepicced: hasRepicced ?? this.hasRepicced,
    );
  }

  // ------------------------------------------------------------
  // DERIVED HELPERS
  // ------------------------------------------------------------

  List<String> get resolvedImages => imageUrls;

  String? get thumbnailUrl {
    if (imageUrls.isEmpty) return null;
    return imageUrls.first;
  }

  /// Check if this is a quote post
  bool get hasQuotedContent => isQuote && quotedPreview != null;

  /// Get the quoted post's thumbnail (if available)
  String? get quotedThumbnailUrl {
    if (!isQuote || quotedPreview == null) return null;
    return quotedPreview!['thumbnailUrl'] as String?;
  }

  /// Get the quoted post's author name
  String get quotedAuthorName {
    if (!isQuote || quotedPreview == null) return 'Unknown';
    return quotedPreview!['authorName'] as String? ?? 'Unknown';
  }
}

/// ------------------------------------------------------------
/// DERIVED MEDIA HELPERS (UI SAFE)
/// ------------------------------------------------------------
