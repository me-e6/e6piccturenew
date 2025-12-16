import 'package:flutter/material.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_service.dart';
import '../post/create/post_model.dart';
import 'user_model.dart';

class ProfileController extends ChangeNotifier {
  final ProfileService _service = ProfileService();

  bool isLoading = true;

  /// Profile being viewed
  UserModel? user;

  /// Logged-in user
  UserModel? currentUser;

  List<PostModel> userPosts = [];
  List<PostModel> reposts = [];
  List<PostModel> savedPosts = [];

  int selectedTab = 0;

  // ------------------------------------------------------------
  // LOAD PROFILE
  // ------------------------------------------------------------
  Future<void> loadProfile(String uid) async {
    // Prevent redundant reloads
    if (user?.uid == uid && !isLoading) return;

    isLoading = true;
    notifyListeners();

    try {
      // Viewed profile
      user = await _service.getUser(uid);

      // Logged-in user
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null) {
        currentUser = await _service.getUser(currentUid);
      }

      // Content
      userPosts = await _service.getUserPosts(uid);
      reposts = await _service.getUserReposts(uid);

      // Saved posts only for self
      if (currentUid == uid) {
        savedPosts = await _service.getSavedPosts(uid);
      } else {
        savedPosts = [];
      }
    } catch (e) {
      // Fail-safe: clear data but avoid crash
      userPosts = [];
      reposts = [];
      savedPosts = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // UPDATE PROFILE PHOTO
  // ------------------------------------------------------------
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
        user = user!.copyWith(profileImageUrl: url);
      }
    } catch (e) {
      // Do not swallow silently — ensure UI recovers
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // ADMIN VIEW LOGIC
  // ------------------------------------------------------------
  bool get isAdminViewing {
    if (currentUser == null || user == null) return false;
    return currentUser!.isAdmin && currentUser!.uid != user!.uid;
  }

  // ------------------------------------------------------------
  // UI STATE
  // ------------------------------------------------------------
  void setTab(int index) {
    if (selectedTab == index) return;
    selectedTab = index;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // VERIFICATION / GAZETTER
  // ------------------------------------------------------------
  Future<void> toggleGazetterStatus() async {
    if (user == null) return;

    final bool newValue = !user!.isVerified;

    await _service.toggleGazetter(targetUid: user!.uid, makeVerified: newValue);

    user = user!.copyWith(
      isVerified: newValue,
      verifiedLabel: newValue ? 'Gazetter' : '',
    );

    notifyListeners();
  }

  // ------------------------------------------------------------
  // STATS (READ-ONLY)
  // ------------------------------------------------------------
  int get postCount => userPosts.length;
  int get repostCount => reposts.length;
  int get followersCount => user?.followersCount ?? 0;
  int get followingCount => user?.followingCount ?? 0;

  // ------------------------------------------------------------
  // LIFECYCLE
  // ------------------------------------------------------------
  @override
  void dispose() {
    // Future-proof: streams / listeners may be added later
    super.dispose();
  }
}
