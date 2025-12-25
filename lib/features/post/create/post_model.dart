import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================================
/// POST MODEL - CANONICAL
/// ============================================================================
/// Supports:
/// - Regular posts (photos with captions)
/// - Quote posts (isQuote=true, references original)
/// - Repic posts (isRepic=true, references original)
/// ============================================================================
class PostModel {
  // --------------------------------------------------------------------------
  // CORE FIELDS
  // --------------------------------------------------------------------------
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorHandle;
  final String? authorAvatarUrl;
  final bool authorIsVerified;

  final List<String> imageUrls;
  final String caption;
  final DateTime createdAt;

  // --------------------------------------------------------------------------
  // ENGAGEMENT COUNTERS
  // --------------------------------------------------------------------------
  final int likeCount;
  final int saveCount;
  final int repicCount;
  final int replyCount;
  final int quoteReplyCount;

  // --------------------------------------------------------------------------
  // USER ENGAGEMENT STATE (hydrated per-user)
  // --------------------------------------------------------------------------
  final bool hasLiked;
  final bool hasSaved;
  final bool hasRepicced;

  // --------------------------------------------------------------------------
  // QUOTE POST FIELDS
  // --------------------------------------------------------------------------
  final bool isQuote;
  final String? quotedPostId;
  final Map<String, dynamic>? quotedPreview;
  final String? commentary;

  // --------------------------------------------------------------------------
  // REPIC POST FIELDS (NEW)
  // --------------------------------------------------------------------------
  final bool isRepic;
  final String? originalPostId;
  final Map<String, dynamic>? originalPost;
  
  // Who created the repic (for "User repicced" header)
  final String? repicAuthorId;
  final String? repicAuthorName;
  final String? repicAuthorHandle;
  final String? repicAuthorAvatarUrl;
  final bool repicAuthorIsVerified;

  PostModel({
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorHandle,
    this.authorAvatarUrl,
    this.authorIsVerified = false,
    required this.imageUrls,
    required this.caption,
    required this.createdAt,
    this.likeCount = 0,
    this.saveCount = 0,
    this.repicCount = 0,
    this.replyCount = 0,
    this.quoteReplyCount = 0,
    this.hasLiked = false,
    this.hasSaved = false,
    this.hasRepicced = false,
    // Quote fields
    this.isQuote = false,
    this.quotedPostId,
    this.quotedPreview,
    this.commentary,
    // Repic fields
    this.isRepic = false,
    this.originalPostId,
    this.originalPost,
    this.repicAuthorId,
    this.repicAuthorName,
    this.repicAuthorHandle,
    this.repicAuthorAvatarUrl,
    this.repicAuthorIsVerified = false,
  });

  // --------------------------------------------------------------------------
  // FIRESTORE → MODEL
  // --------------------------------------------------------------------------
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    List<String> parseImageUrls(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    return PostModel(
      postId: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? data['displayName'] ?? 'Unknown',
      authorHandle: data['authorHandle'] ?? data['handle'] ?? data['username'],
      authorAvatarUrl: data['authorAvatarUrl'] ?? data['authorPhotoUrl'] ?? data['photoUrl'],
      authorIsVerified: data['authorIsVerified'] ?? data['isVerified'] ?? false,
      imageUrls: parseImageUrls(data['imageUrls'] ?? data['images']),
      caption: data['caption'] ?? data['text'] ?? '',
      createdAt: parseTimestamp(data['createdAt']),
      
      // Counters
      likeCount: data['likeCount'] ?? 0,
      saveCount: data['saveCount'] ?? 0,
      repicCount: data['repicCount'] ?? 0,
      replyCount: data['replyCount'] ?? data['commentCount'] ?? 0,
      quoteReplyCount: data['quoteReplyCount'] ?? data['quoteCount'] ?? 0,
      
      // User state (hydrated separately)
      hasLiked: data['hasLiked'] ?? false,
      hasSaved: data['hasSaved'] ?? false,
      hasRepicced: data['hasRepicced'] ?? false,
      
      // Quote fields (backward compatible)
      isQuote: data['isQuote'] ?? false,
      quotedPostId: data['quotedPostId'] ?? data['originalPostId'],
      quotedPreview: data['quotedPreview'] ?? data['originalPost'] ?? data['quotedPost'],
      commentary: data['commentary'] ?? data['quoteText'] ?? data['caption'],
      
      // Repic fields
      isRepic: data['isRepic'] ?? false,
      originalPostId: data['originalPostId'],
      originalPost: data['originalPost'],
      repicAuthorId: data['repicAuthorId'],
      repicAuthorName: data['repicAuthorName'],
      repicAuthorHandle: data['repicAuthorHandle'],
      repicAuthorAvatarUrl: data['repicAuthorAvatarUrl'],
      repicAuthorIsVerified: data['repicAuthorIsVerified'] ?? false,
    );
  }

