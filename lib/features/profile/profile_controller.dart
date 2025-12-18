import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_service.dart';
import '../post/create/post_model.dart';
import 'user_model.dart';

class ProfileController extends ChangeNotifier {
  // ------------------------------------------------------------
  // DEPENDENCIES
  // ------------------------------------------------------------
  final ProfileService _service;
  final FirebaseAuth _auth;
  final ImagePicker _picker = ImagePicker();

  ProfileController({ProfileService? service, FirebaseAuth? auth})
    : _service = service ?? ProfileService(),
      _auth = auth ?? FirebaseAuth.instance;

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------
  bool isLoading = true;
  bool isUpdatingPhoto = false;

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
    if (user?.uid == uid && !isLoading) return;

    isLoading = true;
    notifyListeners();

    try {
      // Viewed profile
      user = await _service.getUser(uid);

      // Logged-in user
      final currentUid = _auth.currentUser?.uid;
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
    } catch (_) {
      // Fail-safe: clear lists but keep UI alive
      userPosts = [];
      reposts = [];
      savedPosts = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // UPDATE PROFILE PHOTO (DP)
  // ------------------------------------------------------------
  Future<void> updatePhoto() async {
    if (isUpdatingPhoto || user == null) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != user!.uid) return;

    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return;

      isUpdatingPhoto = true;
      notifyListeners();

      final file = File(picked.path);
      final url = await _service.updateProfilePhoto(uid: uid, file: file);

      if (url != null) {
        user = user!.copyWith(profileImageUrl: url);
        currentUser = currentUser?.copyWith(profileImageUrl: url);
      }
    } finally {
      isUpdatingPhoto = false;
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

    final newValue = !user!.isVerified;

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
  // UI ALIASES (DO NOT CHANGE UI EXPECTATIONS)
  // ------------------------------------------------------------
  List<PostModel> get posts => userPosts;
  List<PostModel> get saved => savedPosts;

  // ------------------------------------------------------------
  // LIFECYCLE
  // ------------------------------------------------------------
  @override
  void dispose() {
    super.dispose();
  }
}
