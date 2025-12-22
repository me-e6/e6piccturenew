import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'create_post_service.dart';

class CreatePostController extends ChangeNotifier {
  final CreatePostService _service = CreatePostService();
  final ImagePicker _picker = ImagePicker();

  /// Local image paths (UI-safe)
  final List<String> selectedImages;

  bool isUploading = false;
  String? errorMessage;

  // ------------------------------------------------------------
  // CONSTRUCTOR (INITIAL IMAGES FROM PLUS / CAMERA / UPLOAD)
  // ------------------------------------------------------------
  CreatePostController({List<String>? initialImagePaths})
    : selectedImages = initialImagePaths ?? [];

  // ------------------------------------------------------------
  // PICK IMAGES (GALLERY ONLY) - FIXED
  // ------------------------------------------------------------
  Future<void> pickImages() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      // User cancelled picker
      if (files.isEmpty) {
        debugPrint('User cancelled image picker');
        return;
      }

      // Validate file paths
      final validPaths = <String>[];
      for (final file in files) {
        if (file.path.isNotEmpty && File(file.path).existsSync()) {
          validPaths.add(file.path);
        } else {
          debugPrint('Invalid file path: ${file.path}');
        }
      }

      if (validPaths.isEmpty) {
        errorMessage = 'No valid images selected';
        notifyListeners();
        return;
      }

      selectedImages
        ..clear()
        ..addAll(validPaths);

      errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error picking images: $e');
      errorMessage = 'Failed to pick images: $e';
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // PICK FROM CAMERA - NEW METHOD
  // ------------------------------------------------------------
  Future<void> pickFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      // User cancelled camera
      if (photo == null) {
        debugPrint('User cancelled camera');
        return;
      }

      // Validate file path
      if (photo.path.isEmpty || !File(photo.path).existsSync()) {
        debugPrint('Invalid camera photo path: ${photo.path}');
        errorMessage = 'Failed to capture photo';
        notifyListeners();
        return;
      }

      selectedImages
        ..clear()
        ..add(photo.path);

      errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error taking photo: $e');
      errorMessage = 'Failed to take photo: $e';
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // REMOVE IMAGE
  // ------------------------------------------------------------
  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // CLEAR ALL IMAGES
  // ------------------------------------------------------------
  void clearImages() {
    selectedImages.clear();
    errorMessage = null;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // CREATE POST (HARDENED, SINGLE-SUBMIT) - FIXED
  // ------------------------------------------------------------
  Future<bool> createPost() async {
    if (isUploading) {
      debugPrint('Upload already in progress');
      return false;
    }

    if (selectedImages.isEmpty) {
      errorMessage = 'No images selected';
      notifyListeners();
      return false;
    }

    isUploading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Convert paths to File objects with validation
      final imageFiles = <File>[];
      for (final path in selectedImages) {
        final file = File(path);
        if (file.existsSync()) {
          imageFiles.add(file);
        } else {
          debugPrint('File does not exist: $path');
        }
      }

      if (imageFiles.isEmpty) {
        errorMessage = 'No valid image files found';
        return false;
      }

      await _service.createImagePost(images: imageFiles);

      // Reset state on success
      selectedImages.clear();
      errorMessage = null;
      return true;
    } catch (e) {
      debugPrint('Error creating post: $e');
      errorMessage = 'Failed to create post: $e';
      return false;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // CLEANUP
  // ------------------------------------------------------------
  @override
  void dispose() {
    selectedImages.clear();
    super.dispose();
  }
}
