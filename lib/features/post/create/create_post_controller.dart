import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_post_service.dart';
import '../../user/services/account_state_guard.dart';

class CreatePostController extends ChangeNotifier {
  final CreatePostService _service;
  final AccountStateGuard _guard = AccountStateGuard();

  CreatePostController({CreatePostService? testService})
    : _service = testService ?? CreatePostService();

  // --------------------------------------------------
  // IMAGES
  // --------------------------------------------------
  final List<XFile> selectedImages = [];

  // --------------------------------------------------
  // DESCRIPTION
  // --------------------------------------------------
  final TextEditingController descController = TextEditingController();

  // --------------------------------------------------
  // UI STATE
  // --------------------------------------------------
  bool isLoading = false;

  // --------------------------------------------------
  // IMAGE PICKERS
  // --------------------------------------------------
  Future<void> pickImagesFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.isNotEmpty) {
      selectedImages
        ..clear()
        ..addAll(picked);
      notifyListeners();
    }
  }

  Future<void> takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      selectedImages
        ..clear()
        ..add(picked);
      notifyListeners();
    }
  }

  void removeImageAt(int index) {
    selectedImages.removeAt(index);
    notifyListeners();
  }

  // --------------------------------------------------
  // CREATE POST
  // --------------------------------------------------

  Future<String> createPost(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage(context, "Please login again.");
      return "not-authenticated";
    }

    if (selectedImages.isEmpty) {
      _showMessage(context, "Please select at least one image.");
      return "no-images";
    }

    final description = descController.text.trim();
    if (description.isEmpty) {
      _showMessage(context, "Please enter a caption.");
      return "no-description";
    }

    _setLoading(true);

    try {
      final guardResult = await _guard.checkMutationAllowed(user.uid);
      if (guardResult != GuardResult.allowed) {
        _showMessage(context, "Action not allowed.");
        return guardResult.name;
      }

      final result = await _service.createPost(
        images: selectedImages.map((x) => File(x.path)).toList(),
        description: description,
      );

      if (result == "success") {
        _showMessage(context, "Post uploaded successfully!");

        selectedImages.clear();
        descController.clear();
        notifyListeners();

        Future.delayed(const Duration(milliseconds: 400), () {
          Navigator.pushReplacementNamed(context, "/home");
        });

        return "success";
      }

      _showMessage(context, "Something went wrong. Try again.");
      return "error";
    } catch (e, st) {
      debugPrint("Create post failed: $e");
      debugPrintStack(stackTrace: st);

      _showMessage(context, "Upload failed. Please try again.");
      return "exception";
    } finally {
      _setLoading(false);
    }
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
