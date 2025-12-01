import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'create_post_service.dart';

class CreatePostController extends ChangeNotifier {
  final CreatePostService _service;

  CreatePostController({CreatePostService? testService})
    : _service = testService ?? CreatePostService() {
    _loadOfficers();
  }

  // Image
  XFile? selectedImage;

  // Description
  final TextEditingController descController = TextEditingController();

  // Officer Selection
  List<Map<String, dynamic>> officerList = [];
  String? selectedOfficerId;

  // Loading State
  bool isLoading = false;

  // Pick Image from gallery or camera
  Future<void> pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      selectedImage = picked;
      notifyListeners();
    }
  }

  // Load officer list from Firestore (only userType = officer)
  Future<void> _loadOfficers() async {
    final result = await _service.fetchOfficerList();

    officerList = result;
    notifyListeners();
  }

  // Set selected officer
  void setOfficer(String? officerId) {
    selectedOfficerId = officerId;
    notifyListeners();
  }

  // MAIN CREATE POST LOGIC
  Future<void> createPost(BuildContext context) async {
    if (selectedImage == null) {
      _showMessage(context, "Please select an image.");
      return;
    }

    final description = descController.text.trim();
    if (description.isEmpty) {
      _showMessage(context, "Please enter a description.");
      return;
    }

    _setLoading(true);

    final result = await _service.createPost(
      image: File(selectedImage!.path),
      description: description,
      officerId: selectedOfficerId,
    );

    _setLoading(false);

    if (result == "success") {
      _showMessage(context, "Post uploaded successfully!");

      // Clear fields after success
      selectedImage = null;
      descController.clear();
      selectedOfficerId = null;

      notifyListeners();

      // Navigate back to Home
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacementNamed(context, "/home");
      });
    } else {
      _showMessage(context, "Something went wrong. Try again.");
    }
  }

  // Loading state helper
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // Snackbar helper
  void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
