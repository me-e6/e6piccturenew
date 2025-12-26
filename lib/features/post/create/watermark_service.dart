/* import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// ============================================================================
/// WATERMARK SERVICE
/// ============================================================================
/// Adds QR code + "Piccture" branding watermark to images before upload.
///
/// FEATURES:
/// - ✅ QR code links to user's Piccture profile
/// - ✅ "Piccture" text branding
/// - ✅ Configurable position (bottom-right by default)
/// - ✅ Semi-transparent overlay for subtlety
/// - ✅ Scales with image size
/// ============================================================================
class WatermarkService {
  // --------------------------------------------------------------------------
  // CONFIGURATION
  // --------------------------------------------------------------------------

  /// Base URL for Piccture profiles
  ///
  /// CHANGE THIS to your actual domain:
  /// - Firebase Hosting: 'https://your-project.web.app/profile/'
  /// - Custom domain: 'https://yourdomain.com/u/'
  /// - Deep link: 'piccture://profile/'
  /// - Instagram-style: 'https://instagram.com/' (just username)
  static const String _baseProfileUrl = 'https://piccture.app/u/';

  /// Set to true to just embed username (no URL)
  static const bool _useUsernameOnly = false;

  /// Watermark opacity (0.0 - 1.0)
  static const double _watermarkOpacity = 0.7;

  /// QR code size as percentage of image width
  static const double _qrSizePercent = 0.15; // Increased from 0.12

  /// Minimum QR code size in pixels
  static const int _minQrSize = 80; // Increased from 60

  /// Maximum QR code size in pixels
  static const int _maxQrSize = 200; // Increased from 150

  /// Padding from edge in pixels
  static const int _edgePadding = 16;

  /// Branding text (bottom-right, below QR)
  static const String _brandingText = 'Piccture';

  /// Top-left branding text
  static const String _topLeftBranding = 'PICTTER';

  /// Top-left branding font size multiplier
  static const double _topLeftFontScale = 1.5;

  // --------------------------------------------------------------------------
  // MAIN METHOD: Apply Watermark
  // --------------------------------------------------------------------------
  /// Applies QR code + branding watermark to an image file.
  ///
  /// [imageFile] - Original image file
  /// [userId] - User ID for QR code link
  /// [userHandle] - Optional handle for cleaner URL
  ///
  /// Returns a new File with the watermarked image.
  Future<File> applyWatermark({
    required File imageFile,
    required String userId,
    String? userHandle,
  }) async {
    try {
      debugPrint('🎨 [WatermarkService] Applying watermark...');

      // Read original image
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        debugPrint('❌ [WatermarkService] Failed to decode image');
        return imageFile; // Return original if decode fails
      }

      // Calculate QR code size based on image dimensions
      final qrSize = _calculateQrSize(originalImage.width);

      // Generate profile URL or username-only
      String qrData;
      if (_useUsernameOnly) {
        // Just the username (scannable as text)
        qrData = '@${userHandle ?? userId}';
      } else {
        // Full URL
        qrData = userHandle != null && userHandle.isNotEmpty
            ? '$_baseProfileUrl$userHandle'
            : '$_baseProfileUrl$userId';
      }

      debugPrint('🔗 [WatermarkService] QR data: $qrData');

      // Generate QR code image
      final qrImage = await _generateQrCodeImage(qrData, qrSize);

      if (qrImage == null) {
        debugPrint(
          '⚠️ [WatermarkService] Failed to generate QR, returning original',
        );
        return imageFile;
      }

      // Generate branding text image
      final brandingImage = await _generateBrandingImage(qrSize);

      // Composite the watermark onto the original image
      final watermarkedImage = _compositeWatermark(
        original: originalImage,
        qrCode: qrImage,
        branding: brandingImage,
      );

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${tempDir.path}/watermarked_$timestamp.jpg';

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(
        img.encodeJpg(watermarkedImage, quality: 92),
      );

      debugPrint('✅ [WatermarkService] Watermark applied: $outputPath');
      return outputFile;
    } catch (e) {
      debugPrint('❌ [WatermarkService] Error applying watermark: $e');
      return imageFile; // Return original on error
    }
  }

  // --------------------------------------------------------------------------
  // BATCH WATERMARK
  // --------------------------------------------------------------------------
  /// Applies watermark to multiple images.
  Future<List<File>> applyWatermarkBatch({
    required List<File> imageFiles,
    required String userId,
    String? userHandle,
  }) async {
    final results = <File>[];

    for (final file in imageFiles) {
      final watermarked = await applyWatermark(
        imageFile: file,
        userId: userId,
        userHandle: userHandle,
      );
      results.add(watermarked);
    }

    return results;
  }

  // --------------------------------------------------------------------------
  // CALCULATE QR SIZE
  // --------------------------------------------------------------------------
  int _calculateQrSize(int imageWidth) {
    final calculated = (imageWidth * _qrSizePercent).round();
    return calculated.clamp(_minQrSize, _maxQrSize);
  }

  // --------------------------------------------------------------------------
  // GENERATE QR CODE IMAGE
  // --------------------------------------------------------------------------
  Future<img.Image?> _generateQrCodeImage(String data, int size) async {
    try {
      // Create QR painter with HIGH error correction for better scanning
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H, // High error correction
        gapless: true,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );

      // Render to image
      final qrImage = await qrPainter.toImage(size.toDouble());
      final byteData = await qrImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      // Decode to img.Image for compositing
      final decoded = img.decodePng(byteData.buffer.asUint8List());
      return decoded;
    } catch (e) {
      debugPrint('❌ [WatermarkService] QR generation error: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // GENERATE BRANDING IMAGE
  // --------------------------------------------------------------------------
  Future<img.Image?> _generateBrandingImage(int qrSize) async {
    try {
      // Calculate text size based on QR size
      final fontSize = (qrSize * 0.25).clamp(12.0, 24.0);
      final width = qrSize;
      final height = (fontSize * 1.5).round();

      // Create a simple branding image using the image package
      final brandingImg = img.Image(width: width, height: height);

      // Fill with transparent
      img.fill(brandingImg, color: img.ColorRgba8(0, 0, 0, 0));

      // Draw text (simplified - using drawString which has limited fonts)
      img.drawString(
        brandingImg,
        _brandingText,
        font: img.arial14,
        x: 4,
        y: 2,
        color: img.ColorRgba8(255, 255, 255, 200),
      );

      return brandingImg;
    } catch (e) {
      debugPrint('❌ [WatermarkService] Branding generation error: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // COMPOSITE WATERMARK
  // --------------------------------------------------------------------------
  img.Image _compositeWatermark({
    required img.Image original,
    required img.Image qrCode,
    img.Image? branding,
  }) {
    // Create a copy to avoid modifying original
    final result = img.Image.from(original);

    // =========================================================================
    // TOP-LEFT: "PICTTER" BRANDING
    // =========================================================================
    final topLeftX = _edgePadding;
    final topLeftY = _edgePadding;

    // Draw semi-transparent background for top-left branding
    final topBgWidth = 100;
    final topBgHeight = 28;
    img.fillRect(
      result,
      x1: topLeftX - 4,
      y1: topLeftY - 4,
      x2: topLeftX + topBgWidth,
      y2: topLeftY + topBgHeight,
      color: img.ColorRgba8(50, 50, 50, 160),
    );

    // Draw "PICTTER" text
    img.drawString(
      result,
      _topLeftBranding,
      font: img.arial48,
      x: topLeftX,
      y: topLeftY,
      color: img.ColorRgba8(255, 255, 255, 240),
    );

    // =========================================================================
    // BOTTOM-RIGHT: QR CODE + "Piccture"
    // =========================================================================
    // Calculate position (bottom-right corner)
    final qrX = original.width - qrCode.width - _edgePadding;
    final qrY =
        original.height -
        qrCode.height -
        _edgePadding -
        20; // Extra space for branding

    // Add semi-transparent background behind QR
    final bgPadding = 8;
    final bgX = qrX - bgPadding;
    final bgY = qrY - bgPadding;
    final bgWidth = qrCode.width + (bgPadding * 2);
    final bgHeight =
        qrCode.height + (bgPadding * 2) + 24; // Include branding space

    // Draw rounded background
    img.fillRect(
      result,
      x1: bgX,
      y1: bgY,
      x2: bgX + bgWidth,
      y2: bgY + bgHeight,
      color: img.ColorRgba8(0, 0, 0, 140),
    );

    // Composite QR code with opacity
    img.compositeImage(
      result,
      qrCode,
      dstX: qrX,
      dstY: qrY,
      blend: img.BlendMode.alpha,
    );

    // Add branding text below QR
    img.drawString(
      result,
      _brandingText,
      font: img.arial14,
      x: qrX + (qrCode.width ~/ 2) - 28, // Center text
      y: qrY + qrCode.height + 4,
      color: img.ColorRgba8(255, 255, 255, 220),
    );

    return result;
  }

  // --------------------------------------------------------------------------
  // REMOVE WATERMARK (For previews - just returns original)
  // --------------------------------------------------------------------------
  /// Returns the original file without watermark (for preview purposes).
  File getOriginalForPreview(File watermarkedFile, File originalFile) {
    return originalFile;
  }
}
 */

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// ============================================================================
/// WATERMARK SERVICE
/// ============================================================================
/// Adds QR code + "Piccture" branding watermark to images before upload.
///
/// FEATURES:
/// - ✅ QR code links to user's Piccture profile
/// - ✅ "Piccture" text branding
/// - ✅ Configurable position (bottom-right by default)
/// - ✅ Semi-transparent overlay for subtlety
/// - ✅ Scales with image size
/// ============================================================================
class WatermarkService {
  // --------------------------------------------------------------------------
  // CONFIGURATION
  // --------------------------------------------------------------------------