  // --------------------------------------------------------------------------
  // MODEL → FIRESTORE
  // --------------------------------------------------------------------------
  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorHandle': authorHandle,
      'authorAvatarUrl': authorAvatarUrl,
      'authorIsVerified': authorIsVerified,
      'imageUrls': imageUrls,
      'caption': caption,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
      'saveCount': saveCount,
      'repicCount': repicCount,
      'replyCount': replyCount,
      'quoteReplyCount': quoteReplyCount,
      // Quote fields
      'isQuote': isQuote,
      if (quotedPostId != null) 'quotedPostId': quotedPostId,
      if (quotedPreview != null) 'quotedPreview': quotedPreview,
      if (commentary != null) 'commentary': commentary,
      // Repic fields
      'isRepic': isRepic,
      if (originalPostId != null) 'originalPostId': originalPostId,
      if (originalPost != null) 'originalPost': originalPost,
      if (repicAuthorId != null) 'repicAuthorId': repicAuthorId,
      if (repicAuthorName != null) 'repicAuthorName': repicAuthorName,
      if (repicAuthorHandle != null) 'repicAuthorHandle': repicAuthorHandle,
      if (repicAuthorAvatarUrl != null) 'repicAuthorAvatarUrl': repicAuthorAvatarUrl,
      'repicAuthorIsVerified': repicAuthorIsVerified,
    };
  }

  // --------------------------------------------------------------------------
  // COPY WITH
  // --------------------------------------------------------------------------
  PostModel copyWith({
    String? postId,
    String? authorId,
    String? authorName,
    String? authorHandle,
    String? authorAvatarUrl,
    bool? authorIsVerified,
    List<String>? imageUrls,
    String? caption,
    DateTime? createdAt,
    int? likeCount,
    int? saveCount,
    int? repicCount,
    int? replyCount,
    int? quoteReplyCount,
    bool? hasLiked,
    bool? hasSaved,
    bool? hasRepicced,
    // Quote
    bool? isQuote,
    String? quotedPostId,
    Map<String, dynamic>? quotedPreview,
    String? commentary,
    // Repic
    bool? isRepic,
    String? originalPostId,
    Map<String, dynamic>? originalPost,
    String? repicAuthorId,
    String? repicAuthorName,
    String? repicAuthorHandle,
    String? repicAuthorAvatarUrl,
    bool? repicAuthorIsVerified,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorHandle: authorHandle ?? this.authorHandle,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorIsVerified: authorIsVerified ?? this.authorIsVerified,
      imageUrls: imageUrls ?? this.imageUrls,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      saveCount: saveCount ?? this.saveCount,
      repicCount: repicCount ?? this.repicCount,
      replyCount: replyCount ?? this.replyCount,
      quoteReplyCount: quoteReplyCount ?? this.quoteReplyCount,
      hasLiked: hasLiked ?? this.hasLiked,
      hasSaved: hasSaved ?? this.hasSaved,
      hasRepicced: hasRepicced ?? this.hasRepicced,
      // Quote
      isQuote: isQuote ?? this.isQuote,
      quotedPostId: quotedPostId ?? this.quotedPostId,
      quotedPreview: quotedPreview ?? this.quotedPreview,
      commentary: commentary ?? this.commentary,
      // Repic
      isRepic: isRepic ?? this.isRepic,
      originalPostId: originalPostId ?? this.originalPostId,
      originalPost: originalPost ?? this.originalPost,
      repicAuthorId: repicAuthorId ?? this.repicAuthorId,
      repicAuthorName: repicAuthorName ?? this.repicAuthorName,
      repicAuthorHandle: repicAuthorHandle ?? this.repicAuthorHandle,
      repicAuthorAvatarUrl: repicAuthorAvatarUrl ?? this.repicAuthorAvatarUrl,
      repicAuthorIsVerified: repicAuthorIsVerified ?? this.repicAuthorIsVerified,
    );
  }

  // --------------------------------------------------------------------------
  // HELPERS
  // --------------------------------------------------------------------------
  
  /// True if this is a quote post with content
  bool get hasQuotedContent =>
      isQuote && (quotedPostId != null || quotedPreview != null);

  /// True if this is a repic post with original
  bool get hasOriginalPost =>
      isRepic && (originalPostId != null || originalPost != null);

  /// Get thumbnail URL from quoted preview
  String? get quotedThumbnailUrl {
    if (quotedPreview == null) return null;
    return quotedPreview!['thumbnailUrl'] as String? ??
        quotedPreview!['imageUrl'] as String?;
  }

  /// Get author name from quoted preview
  String? get quotedAuthorName {
    if (quotedPreview == null) return null;
    return quotedPreview!['authorName'] as String? ??
        quotedPreview!['displayName'] as String?;
  }

  /// Get thumbnail URL from original post (repic)
  String? get originalThumbnailUrl {
    if (originalPost == null) return null;
    final images = originalPost!['imageUrls'] as List?;
    if (images != null && images.isNotEmpty) {
      return images.first as String?;
    }
    return originalPost!['thumbnailUrl'] as String?;
  }

  /// Get author name from original post (repic)
  String? get originalAuthorName {
    if (originalPost == null) return null;
    return originalPost!['authorName'] as String? ??
        originalPost!['displayName'] as String?;
  }

  /// Get image URLs from original post (repic)
  List<String> get originalImageUrls {
    if (originalPost == null) return [];
    final images = originalPost!['imageUrls'];
    if (images is List) {
      return images.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Get caption from original post (repic)
  String get originalCaption {
    if (originalPost == null) return '';
    return originalPost!['caption'] as String? ?? '';
  }
}
