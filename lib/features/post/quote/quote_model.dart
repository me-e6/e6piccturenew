import 'package:cloud_firestore/cloud_firestore.dart';

/// ------------------------------------------------------------
/// QUOTED POST PREVIEW (EMBEDDED SNAPSHOT)
/// ------------------------------------------------------------
/// Denormalized snapshot of the original post embedded in the quote.
/// This ensures the quote displays correctly even if the original
/// post is deleted or modified.
/// ------------------------------------------------------------
class QuotedPostPreview {
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorHandle;
  final String? authorAvatarUrl;
  final bool isVerifiedOwner;
  final String? thumbnailUrl;      // First image of original post
  final String? previewText;       // First 50 chars if text post
  final DateTime? originalCreatedAt;

  /// Maximum characters for preview text
  static const int maxPreviewLength = 50;

  QuotedPostPreview({
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorHandle,
    this.authorAvatarUrl,
    required this.isVerifiedOwner,
    this.thumbnailUrl,
    this.previewText,
    this.originalCreatedAt,
  });

  /// Creates preview from a post document snapshot
  factory QuotedPostPreview.fromPostData(Map<String, dynamic> data, String postId) {
    // Extract first image as thumbnail
    final images = (data['imageUrls'] as List?)?.whereType<String>().toList() ?? [];
    final thumbnail = images.isNotEmpty ? images.first : null;

    // Extract and truncate preview text
    String? preview;
    final rawText = data['text'] as String?;
    if (rawText != null && rawText.trim().isNotEmpty) {
      preview = rawText.trim().length > maxPreviewLength
          ? '${rawText.trim().substring(0, maxPreviewLength)}…'
          : rawText.trim();
    }

    // Parse original creation timestamp
    final rawCreatedAt = data['createdAt'];
    final createdAt = rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null;

    return QuotedPostPreview(
      postId: postId,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Unknown',
      authorHandle: data['authorHandle'] as String?,
      authorAvatarUrl: data['authorAvatarUrl'] as String?,
      isVerifiedOwner: data['isVerifiedOwner'] as bool? ?? false,
      thumbnailUrl: thumbnail,
      previewText: preview,
      originalCreatedAt: createdAt,
    );
  }

  /// Creates from Firestore map (when reading quote post)
  factory QuotedPostPreview.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['originalCreatedAt'];
    final createdAt = rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null;

    return QuotedPostPreview(
      postId: map['postId'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Unknown',
      authorHandle: map['authorHandle'] as String?,
      authorAvatarUrl: map['authorAvatarUrl'] as String?,
      isVerifiedOwner: map['isVerifiedOwner'] as bool? ?? false,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      previewText: map['previewText'] as String?,
      originalCreatedAt: createdAt,
    );
  }

  /// Converts to Firestore-safe map for storage
  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorHandle': authorHandle,
      'authorAvatarUrl': authorAvatarUrl,
      'isVerifiedOwner': isVerifiedOwner,
      'thumbnailUrl': thumbnailUrl,
      'previewText': previewText,
      'originalCreatedAt': originalCreatedAt != null
          ? Timestamp.fromDate(originalCreatedAt!)
          : null,
    };
  }

  /// Check if the original post has been deleted
  bool get isOriginalDeleted => postId.isEmpty;

  /// Display-ready author identifier
  String get displayAuthor => authorHandle ?? '@$authorName';
}

/// ------------------------------------------------------------
/// QUOTE POST EXTENSION FIELDS
/// ------------------------------------------------------------
/// These fields extend PostModel when isQuote == true
/// ------------------------------------------------------------
class QuotePostData {
  final bool isQuote;
  final String? quotedPostId;
  final QuotedPostPreview? quotedPreview;
  final String? commentary;         // User's added text (optional)
  final bool isNestedQuote;         // True if quoting another quote

  /// ✅ UPDATED: Maximum commentary length is 30 characters
  /// Short, punchy captions that overlay on the image
  /// Rule: Everything is pictures - quote text becomes visual overlay
  static const int maxCommentaryLength = 30;

  QuotePostData({
    required this.isQuote,
    this.quotedPostId,
    this.quotedPreview,
    this.commentary,
    this.isNestedQuote = false,
  });

  factory QuotePostData.fromMap(Map<String, dynamic> data) {
    final quotedPreviewRaw = data['quotedPreview'] as Map<String, dynamic>?;

    return QuotePostData(
      isQuote: data['isQuote'] as bool? ?? false,
      quotedPostId: data['quotedPostId'] as String?,
      quotedPreview: quotedPreviewRaw != null
          ? QuotedPostPreview.fromMap(quotedPreviewRaw)
          : null,
      commentary: data['commentary'] as String?,
      isNestedQuote: data['isNestedQuote'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isQuote': isQuote,
      'quotedPostId': quotedPostId,
      'quotedPreview': quotedPreview?.toMap(),
      'commentary': commentary,
      'isNestedQuote': isNestedQuote,
    };
  }

  /// Validates commentary length
  static String? validateCommentary(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    if (text.length > maxCommentaryLength) {
      return 'Caption must be $maxCommentaryLength characters or less';
    }
    return null;
  }
}

/// ------------------------------------------------------------
/// QUOTE VALIDATION RESULT
/// ------------------------------------------------------------
enum QuoteValidationError {
  none,
  emptyPost,
  cannotQuoteOwnPost,
  cannotQuoteQuote,      // Prevents nested quotes
  postNotFound,
  postDeleted,
  postPrivate,
  alreadyQuoted,         // User already quoted this post
}

class QuoteValidationResult {
  final bool isValid;
  final QuoteValidationError error;
  final String? message;

  const QuoteValidationResult._({
    required this.isValid,
    this.error = QuoteValidationError.none,
    this.message,
  });

  factory QuoteValidationResult.valid() {
    return const QuoteValidationResult._(isValid: true);
  }

  factory QuoteValidationResult.invalid(QuoteValidationError error, String message) {
    return QuoteValidationResult._(
      isValid: false,
      error: error,
      message: message,
    );
  }
}