  /// Base URL for Piccture profiles
  ///
  /// CHANGE THIS to your actual domain:
  /// - Firebase Hosting: 'https://your-project.web.app/profile/'
  /// - Custom domain: 'https://yourdomain.com/u/'
  /// - Deep link: 'piccture://profile/'
  /// - Instagram-style: 'https://instagram.com/' (just username)
  static const String _baseProfileUrl = 'https://piccture.app/u/';

  /// Set to true to just embed username (no URL)
  static const bool _useUsernameOnly = false;

  /// Watermark opacity (0.0 - 1.0)
  static const double _watermarkOpacity = 0.7;

  /// QR code size as percentage of image width
  static const double _qrSizePercent = 0.15; // Increased from 0.12

  /// Minimum QR code size in pixels
  static const int _minQrSize = 80; // Increased from 60

  /// Maximum QR code size in pixels
  static const int _maxQrSize = 200; // Increased from 150

  /// Padding from edge in pixels
  static const int _edgePadding = 16;

  /// Branding text (bottom-right, below QR)
  static const String _brandingText = 'Piccture';

  /// Top-left branding text
  static const String _topLeftBranding = 'PICTTER';

  /// Top-left branding font size multiplier
  static const double _topLeftFontScale = 1.5;

  // --------------------------------------------------------------------------
  // MAIN METHOD: Apply Watermark
  // --------------------------------------------------------------------------
  /// Applies QR code + branding watermark to an image file.
  ///
  /// [imageFile] - Original image file
  /// [userId] - User ID for QR code link
  /// [userHandle] - Optional handle for cleaner URL
  ///
  /// Returns a new File with the watermarked image.
  Future<File> applyWatermark({
    required File imageFile,
    required String userId,
    String? userHandle,
  }) async {
    try {
      debugPrint('🎨 [WatermarkService] Applying watermark...');

      // Read original image
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        debugPrint('❌ [WatermarkService] Failed to decode image');
        return imageFile; // Return original if decode fails
      }

      // Calculate QR code size based on image dimensions
      final qrSize = _calculateQrSize(originalImage.width);

      // Generate profile URL or username-only
      String qrData;
      if (_useUsernameOnly) {
        // Just the username (scannable as text)
        qrData = '@${userHandle ?? userId}';
      } else {
        // Full URL
        qrData = userHandle != null && userHandle.isNotEmpty
            ? '$_baseProfileUrl$userHandle'
            : '$_baseProfileUrl$userId';
      }

      debugPrint('🔗 [WatermarkService] QR data: $qrData');

      // Generate QR code image
      final qrImage = await _generateQrCodeImage(qrData, qrSize);

      if (qrImage == null) {
        debugPrint(
          '⚠️ [WatermarkService] Failed to generate QR, returning original',
        );
        return imageFile;
      }

      // Generate branding text image
      final brandingImage = await _generateBrandingImage(qrSize);

      // Composite the watermark onto the original image
      final watermarkedImage = _compositeWatermark(
        original: originalImage,
        qrCode: qrImage,
        branding: brandingImage,
      );

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${tempDir.path}/watermarked_$timestamp.jpg';

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(
        img.encodeJpg(watermarkedImage, quality: 92),
      );

      debugPrint('✅ [WatermarkService] Watermark applied: $outputPath');
      return outputFile;
    } catch (e) {
      debugPrint('❌ [WatermarkService] Error applying watermark: $e');
      return imageFile; // Return original on error
    }
  }

  // --------------------------------------------------------------------------
  // BATCH WATERMARK
  // --------------------------------------------------------------------------
  /// Applies watermark to multiple images.
  Future<List<File>> applyWatermarkBatch({
    required List<File> imageFiles,
    required String userId,
    String? userHandle,
  }) async {
    final results = <File>[];

    for (final file in imageFiles) {
      final watermarked = await applyWatermark(
        imageFile: file,
        userId: userId,
        userHandle: userHandle,
      );
      results.add(watermarked);
    }

    return results;
  }

  // --------------------------------------------------------------------------
  // CALCULATE QR SIZE
  // --------------------------------------------------------------------------
  int _calculateQrSize(int imageWidth) {
    final calculated = (imageWidth * _qrSizePercent).round();
    return calculated.clamp(_minQrSize, _maxQrSize);
  }

  // --------------------------------------------------------------------------
  // GENERATE QR CODE IMAGE
  // --------------------------------------------------------------------------
  Future<img.Image?> _generateQrCodeImage(String data, int size) async {
    try {
      // Create QR painter with HIGH error correction for better scanning
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H, // High error correction
        gapless: true,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );

      // Render to image
      final qrImage = await qrPainter.toImage(size.toDouble());
      final byteData = await qrImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      // Decode to img.Image for compositing
      final decoded = img.decodePng(byteData.buffer.asUint8List());
      return decoded;
    } catch (e) {
      debugPrint('❌ [WatermarkService] QR generation error: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // GENERATE BRANDING IMAGE
  // --------------------------------------------------------------------------
  Future<img.Image?> _generateBrandingImage(int qrSize) async {
    try {
      // Calculate text size based on QR size
      final fontSize = (qrSize * 0.25).clamp(12.0, 24.0);
      final width = qrSize;
      final height = (fontSize * 1.5).round();

      // Create a simple branding image using the image package
      final brandingImg = img.Image(width: width, height: height);

      // Fill with transparent
      img.fill(brandingImg, color: img.ColorRgba8(0, 0, 0, 0));

      // Draw text (simplified - using drawString which has limited fonts)
      img.drawString(
        brandingImg,
        _brandingText,
        font: img.arial14,
        x: 4,
        y: 2,
        color: img.ColorRgba8(255, 255, 255, 200),
      );

      return brandingImg;
    } catch (e) {
      debugPrint('❌ [WatermarkService] Branding generation error: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // COMPOSITE WATERMARK
  // --------------------------------------------------------------------------
  img.Image _compositeWatermark({
    required img.Image original,
    required img.Image qrCode,
    img.Image? branding,
  }) {
    // Create a copy to avoid modifying original
    final result = img.Image.from(original);

    // =========================================================================
    // BOTTOM-RIGHT: PICTTER + QR CODE + Piccture (stacked vertically)
    // =========================================================================

    // Calculate dimensions
    final qrX = original.width - qrCode.width - _edgePadding;
    final brandingHeight = 35; // Height for PICTTER bar
    final bottomTextHeight = 28; // Height for "Piccture" text
    final bgPadding = 8;

    // Total watermark height: PICTTER + QR + Piccture
    final totalHeight =
        brandingHeight + qrCode.height + bottomTextHeight + (bgPadding * 2);

    // Y position for the entire watermark block
    final blockY = original.height - totalHeight - _edgePadding;

    // Background dimensions
    final bgX = qrX - bgPadding;
    final bgY = blockY;
    final bgWidth = qrCode.width + (bgPadding * 2);

    // ─────────────────────────────────────────────────────────────────────────
    // 1. ORANGE HEADER: "PICTTER"
    // ─────────────────────────────────────────────────────────────────────────
    img.fillRect(
      result,
      x1: bgX,
      y1: bgY,
      x2: bgX + bgWidth,
      y2: bgY + brandingHeight,
      color: img.ColorRgba8(255, 140, 0, 255), // Orange (#FF8C00)
    );

    // Draw "PICTTER" text (white on orange)
    final pictterX = qrX + (qrCode.width ~/ 2) - 42; // Center text
    img.drawString(
      result,
      _topLeftBranding,
      font: img.arial24,
      x: pictterX,
      y: bgY + 4,
      color: img.ColorRgba8(255, 255, 255, 255), // Pure white
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 2. QR CODE SECTION (dark background)
    // ─────────────────────────────────────────────────────────────────────────
    final qrSectionY = bgY + brandingHeight;

    // Dark background for QR
    img.fillRect(
      result,
      x1: bgX,
      y1: qrSectionY,
      x2: bgX + bgWidth,
      y2: qrSectionY + qrCode.height + bgPadding,
      color: img.ColorRgba8(0, 0, 0, 180),
    );

    // Composite QR code
    img.compositeImage(
      result,
      qrCode,
      dstX: qrX,
      dstY: qrSectionY + (bgPadding ~/ 2),
      blend: img.BlendMode.alpha,
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 3. BOTTOM: "Piccture" text
    // ─────────────────────────────────────────────────────────────────────────
    final bottomTextY = qrSectionY + qrCode.height + bgPadding;

    // Dark background for bottom text
    img.fillRect(
      result,
      x1: bgX,
      y1: bottomTextY,
      x2: bgX + bgWidth,
      y2: bottomTextY + bottomTextHeight,
      color: img.ColorRgba8(0, 0, 0, 180),
    );

    // Draw "Piccture" text
    img.drawString(
      result,
      _brandingText,
      font: img.arial14,
      x: qrX + (qrCode.width ~/ 2) - 28, // Center text
      y: bottomTextY + 4,
      color: img.ColorRgba8(255, 255, 255, 220),
    );

    return result;
  }

  // --------------------------------------------------------------------------
  // REMOVE WATERMARK (For previews - just returns original)
  // --------------------------------------------------------------------------
  /// Returns the original file without watermark (for preview purposes).
  File getOriginalForPreview(File watermarkedFile, File originalFile) {
    return originalFile;
  }
}
