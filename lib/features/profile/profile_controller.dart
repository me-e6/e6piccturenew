import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'profile_service.dart';
import '../post/create/post_model.dart';
import 'user_model.dart';

class ProfileController extends ChangeNotifier {
  final ProfileService _service = ProfileService();

  bool isLoading = true;

  UserModel? user;
  List<PostModel> userPosts = [];
  List<PostModel> reposts = [];
  List<PostModel> savedPosts = [];

  int selectedTab = 0;

  // ---------------- LOAD PROFILE ----------------
  Future<void> loadProfile(String uid) async {
    isLoading = true;
    notifyListeners();

    user = await _service.getUser(uid);
    userPosts = await _service.getUserPosts(uid);
    reposts = await _service.getUserReposts(uid);
    savedPosts = await _service.getSavedPosts(uid);

    isLoading = false;
    notifyListeners();
  }

  // ---------------- UPDATE PROFILE PHOTO ----------------
  Future<void> updatePhoto(String uid) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return;

      isLoading = true;
      notifyListeners();

      final file = File(picked.path);

      final url = await _service.updateProfilePhoto(uid, file);

      if (url != null && user != null) {
        user = user!.copyWith(photoUrl: url);
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print("🔥 Error changing photo: $e");
    }
  }

  void setTab(int index) {
    selectedTab = index;
    notifyListeners();
  }

  // ------------ Stats (Fixed for new UserModel) -------------
  int get postCount => userPosts.length;
  int get repostCount => reposts.length;
  int get followersCount => user?.followersCount ?? 0;
  int get followingCount => user?.followingCount ?? 0;
}
