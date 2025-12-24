import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'quote_model.dart';

/// ------------------------------------------------------------
/// QUOTE SERVICE
/// ------------------------------------------------------------
/// Handles all Firebase operations for the Quote System.
/// 
/// Architecture:
/// - Quotes are stored as independent posts with isQuote: true
/// - Original post's quoteReplyCount is incremented transactionally
/// - Quoted post preview is denormalized for display performance
/// - Nested quotes are prevented (can't quote a quote)
/// ------------------------------------------------------------
class QuoteService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  QuoteService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ------------------------------------------------------------
  // GETTERS
  // ------------------------------------------------------------
  
  String? get _currentUid => _auth.currentUser?.uid;
  
  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _firestore.collection('posts');
  
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  // ------------------------------------------------------------
  // VALIDATION
  // ------------------------------------------------------------

  /// Validates if a post can be quoted by the current user
  Future<QuoteValidationResult> validateQuote(String postId) async {
    final uid = _currentUid;
    if (uid == null) {
      return QuoteValidationResult.invalid(
        QuoteValidationError.emptyPost,
        'You must be logged in to quote a post',
      );
    }

    try {
      final postDoc = await _postsRef.doc(postId).get();

      // Check if post exists
      if (!postDoc.exists) {
        return QuoteValidationResult.invalid(
          QuoteValidationError.postNotFound,
          'This post no longer exists',
        );
      }

      final data = postDoc.data()!;

      // Check if post is deleted (soft delete)
      if (data['isDeleted'] == true) {
        return QuoteValidationResult.invalid(
          QuoteValidationError.postDeleted,
          'This post has been deleted',
        );
      }

      // Prevent quoting own posts (optional - remove if you want to allow)
      // if (data['authorId'] == uid) {
      //   return QuoteValidationResult.invalid(
      //     QuoteValidationError.cannotQuoteOwnPost,
      //     'You cannot quote your own post',
      //   );
      // }

      // Prevent nested quotes (quoting a quote)
      if (data['isQuote'] == true) {
        return QuoteValidationResult.invalid(
          QuoteValidationError.cannotQuoteQuote,
          'You cannot quote a quote. Quote the original post instead.',
        );
      }

      // Check visibility restrictions
      final visibility = data['visibility'] as String? ?? 'public';
      if (visibility == 'private') {
        return QuoteValidationResult.invalid(
          QuoteValidationError.postPrivate,
          'This post is private and cannot be quoted',
        );
      }

      // Check if user already quoted this post (optional duplicate prevention)
      final existingQuote = await _postsRef
          .where('authorId', isEqualTo: uid)
          .where('isQuote', isEqualTo: true)
          .where('quotedPostId', isEqualTo: postId)
          .limit(1)
          .get();

      if (existingQuote.docs.isNotEmpty) {
        return QuoteValidationResult.invalid(
          QuoteValidationError.alreadyQuoted,
          'You have already quoted this post',
        );
      }

      return QuoteValidationResult.valid();
    } catch (e) {
      return QuoteValidationResult.invalid(
        QuoteValidationError.postNotFound,
        'Error validating post: $e',
      );
    }
  }

  // ------------------------------------------------------------
  // CREATE QUOTE
  // ------------------------------------------------------------

  /// Creates a quote post with full transaction safety
  /// 
  /// Transaction ensures:
  /// 1. Original post exists and is quotable
  /// 2. Quote post is created
  /// 3. Original post's quoteReplyCount is incremented
  /// 4. User's quote index is updated
  /// 
  /// Returns the new quote post ID on success
  Future<String> createQuote({
    required String originalPostId,
    String? commentary,
  }) async {
    final uid = _currentUid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    // Force token refresh for security
    await _auth.currentUser!.getIdToken(true);

    // Validate first
    final validation = await validateQuote(originalPostId);
    if (!validation.isValid) {
      throw Exception(validation.message ?? 'Cannot quote this post');
    }

    // Trim and validate commentary
    final trimmedCommentary = commentary?.trim();
    if (trimmedCommentary != null && trimmedCommentary.length > QuotePostData.maxCommentaryLength) {
      throw Exception('Commentary exceeds ${QuotePostData.maxCommentaryLength} characters');
    }

    // Get current user data for author snapshot
    final userDoc = await _usersRef.doc(uid).get();
    final userData = userDoc.data();

    final authorName = (userData?['displayName'] as String?)?.trim().isNotEmpty == true
        ? userData!['displayName']
        : 'Unknown';
    final authorHandle = (userData?['handle'] as String?)?.trim().isNotEmpty == true
        ? userData!['handle']
        : null;
    final authorAvatarUrl = (userData?['profileImageUrl'] as String?) ??
        (userData?['photoURL'] as String?);
    final isVerified = userData?['isVerified'] as bool? ?? false;

    // Generate new post ID
    final quotePostRef = _postsRef.doc();
    final quotePostId = quotePostRef.id;

    // Run transaction
    await _firestore.runTransaction((transaction) async {
      // 1. Read original post
      final originalPostDoc = await transaction.get(_postsRef.doc(originalPostId));
      
      if (!originalPostDoc.exists) {
        throw Exception('Original post not found');
      }

      final originalData = originalPostDoc.data()!;

      // 2. Create quoted preview snapshot
      final quotedPreview = QuotedPostPreview.fromPostData(originalData, originalPostId);

      // 3. Build quote post document
      final quotePostData = {
        // Core identity
        'postId': quotePostId,
        'authorId': uid,
        'authorName': authorName,
        'authorHandle': authorHandle,
        'authorAvatarUrl': authorAvatarUrl,
        'isVerifiedOwner': isVerified,

        // Quote-specific fields
        'isQuote': true,
        'quotedPostId': originalPostId,
        'quotedPreview': quotedPreview.toMap(),
        'commentary': trimmedCommentary,
        'isNestedQuote': false,

        // Standard post fields
        'imageUrls': <String>[],  // Quote posts don't have their own images
        'isRepost': false,
        'visibility': 'public',
        'createdAt': FieldValue.serverTimestamp(),

        // Engagement counters (quote posts can be liked, replied to, etc.)
        'likeCount': 0,
        'saveCount': 0,
        'repicCount': 0,
        'replyCount': 0,
        'quoteReplyCount': 0,
      };

      // 4. Write quote post
      transaction.set(quotePostRef, quotePostData);

      // 5. Increment original post's quote counter
      transaction.update(_postsRef.doc(originalPostId), {
        'quoteReplyCount': FieldValue.increment(1),
      });

      // 6. Index quote in user's quotes collection (for profile "Quotes" tab)
      final userQuoteRef = _usersRef
          .doc(uid)
          .collection('quoted_posts')
          .doc(quotePostId);
      
      transaction.set(userQuoteRef, {
        'quotePostId': quotePostId,
        'originalPostId': originalPostId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return quotePostId;
  }

  // ------------------------------------------------------------
  // DELETE QUOTE
  // ------------------------------------------------------------

  /// Deletes a quote post and decrements the original's counter
  Future<void> deleteQuote(String quotePostId) async {
    final uid = _currentUid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.runTransaction((transaction) async {
      // 1. Read quote post
      final quoteDoc = await transaction.get(_postsRef.doc(quotePostId));
      
      if (!quoteDoc.exists) {
        throw Exception('Quote post not found');
      }

      final quoteData = quoteDoc.data()!;

      // Verify ownership
      if (quoteData['authorId'] != uid) {
        throw Exception('You can only delete your own quotes');
      }

      // Verify it's actually a quote
      if (quoteData['isQuote'] != true) {
        throw Exception('This is not a quote post');
      }

      final originalPostId = quoteData['quotedPostId'] as String?;

      // 2. Delete quote post
      transaction.delete(_postsRef.doc(quotePostId));

      // 3. Decrement original post's counter (if original exists)
      if (originalPostId != null) {
        final originalDoc = await transaction.get(_postsRef.doc(originalPostId));
        if (originalDoc.exists) {
          final currentCount = originalDoc.data()?['quoteReplyCount'] as int? ?? 0;
          transaction.update(_postsRef.doc(originalPostId), {
            'quoteReplyCount': currentCount > 0 ? FieldValue.increment(-1) : 0,
          });
        }
      }

      // 4. Remove from user's quotes index
      final userQuoteRef = _usersRef
          .doc(uid)
          .collection('quoted_posts')
          .doc(quotePostId);
      transaction.delete(userQuoteRef);
    });
  }

  // ------------------------------------------------------------
  // FETCH QUOTES
  // ------------------------------------------------------------

  /// Stream of quotes for a specific post (real-time)
  Stream<List<DocumentSnapshot>> streamQuotesForPost(String postId) {
    return _postsRef
        .where('isQuote', isEqualTo: true)
        .where('quotedPostId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  /// Stream of user's quotes (for profile "Quotes" tab)
  Stream<List<DocumentSnapshot>> streamUserQuotes(String userId) {
    return _postsRef
        .where('authorId', isEqualTo: userId)
        .where('isQuote', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  /// Fetch quotes for a post (one-time)
  Future<List<DocumentSnapshot>> fetchQuotesForPost(String postId, {int limit = 20}) async {
    final snap = await _postsRef
        .where('isQuote', isEqualTo: true)
        .where('quotedPostId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs;
  }

  /// Get quote count for a post (real-time stream)
  Stream<int> streamQuoteCount(String postId) {
    return _postsRef.doc(postId).snapshots().map((doc) {
      return doc.data()?['quoteReplyCount'] as int? ?? 0;
    });
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  /// Check if current user has quoted a post
  Future<bool> hasUserQuotedPost(String postId) async {
    final uid = _currentUid;
    if (uid == null) return false;

    final snap = await _postsRef
        .where('authorId', isEqualTo: uid)
        .where('isQuote', isEqualTo: true)
        .where('quotedPostId', isEqualTo: postId)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  /// Get the quote post ID if user has quoted
  Future<String?> getUserQuotePostId(String postId) async {
    final uid = _currentUid;
    if (uid == null) return null;

    final snap = await _postsRef
        .where('authorId', isEqualTo: uid)
        .where('isQuote', isEqualTo: true)
        .where('quotedPostId', isEqualTo: postId)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty ? snap.docs.first.id : null;
  }
}
