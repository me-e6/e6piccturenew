import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// ============================================================================
/// IMAGE UTILITIES
/// ============================================================================
/// Handles image compression, caching, and processing:
/// - ✅ Compress images before upload
/// - ✅ Generate thumbnails
/// - ✅ Clear image cache
/// - ✅ Preload images
/// - ✅ Get image dimensions
/// ============================================================================
class ImageUtils {
  // --------------------------------------------------------------------------
  // COMPRESSION
  // --------------------------------------------------------------------------
  
  /// Compress image file for upload
  /// Returns compressed file or original if compression fails
  static Future<File> compressImage(
    File file, {
    int quality = 80,
    int minWidth = 1080,
    int minHeight = 1080,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = p.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final originalSize = await file.length();
        final compressedSize = await result.length();
        
        debugPrint(
          '📦 Image compressed: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)} '
          '(${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}% reduction)',
        );

        return File(result.path);
      }

      return file;
    } catch (e) {
      debugPrint('⚠️ Compression failed, using original: $e');
      return file;
    }
  }

  /// Compress image bytes
  static Future<Uint8List?> compressBytes(
    Uint8List bytes, {
    int quality = 80,
    int minWidth = 1080,
    int minHeight = 1080,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );

      return result;
    } catch (e) {
      debugPrint('⚠️ Bytes compression failed: $e');
      return null;
    }
  }

  /// Generate thumbnail from image file
  static Future<File?> generateThumbnail(
    File file, {
    int size = 300,
    int quality = 70,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = p.join(
        dir.path,
        'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: size,
        minHeight: size,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        return File(result.path);
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Thumbnail generation failed: $e');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // CACHING
  // --------------------------------------------------------------------------
  
  /// Clear all cached images
  static Future<void> clearCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      
      // Also clear image cache in memory
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      debugPrint('✅ Image cache cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing cache: $e');
    }
  }

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      int size = 0;

      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          size += await entity.length();
        }
      }

      return size;
    } catch (e) {
      return 0;
    }
  }

  /// Format bytes to human readable
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get formatted cache size string
  static Future<String> getFormattedCacheSize() async {
    final size = await getCacheSize();
    return _formatBytes(size);
  }

  // --------------------------------------------------------------------------
  // PRELOADING
  // --------------------------------------------------------------------------
  
  /// Preload image into cache
  static Future<void> preloadImage(String url) async {
    try {
      await DefaultCacheManager().getSingleFile(url);
    } catch (e) {
      debugPrint('⚠️ Failed to preload: $url');
    }
  }

  /// Preload multiple images
  static Future<void> preloadImages(List<String> urls) async {
    await Future.wait(urls.map(preloadImage));
  }

  // --------------------------------------------------------------------------
  // DIMENSIONS
  // --------------------------------------------------------------------------
  
  /// Get image dimensions from file
  static Future<Size?> getImageDimensions(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      debugPrint('⚠️ Failed to get dimensions: $e');
      return null;
    }
  }

  /// Check if image is square
  static Future<bool> isSquare(File file) async {
    final size = await getImageDimensions(file);
    if (size == null) return false;
    return (size.width - size.height).abs() < 10;
  }

  /// Calculate aspect ratio
  static Future<double?> getAspectRatio(File file) async {
    final size = await getImageDimensions(file);
    if (size == null || size.height == 0) return null;
    return size.width / size.height;
  }
}

/// ============================================================================
/// CACHED IMAGE WITH PLACEHOLDER
/// ============================================================================
/// Wrapper widget for CachedNetworkImage with consistent styling
/// ============================================================================
class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget image;

    if (imageUrl == null || imageUrl!.isEmpty) {
      image = _buildPlaceholder(scheme);
    } else {
      image = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => placeholder ?? _buildLoadingPlaceholder(scheme),
        errorWidget: (_, __, ___) => errorWidget ?? _buildErrorWidget(scheme),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder(ColorScheme scheme) {
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
        size: 32,
      ),
    );
  }

  Widget _buildLoadingPlaceholder(ColorScheme scheme) {
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(ColorScheme scheme) {
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image_outlined,
        color: scheme.error.withValues(alpha: 0.5),
        size: 32,
      ),
    );
  }
}

/// ============================================================================
/// AVATAR IMAGE
/// ============================================================================
/// Consistent avatar widget with fallback
/// ============================================================================
class AvatarImage extends StatelessWidget {
  final String? url;
  final double radius;
  final String? fallbackText;

  const AvatarImage({
    super.key,
    this.url,
    this.radius = 20,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: scheme.surfaceContainerHighest,
        child: fallbackText != null && fallbackText!.isNotEmpty
            ? Text(
                fallbackText![0].toUpperCase(),
                style: TextStyle(
                  fontSize: radius * 0.8,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurfaceVariant,
                ),
              )
            : Icon(
                Icons.person,
                size: radius,
                color: scheme.onSurfaceVariant,
              ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url!,
      imageBuilder: (_, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (_, __) => CircleAvatar(
        radius: radius,
        backgroundColor: scheme.surfaceContainerHighest,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (_, __, ___) => CircleAvatar(
        radius: radius,
        backgroundColor: scheme.surfaceContainerHighest,
        child: Icon(Icons.person, size: radius, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
