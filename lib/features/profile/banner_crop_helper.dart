import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '.././post/create/image_crop_service.dart';

/// ============================================================================
/// BANNER CROP HELPER
/// ============================================================================
/// Helper class for picking and cropping profile banners.
///
/// Usage:
/// ```dart
/// final bannerPath = await BannerCropHelper.pickAndCropBanner(context);
/// if (bannerPath != null) {
///   // Upload banner
/// }
/// ```
/// ============================================================================
class BannerCropHelper {
  static final ImagePicker _picker = ImagePicker();
  static final ImageCropService _cropService = ImageCropService();

  // --------------------------------------------------------------------------
  // PICK AND CROP BANNER
  // --------------------------------------------------------------------------
  /// Opens gallery to pick an image, then crops it for banner (16:9).
  ///
  /// Returns the cropped file path, or null if cancelled.
  static Future<String?> pickAndCropBanner(BuildContext context) async {
    try {
      // Pick image
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1080,
        requestFullMetadata: false,
      );

      if (image == null) {
        debugPrint('📷 [BannerCropHelper] User cancelled picker');
        return null;
      }

      // Validate file
      if (image.path.isEmpty || !File(image.path).existsSync()) {
        debugPrint('❌ [BannerCropHelper] Invalid file path');
        return null;
      }

      // Crop for banner (16:9)
      final croppedPath = await _cropService.cropForBanner(
        imagePath: image.path,
        context: context,
      );

      if (croppedPath != null) {
        debugPrint('✅ [BannerCropHelper] Banner cropped: $croppedPath');
      }

      return croppedPath;
    } catch (e) {
      debugPrint('❌ [BannerCropHelper] Error: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // PICK AND CROP PROFILE PICTURE
  // --------------------------------------------------------------------------
  /// Opens gallery to pick an image, then crops it for profile picture (1:1).
  ///
  /// Returns the cropped file path, or null if cancelled.
  static Future<String?> pickAndCropProfilePicture(BuildContext context) async {
    try {
      // Pick image
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 800,
        maxHeight: 800,
        requestFullMetadata: false,
      );

      if (image == null) {
        debugPrint('📷 [BannerCropHelper] User cancelled picker');
        return null;
      }

      // Validate file
      if (image.path.isEmpty || !File(image.path).existsSync()) {
        debugPrint('❌ [BannerCropHelper] Invalid file path');
        return null;
      }

      // Crop for profile picture (1:1 circle)
      final croppedPath = await _cropService.cropForProfilePicture(
        imagePath: image.path,
        context: context,
      );

      if (croppedPath != null) {
        debugPrint(
          '✅ [BannerCropHelper] Profile picture cropped: $croppedPath',
        );
      }

      return croppedPath;
    } catch (e) {
      debugPrint('❌ [BannerCropHelper] Error: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // SHOW SOURCE DIALOG + CROP
  // --------------------------------------------------------------------------
  /// Shows a dialog to choose camera/gallery, then crops for the specified type.
  static Future<String?> pickWithSourceAndCrop(
    BuildContext context, {
    required CropType cropType,
  }) async {
    // Show source selection dialog
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return null;

    try {
      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: cropType == CropType.banner ? 1920 : 800,
        maxHeight: cropType == CropType.banner ? 1080 : 800,
        requestFullMetadata: false,
      );

      if (image == null || image.path.isEmpty) return null;

      // Crop based on type
      switch (cropType) {
        case CropType.banner:
          return await _cropService.cropForBanner(
            imagePath: image.path,
            context: context,
          );
        case CropType.profilePicture:
          return await _cropService.cropForProfilePicture(
            imagePath: image.path,
            context: context,
          );
        case CropType.post:
          return await _cropService.cropForPost(
            imagePath: image.path,
            context: context,
          );
      }
    } catch (e) {
      debugPrint('❌ [BannerCropHelper] Error: $e');
      return null;
    }
  }
}

/// Types of cropping presets
enum CropType {
  /// 16:9 aspect ratio for profile banners
  banner,

  /// 1:1 aspect ratio for profile pictures (circular preview)
  profilePicture,

  /// Multiple aspect ratio options for posts
  post,
}
