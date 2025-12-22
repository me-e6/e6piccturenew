import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Centralized media picker service with proper error handling
class MediaPickerService {
  final ImagePicker _picker = ImagePicker();

  // ------------------------------------------------------------
  // PICK SINGLE IMAGE
  // ------------------------------------------------------------
  Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 85,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        requestFullMetadata:
            false, // ✅ FIX: Prevents Bundle NullPointerException
      );

      // User cancelled picker
      if (image == null) {
        debugPrint('User cancelled image picker');
        return null;
      }

      // Validate file path
      if (image.path.isEmpty || !File(image.path).existsSync()) {
        debugPrint('Invalid image path: ${image.path}');
        throw Exception('Invalid image file');
      }

      return File(image.path);
    } catch (e) {
      debugPrint('Error picking image: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // PICK MULTIPLE IMAGES
  // ------------------------------------------------------------
  Future<List<File>> pickMultipleImages({
    int imageQuality = 85,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
    int? limit,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        limit: limit,
        requestFullMetadata:
            false, // ✅ FIX: Prevents Bundle NullPointerException
      );

      // User cancelled picker
      if (images.isEmpty) {
        debugPrint('User cancelled image picker or no images selected');
        return [];
      }

      // Validate and convert to File objects
      final validFiles = <File>[];
      for (final image in images) {
        if (image.path.isNotEmpty && File(image.path).existsSync()) {
          validFiles.add(File(image.path));
        } else {
          debugPrint('Skipping invalid file: ${image.path}');
        }
      }

      if (validFiles.isEmpty) {
        throw Exception('No valid image files found');
      }

      return validFiles;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // PICK VIDEO
  // ------------------------------------------------------------
  Future<File?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );

      // User cancelled picker
      if (video == null) {
        debugPrint('User cancelled video picker');
        return null;
      }

      // Validate file path
      if (video.path.isEmpty || !File(video.path).existsSync()) {
        debugPrint('Invalid video path: ${video.path}');
        throw Exception('Invalid video file');
      }

      return File(video.path);
    } catch (e) {
      debugPrint('Error picking video: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // SHOW PICKER SOURCE DIALOG
  // ------------------------------------------------------------
  Future<ImageSource?> showSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // VALIDATE FILE SIZE
  // ------------------------------------------------------------
  bool validateFileSize(File file, {int maxSizeMB = 10}) {
    final fileSizeInBytes = file.lengthSync();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

    if (fileSizeInMB > maxSizeMB) {
      debugPrint('File size ($fileSizeInMB MB) exceeds limit ($maxSizeMB MB)');
      return false;
    }

    return true;
  }

  // ------------------------------------------------------------
  // GET FILE SIZE IN MB
  // ------------------------------------------------------------
  double getFileSizeInMB(File file) {
    final fileSizeInBytes = file.lengthSync();
    return fileSizeInBytes / (1024 * 1024);
  }
}
