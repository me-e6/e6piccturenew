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
  // LOAD PROFILE
  // ------------------------------------------------------------
  Future<void> loadProfile(String uid) async {
    isLoading = true;
    notifyListeners();

    try {
      final currentUid = _auth.currentUser?.uid;

      // ------------------------
      // USERS
      // ------------------------
      user = await _profileService.getUser(uid);

      if (currentUid != null) {
        currentUser = await _profileService.getUser(currentUid);
      }

      if (user == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      // ------------------------
      // FOLLOW STATE
      // ------------------------
      if (currentUid != null && currentUid != uid) {
        _isFollowing = await _followService.isFollowing(
          currentUid: currentUid,
          targetUid: uid,
        );
      } else {
        _isFollowing = false;
      }

      // ------------------------
      // FOLLOW COUNTS
      // ------------------------
      followersCount = await _followService.getFollowersCount(uid);
      followingCount = await _followService.getFollowingCount(uid);

      // ------------------------
      // CONTENT
      // ------------------------
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
      final url = await _profileService.updateProfilePhoto(
        uid: uid,
        file: file,
      );

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
  // FOLLOW / UNFOLLOW
  // ------------------------------------------------------------
  Future<void> toggleFollow() async {
    if (user == null) return;

    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid == user!.uid) return;

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
  // UI STATE
  // ------------------------------------------------------------
  void setTab(int index) {
    if (selectedTab == index) return;
    selectedTab = index;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // ADMIN / VERIFICATION
  // ------------------------------------------------------------
  bool get isAdminViewing {
    if (currentUser == null || user == null) return false;
    return currentUser!.isAdmin && currentUser!.uid != user!.uid;
  }
  // ------------------------------------------------------------
  // VERIFICATION
  // ------------------------------------------------------------

  Future<void> toggleGazetterStatus() async {
    if (user == null) return;

    final newValue = !user!.isVerified;

    await _profileService.toggleGazetter(
      targetUid: user!.uid,
      makeVerified: newValue,
    );

    user = user!.copyWith(
      isVerified: newValue,
      verifiedLabel: newValue ? 'Gazetter' : '',
    );

    notifyListeners();
  }

  // ------------------------------------------------------------
  // READ-ONLY ALIASES (UI SAFE)
  // ------------------------------------------------------------
  List<PostModel> get posts => userPosts;
  List<PostModel> get saved => savedPosts;

  int get postCount => userPosts.length;
  int get repostCount => reposts.length;

  // ------------------------------------------------------------
  // IMPACT POSTS (CLIENT-DERIVED, API-AWARE)
  // ------------------------------------------------------------
  /// TEMP logic:
  /// A post is "Impact" if it crosses engagement threshold.
  /// Backend will own this later.
  List<PostModel> get impactPosts {
    return userPosts.where((post) {
      return post.likeCount >= 50 ||
          post.replyCount >= 10 ||
          post.quoteReplyCount >= 5;
    }).toList();
  }

  // ------------------------------------------------------------
  // EDIT PROFILE (STUB — FUTURE)
  // ------------------------------------------------------------
  void editProfile() {
    // TODO: Navigate to Edit Profile screen
  }

  // ------------------------------------------------------------
  // LIFECYCLE
  // ------------------------------------------------------------
  @override
  void dispose() {
    super.dispose();
  }
}
