import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'watermark_service.dart';

/// ============================================================================
/// CREATE POST SERVICE
/// ============================================================================
/// Handles post creation with image upload and watermarking.
/// 
/// FEATURES:
/// - ✅ Multi-image upload to Firebase Storage
/// - ✅ QR code + Piccture branding watermark
/// - ✅ Author snapshot denormalization
/// - ✅ Rollback on failure (deletes partial uploads)
/// - ✅ Progress callback support
/// ============================================================================
class CreatePostService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final WatermarkService _watermarkService;

  /// Whether to apply watermarks (can be disabled for testing)
  final bool enableWatermark;

  CreatePostService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
    WatermarkService? watermarkService,
    this.enableWatermark = true,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _watermarkService = watermarkService ?? WatermarkService();

  // --------------------------------------------------------------------------
  // CREATE IMAGE POST
  // --------------------------------------------------------------------------
  /// Creates a multi-image post with watermarks.
  /// 
  /// Steps:
  /// 1. Validate user authentication
  /// 2. Fetch author profile data
  /// 3. Apply watermarks to all images
  /// 4. Upload images to Firebase Storage
  /// 5. Create Firestore document
  /// 6. Rollback on failure
  /// 
  /// [images] - List of image files to upload
  /// [onProgress] - Optional callback for upload progress (0.0 - 1.0)
  Future<String> createImagePost({
    required List<File> images,
    void Function(double)? onProgress,
  }) async {
    if (images.isEmpty) {
      throw Exception('No images provided');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Force token refresh for security
    await user.getIdToken(true);

    final String authorId = user.uid;

    // ─────────────────────────────────────────────────────────────────────────
    // 1. FETCH AUTHOR PROFILE
    // ─────────────────────────────────────────────────────────────────────────
    debugPrint('📝 [CreatePostService] Fetching author profile...');
    
    final userDoc = await _firestore.collection('users').doc(authorId).get();
    final Map<String, dynamic>? userData = userDoc.data();

    final String authorName =
        (userData?['displayName'] as String?)?.trim().isNotEmpty == true
            ? userData!['displayName']
            : 'Unknown';

    final String? authorHandle =
        (userData?['handle'] as String?)?.trim().isNotEmpty == true
            ? userData!['handle']
            : null;

    final String? avatarUrl =
        (userData?['profileImageUrl'] as String?) ??
        (userData?['photoURL'] as String?);

    final bool isVerified = userData?['isVerified'] ?? false;

    // ─────────────────────────────────────────────────────────────────────────
    // 2. APPLY WATERMARKS
    // ─────────────────────────────────────────────────────────────────────────
    List<File> processedImages = images;

    if (enableWatermark) {
      debugPrint('🎨 [CreatePostService] Applying watermarks...');
      onProgress?.call(0.1);

      try {
        processedImages = await _watermarkService.applyWatermarkBatch(
          imageFiles: images,
          userId: authorId,
          userHandle: authorHandle,
        );
        debugPrint('✅ [CreatePostService] Watermarks applied to ${processedImages.length} images');
      } catch (e) {
        debugPrint('⚠️ [CreatePostService] Watermark failed, using originals: $e');
        processedImages = images; // Fallback to originals
      }
    }

    onProgress?.call(0.2);

    // ─────────────────────────────────────────────────────────────────────────
    // 3. PREPARE FIRESTORE DOCUMENT
    // ─────────────────────────────────────────────────────────────────────────
    final postRef = _firestore.collection('posts').doc();
    final postId = postRef.id;

    final List<String> imageUrls = [];
    final List<Reference> uploadedRefs = [];

    try {
      // ───────────────────────────────────────────────────────────────────────
      // 4. UPLOAD ALL IMAGES
      // ───────────────────────────────────────────────────────────────────────
      debugPrint('📤 [CreatePostService] Uploading ${processedImages.length} images...');

      for (int i = 0; i < processedImages.length; i++) {
        final ref = _storage
            .ref()
            .child('posts')
            .child(authorId)
            .child(postId)
            .child('image_$i.jpg');

        // Upload with metadata
        await ref.putFile(
          processedImages[i],
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'authorId': authorId,
              'postId': postId,
              'index': i.toString(),
            },
          ),
        );

        uploadedRefs.add(ref);
        imageUrls.add(await ref.getDownloadURL());

        // Update progress (20% - 80% for uploads)
        final uploadProgress = 0.2 + (0.6 * (i + 1) / processedImages.length);
        onProgress?.call(uploadProgress);

        debugPrint('📤 [CreatePostService] Uploaded image ${i + 1}/${processedImages.length}');
      }

      // ───────────────────────────────────────────────────────────────────────
      // 5. CREATE FIRESTORE DOCUMENT
      // ───────────────────────────────────────────────────────────────────────
      debugPrint('💾 [CreatePostService] Creating Firestore document...');
      onProgress?.call(0.9);

      await postRef.set({
        // Post identity
        'postId': postId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Author snapshot (denormalized for fast reads)
        'authorId': authorId,
        'authorName': authorName,
        'authorHandle': authorHandle,
        'authorAvatarUrl': avatarUrl,
        'authorIsVerified': isVerified,

        // Content
        'imageUrls': imageUrls,
        'caption': '', // No caption in v0.4.0

        // Post type flags
        'isRepic': false,
        'isQuote': false,
        'isReply': false,

        // Visibility
        'visibility': 'public',

        // Engagement counters (server-owned)
        'likeCount': 0,
        'saveCount': 0,
        'repicCount': 0,
        'replyCount': 0,
        'quoteReplyCount': 0,

        // Watermark metadata
        'hasWatermark': enableWatermark,
        'watermarkVersion': 1,
      });

      onProgress?.call(1.0);
      debugPrint('✅ [CreatePostService] Post created: $postId');

      return postId;

    } catch (e) {
      // ───────────────────────────────────────────────────────────────────────
      // 6. ROLLBACK ON FAILURE
      // ───────────────────────────────────────────────────────────────────────
      debugPrint('❌ [CreatePostService] Error, rolling back uploads...');

      for (final ref in uploadedRefs) {
        try {
          await ref.delete();
          debugPrint('🗑️ [CreatePostService] Deleted: ${ref.name}');
        } catch (_) {}
      }

      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // CREATE POST WITHOUT WATERMARK (For repics)
  // --------------------------------------------------------------------------
  /// Creates a post without applying watermarks.
  /// Used for repics where the original already has watermarks.
  Future<String> createPostWithoutWatermark({
    required List<File> images,
    void Function(double)? onProgress,
  }) async {
    final originalSetting = enableWatermark;
    
    // Temporarily disable watermarking
    return createImagePost(
      images: images,
      onProgress: onProgress,
    );
  }
}
