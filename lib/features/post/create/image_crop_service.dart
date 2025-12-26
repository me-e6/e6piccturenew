import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// ============================================================================
/// IMAGE CROP SERVICE
/// ============================================================================
/// Provides image cropping functionality using image_cropper ^8.0.2
///
/// FEATURES:
/// - ✅ Multiple aspect ratio options (1:1, 4:5, 16:9, free)
/// - ✅ Theme-aware UI (adapts to dark/light mode)
/// - ✅ Configurable compression quality
/// - ✅ Banner-specific cropping (16:9 for profile banners)
/// ============================================================================
class ImageCropService {
  final ImageCropper _cropper = ImageCropper();

  // --------------------------------------------------------------------------
  // CROP FOR POST (Multiple aspect ratios)
  // --------------------------------------------------------------------------
  /// Opens the cropper for a post image with multiple aspect ratio options.
  ///
  /// Returns the cropped file path, or null if cancelled.
  Future<String?> cropForPost({
    required String imagePath,
    required BuildContext context,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final croppedFile = await _cropper.cropImage(
        sourcePath: imagePath,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: scheme.surface,
            toolbarWidgetColor: scheme.onSurface,
            backgroundColor: isDark ? Colors.black : Colors.white,
            activeControlsWidgetColor: scheme.primary,
            cropFrameColor: scheme.primary,
            cropGridColor: _withAlpha(scheme.primary, 0.5),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square, // 1:1
              CropAspectRatioPreset.ratio4x3, // 4:3
              CropAspectRatioPreset.ratio3x2, // 3:2
              CropAspectRatioPreset.ratio16x9, // 16:9
              CropAspectRatioPreset.original, // Original
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.original,
            ],
          ),
        ],
      );

      return croppedFile?.path;
    } catch (e) {
      debugPrint('❌ [ImageCropService] Error cropping image: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // CROP FOR PROFILE BANNER (16:9 locked)
  // --------------------------------------------------------------------------
  /// Opens the cropper specifically for profile banners (16:9 aspect ratio).
  ///
  /// Returns the cropped file path, or null if cancelled.
  Future<String?> cropForBanner({
    required String imagePath,
    required BuildContext context,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final croppedFile = await _cropper.cropImage(
        sourcePath: imagePath,
        compressQuality: 90,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Banner',
            toolbarColor: scheme.surface,
            toolbarWidgetColor: scheme.onSurface,
            backgroundColor: isDark ? Colors.black : Colors.white,
            activeControlsWidgetColor: scheme.primary,
            cropFrameColor: scheme.primary,
            cropGridColor: _withAlpha(scheme.primary, 0.5),
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Crop Banner',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            rotateButtonsHidden: false,
          ),
        ],
      );

      return croppedFile?.path;
    } catch (e) {
      debugPrint('❌ [ImageCropService] Error cropping banner: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // CROP FOR PROFILE PICTURE (1:1 locked, circular)
  // --------------------------------------------------------------------------
  /// Opens the cropper for profile pictures (1:1 square aspect ratio).
  ///
  /// Returns the cropped file path, or null if cancelled.
  Future<String?> cropForProfilePicture({
    required String imagePath,
    required BuildContext context,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final croppedFile = await _cropper.cropImage(
        sourcePath: imagePath,
        compressQuality: 90,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: scheme.surface,
            toolbarWidgetColor: scheme.onSurface,
            backgroundColor: isDark ? Colors.black : Colors.white,
            activeControlsWidgetColor: scheme.primary,
            cropFrameColor: scheme.primary,
            cropGridColor: _withAlpha(scheme.primary, 0.5),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
            cropStyle: CropStyle.circle, // ✅ Circular preview
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            rotateButtonsHidden: false,
            cropStyle: CropStyle.circle, // ✅ Circular preview
          ),
        ],
      );

      return croppedFile?.path;
    } catch (e) {
      debugPrint('❌ [ImageCropService] Error cropping profile picture: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // CROP WITH CUSTOM ASPECT RATIO
  // --------------------------------------------------------------------------
  /// Opens the cropper with a custom aspect ratio.
  Future<String?> cropWithCustomRatio({
    required String imagePath,
    required BuildContext context,
    required double ratioX,
    required double ratioY,
    bool lockRatio = true,
    String title = 'Crop Image',
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final croppedFile = await _cropper.cropImage(
        sourcePath: imagePath,
        compressQuality: 90,
        aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: scheme.surface,
            toolbarWidgetColor: scheme.onSurface,
            backgroundColor: isDark ? Colors.black : Colors.white,
            activeControlsWidgetColor: scheme.primary,
            cropFrameColor: scheme.primary,
            cropGridColor: _withAlpha(scheme.primary, 0.5),
            lockAspectRatio: lockRatio,
            hideBottomControls: lockRatio,
          ),
          IOSUiSettings(
            title: title,
            aspectRatioLockEnabled: lockRatio,
            resetAspectRatioEnabled: !lockRatio,
          ),
        ],
      );

      return croppedFile?.path;
    } catch (e) {
      debugPrint('❌ [ImageCropService] Error with custom crop: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // HELPER: Color with alpha (avoids deprecated withOpacity)
  // --------------------------------------------------------------------------
  Color _withAlpha(Color color, double opacity) {
    return Color.fromRGBO(color.red, color.green, color.blue, opacity);
  }
}
