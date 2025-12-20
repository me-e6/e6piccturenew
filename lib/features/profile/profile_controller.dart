import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_service.dart';
import '../follow/follow_service.dart';
import '../post/create/post_model.dart';
import 'user_model.dart';

class ProfileController extends ChangeNotifier {
  // ------------------------------------------------------------
  // DEPENDENCIES
  // ------------------------------------------------------------
  final ProfileService _profileService;
  final FollowService _followService;
  final FirebaseAuth _auth;
  final ImagePicker _picker = ImagePicker();

  ProfileController({
    ProfileService? profileService,
    FollowService? followService,
    FirebaseAuth? auth,
  }) : _profileService = profileService ?? ProfileService(),
       _followService = followService ?? FollowService(),
       _auth = auth ?? FirebaseAuth.instance;

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------
  bool isLoading = true;
  bool isUpdatingPhoto = false;
  bool isUpdatingBanner = false;

  /// Viewed profile
  UserModel? user;

  /// Logged-in user
  UserModel? currentUser;

  /// Follow state (viewer → profile)
  bool _isFollowing = false;
  bool get isFollowing => _isFollowing;

  /// Follow graph counts
  int followersCount = 0;
  int followingCount = 0;

  /// Content
  List<PostModel> userPosts = [];
  List<PostModel> reposts = [];
  List<PostModel> savedPosts = [];

  /// Tabs
  int selectedTab = 0;

  // ------------------------------------------------------------
  // OWNERSHIP (CANONICAL)
  // ------------------------------------------------------------
  bool get isOwner {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || user == null) return false;
    return currentUid == user!.uid;
  }

  // ------------------------------------------------------------
  // LOAD PROFILE
  // ------------------------------------------------------------
  Future<void> loadProfile(String uid) async {
    isLoading = true;
    notifyListeners();

    try {
      final currentUid = _auth.currentUser?.uid;

      user = await _profileService.getUser(uid);

      if (currentUid != null) {
        currentUser = await _profileService.getUser(currentUid);
      }

      if (user == null) return;

      // Follow state
      if (currentUid != null && currentUid != uid) {
        _isFollowing = await _followService.isFollowing(
          currentUid: currentUid,
          targetUid: uid,
        );
      } else {
        _isFollowing = false;
      }

      // Counts
      followersCount = await _followService.getFollowersCount(uid);
      followingCount = await _followService.getFollowingCount(uid);

      // Content
      userPosts = await _profileService.getUserPosts(uid);
      reposts = await _profileService.getUserReposts(uid);

      if (currentUid == uid) {
        savedPosts = await _profileService.getSavedPosts(uid);
      } else {
        savedPosts = [];
      }
    } catch (_) {
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
  Future<void> updatePhoto() async {
    if (isUpdatingPhoto || !isOwner) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      isUpdatingPhoto = true;
      notifyListeners();

      final file = File(picked.path);
      final url = await _profileService.updateProfilePhoto(
        uid: uid,
        file: file,
      );

      if (url != null) {
        user = user!.copyWith(
          displayName: user!.displayName,
          profileImageUrl: url,
        );
        currentUser = currentUser?.copyWith(
          displayName: currentUser!.displayName,
          profileImageUrl: url,
        );
      }
    } finally {
      isUpdatingPhoto = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // UPDATE PROFILE BANNER
  // ------------------------------------------------------------
  Future<void> updateBanner() async {
    if (isUpdatingBanner || !isOwner) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      isUpdatingBanner = true;
      notifyListeners();

      final file = File(picked.path);
      final url = await _profileService.updateProfileBanner(
        uid: uid,
        file: file,
      );

      if (url != null) {
        user = user!.copyWith(
          displayName: user!.displayName,
          profileBannerUrl: url,
        );
      }
    } finally {
      isUpdatingBanner = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // FOLLOW / UNFOLLOW
  // ------------------------------------------------------------
  Future<void> toggleFollow() async {
    if (user == null || isOwner) return;

    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    if (_isFollowing) {
      await _followService.unfollow(
        currentUid: currentUid,
        targetUid: user!.uid,
      );
      _isFollowing = false;
      followersCount--;
    } else {
      await _followService.follow(currentUid: currentUid, targetUid: user!.uid);
      _isFollowing = true;
      followersCount++;
    }

    notifyListeners();
  }

  // ------------------------------------------------------------
  // SAVE PROFILE DETAILS
  // ------------------------------------------------------------
  Future<void> saveProfile({
    required String displayName,
    required String bio,
  }) async {
    if (!isOwner) return;

    await _profileService.updateProfileDetails(
      uid: user!.uid,
      displayName: displayName,
      bio: bio,
    );

    user = user!.copyWith(displayName: displayName, bio: bio);

    notifyListeners();
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------
  void setTab(int index) {
    if (selectedTab == index) return;
    selectedTab = index;
    notifyListeners();
  }

  List<PostModel> get posts => userPosts;
  List<PostModel> get saved => savedPosts;

  List<PostModel> get impactPosts => userPosts.where((post) {
    return post.likeCount >= 50 ||
        post.replyCount >= 10 ||
        post.quoteReplyCount >= 5;
  }).toList();
}
