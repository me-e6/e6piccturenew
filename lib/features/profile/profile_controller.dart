/* import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_service.dart';
import '../post/create/post_model.dart';
import 'user_model.dart';
import '../follow/follow_service.dart';

class ProfileController extends ChangeNotifier {
  // ------------------------------------------------------------
  // DEPENDENCIES
  // ------------------------------------------------------------
  final ProfileService _service;
  //final FollowService _followService;
  final FirebaseAuth _auth;
  final FollowService _followService = FollowService();

  final ImagePicker _picker = ImagePicker();

  ProfileController({
    ProfileService? service,
    FollowService? followService,
    FirebaseAuth? auth,
  }) : _service = service ?? ProfileService(),
       // _followService = followService ?? FollowService(),
       _auth = auth ?? FirebaseAuth.instance;

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------
  bool isLoading = true;
  bool isUpdatingPhoto = false;

  bool _isFollowing = false;
  bool get isFollowing => _isFollowing;

  /// Viewed profile
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
    isLoading = true;
    notifyListeners();

    try {
      user = await _service.getUser(uid);

      final currentUid = _auth.currentUser?.uid;
      if (currentUid != null) {
        currentUser = await _service.getUser(currentUid);

        if (currentUid != uid) {
          _isFollowing = await _followService.isFollowing(
            currentUid: currentUid,
            targetUid: uid,
          );
        } else {
          _isFollowing = false;
        }
      }

      userPosts = await _service.getUserPosts(uid);
      reposts = await _service.getUserReposts(uid);

      if (currentUid == uid) {
        savedPosts = await _service.getSavedPosts(uid);
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
    if (isUpdatingPhoto || user == null) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != user!.uid) return;

    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    isUpdatingPhoto = true;
    notifyListeners();

    try {
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
  // FOLLOW / UNFOLLOW
  // ------------------------------------------------------------
  Future<void> toggleFollow() async {
    if (user == null || currentUser == null) return;

    final currentUid = currentUser!.uid;
    final targetUid = user!.uid;

    if (_isFollowing) {
      await _followService.unfollow(
        currentUid: currentUid,
        targetUid: targetUid,
      );
      _isFollowing = false;
    } else {
      await _followService.follow(currentUid: currentUid, targetUid: targetUid);
      _isFollowing = true;
    }

    notifyListeners();
  }

  // ------------------------------------------------------------
  // EDIT PROFILE (API READY STUB)
  // ------------------------------------------------------------
  void editProfile() {
    // navigation hook later
  }

  // ------------------------------------------------------------
  // ADMIN
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
  // VERIFICATION
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
  // UI ALIASES
  // ------------------------------------------------------------
  List<PostModel> get posts => userPosts;
  List<PostModel> get saved => savedPosts;
}
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_service.dart';
import '../post/create/post_model.dart';
import 'user_model.dart';
import '../follow/follow_service.dart';

class ProfileController extends ChangeNotifier {
  // ------------------------------------------------------------
  // DEPENDENCIES
  // ------------------------------------------------------------
  final ProfileService _service;
  final FirebaseAuth _auth;
  final FollowService _followService = FollowService();
  final ImagePicker _picker = ImagePicker();

  ProfileController({ProfileService? service, FirebaseAuth? auth})
    : _service = service ?? ProfileService(),
      _auth = auth ?? FirebaseAuth.instance;

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------
  bool isLoading = true;
  bool isUpdatingPhoto = false;

  UserModel? user;
  UserModel? currentUser;

  List<PostModel> userPosts = [];
  List<PostModel> reposts = [];
  List<PostModel> savedPosts = [];

  bool _isFollowing = false;
  bool get isFollowing => _isFollowing;

  bool get isOwner =>
      currentUser != null && user != null && currentUser!.uid == user!.uid;

  int selectedTab = 0;

  // ------------------------------------------------------------
  // LOAD PROFILE
  // ------------------------------------------------------------
  Future<void> loadProfile(String uid) async {
    isLoading = true;
    notifyListeners();

    try {
      user = await _service.getUser(uid);

      final currentUid = _auth.currentUser?.uid;
      if (currentUid != null) {
        currentUser = await _service.getUser(currentUid);

        if (currentUid != uid) {
          _isFollowing = await _followService.isFollowing(
            currentUid: currentUid,
            targetUid: uid,
          );
        }
      }

      userPosts = await _service.getUserPosts(uid);
      reposts = await _service.getUserReposts(uid);

      if (currentUid == uid) {
        savedPosts = await _service.getSavedPosts(uid);
      } else {
        savedPosts = [];
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // VERIFICATION
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
  // FOLLOW / UNFOLLOW
  // ------------------------------------------------------------
  Future<void> toggleFollow() async {
    if (user == null || currentUser == null) return;

    final currentUid = currentUser!.uid;
    final targetUid = user!.uid;

    if (_isFollowing) {
      await _followService.unfollow(
        currentUid: currentUid,
        targetUid: targetUid,
      );
      _isFollowing = false;
    } else {
      await _followService.follow(currentUid: currentUid, targetUid: targetUid);
      _isFollowing = true;
    }

    notifyListeners();
  }

  // ------------------------------------------------------------
  // UPDATE PROFILE PHOTO
  // ------------------------------------------------------------
  Future<void> updatePhoto() async {
    if (!isOwner || isUpdatingPhoto) return;

    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    isUpdatingPhoto = true;
    notifyListeners();

    try {
      final file = File(picked.path);
      final url = await _service.updateProfilePhoto(uid: user!.uid, file: file);

      if (url != null) {
        user = user!.copyWith(profileImageUrl: url);
      }
    } finally {
      isUpdatingPhoto = false;
      notifyListeners();
    }
  }

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
  // ADMIN
  // ------------------------------------------------------------
  bool get isAdminViewing {
    if (currentUser == null || user == null) return false;
    return currentUser!.isAdmin && currentUser!.uid != user!.uid;
  }

  // ------------------------------------------------------------
  // TABS
  // ------------------------------------------------------------
  void setTab(int index) {
    if (selectedTab == index) return;
    selectedTab = index;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // UI ALIASES (DO NOT BREAK EXISTING UI)
  // ------------------------------------------------------------
  List<PostModel> get posts => userPosts;
  List<PostModel> get saved => savedPosts;
}
