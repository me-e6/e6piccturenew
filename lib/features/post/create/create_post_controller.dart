import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_post_service.dart';

class CreatePostController extends ChangeNotifier {
  final CreatePostService _service = CreatePostService();
  final ImagePicker _picker = ImagePicker();

  /// Local image paths (UI-safe)
  final List<String> selectedImages;

  bool isUploading = false;

  // ------------------------------------------------------------
  // CONSTRUCTOR (INITIAL IMAGES FROM PLUS / CAMERA / UPLOAD)
  // ------------------------------------------------------------
  CreatePostController({List<String>? initialImagePaths})
    : selectedImages = initialImagePaths ?? [];

  // ------------------------------------------------------------
  // PICK IMAGES (GALLERY ONLY)
  // ------------------------------------------------------------
  Future<void> pickImages() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage();

      if (files.isEmpty) return;

      selectedImages
        ..clear()
        ..addAll(files.map((f) => f.path));

      notifyListeners();
    } catch (_) {
      // UI-safe: ignore picker failures
    }
  }

  // ------------------------------------------------------------
  // CREATE POST
  // ------------------------------------------------------------
  Future<bool> createPost() async {
    if (selectedImages.isEmpty || isUploading) return false;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    isUploading = true;
    notifyListeners();

    try {
      final imageFiles = selectedImages.map((p) => File(p)).toList();

      await _service.createImagePost(authorId: uid, images: imageFiles);

      // Reset state on success
      selectedImages.clear();
      return true;
    } catch (_) {
      return false;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }
}
