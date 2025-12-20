/* import 'dart:io';
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
  bool isUpdatingVideoDp = false;

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
  // VIDEO DP Controllers
  // ------------------------------------------------------------
  Future<void> updateVideoDp() async {
    if (isUpdatingVideoDp || !isOwner) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 20),
      );

      if (picked == null) return;

      isUpdatingVideoDp = true;
      notifyListeners();

      final file = File(picked.path);

      /*  final videoUrl = await _profileService.updateVideoDp(
        uid: uid,
        file: file,
      ); */
      final videoUrl = await _profileService.uploadVideoDp(
        uid: uid,
        file: file,
      );

      user = user!.copyWith(videoDpUrl: videoUrl);
      /*   ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Video DP updated'))); */

      currentUser = currentUser?.copyWith(videoDpUrl: videoUrl);
    } finally {
      isUpdatingVideoDp = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // VIDEO DP — REPLACE
  // ------------------------------------------------------------
  Future<void> replaceVideoDp() async {
    if (isUpdatingVideoDp || user == null) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != user!.uid) return;

    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 20),
      );

      if (picked == null) return;

      isUpdatingVideoDp = true;
      notifyListeners();

      final file = File(picked.path);

      final url = await _profileService.uploadVideoDp(uid: uid, file: file);

      user = user!.copyWith(displayName: user!.displayName, videoDpUrl: url);
    } finally {
      isUpdatingVideoDp = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // VIDEO DP — DELETE
  // ------------------------------------------------------------
  Future<void> deleteVideoDp() async {
    if (isUpdatingVideoDp || user == null) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null || uid != user!.uid) return;

    try {
      isUpdatingVideoDp = true;
      notifyListeners();

      await _profileService.deleteVideoDp(uid);

      user = user!.copyWith(displayName: user!.displayName, videoDpUrl: null);
    } finally {
      isUpdatingVideoDp = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // VIDEO DP ACTIONS (UI TRIGGER)
  // ------------------------------------------------------------
  void showVideoDpActions(BuildContext context) {
    if (user == null || user!.videoDpUrl == null) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('View video'),
                onTap: () {
                  Navigator.pop(context);
                  // UI handles navigation
                },
              ),

              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Replace video'),
                onTap: () {
                  Navigator.pop(context);
                  replaceVideoDp();
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete video',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  deleteVideoDp();
                },
              ),
            ],
          ),
        );
      },
    );
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
 */

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
  bool isUpdatingVideoDp = false;

  UserModel? user;
  UserModel? currentUser;

  bool _isFollowing = false;
  bool get isFollowing => _isFollowing;

  int followersCount = 0;
  int followingCount = 0;

  List<PostModel> userPosts = [];
  List<PostModel> reposts = [];
  List<PostModel> savedPosts = [];

  int selectedTab = 0;

  // ------------------------------------------------------------
  // OWNERSHIP
  // ------------------------------------------------------------
  bool get isOwner {
    final uid = _auth.currentUser?.uid;
    return uid != null && user != null && uid == user!.uid;
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

      if (currentUid != null && currentUid != uid) {
        _isFollowing = await _followService.isFollowing(
          currentUid: currentUid,
          targetUid: uid,
        );
      }

      followersCount = await _followService.getFollowersCount(uid);
      followingCount = await _followService.getFollowingCount(uid);

      userPosts = await _profileService.getUserPosts(uid);
      reposts = await _profileService.getUserReposts(uid);

      if (currentUid == uid) {
        savedPosts = await _profileService.getSavedPosts(uid);
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // UPDATE PROFILE PHOTO
  // ------------------------------------------------------------
  Future<void> updatePhoto(BuildContext context) async {
    if (isUpdatingPhoto || !isOwner) return;

    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      isUpdatingPhoto = true;
      notifyListeners();

      final url = await _profileService.updateProfilePhoto(
        uid: user!.uid,
        file: File(picked.path),
      );

      if (url != null) {
        user = user!.copyWith(profileImageUrl: url);
        currentUser = currentUser?.copyWith(profileImageUrl: url);

        _success(context, 'Profile photo updated');
      }
    } catch (_) {
      _error(context);
    } finally {
      isUpdatingPhoto = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // UPDATE PROFILE BANNER
  // ------------------------------------------------------------
  Future<void> updateBanner(BuildContext context) async {
    if (isUpdatingBanner || !isOwner) return;

    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      isUpdatingBanner = true;
      notifyListeners();

      final url = await _profileService.updateProfileBanner(
        uid: user!.uid,
        file: File(picked.path),
      );

      if (url != null) {
        user = user!.copyWith(profileBannerUrl: url);
        _success(context, 'Banner updated');
      }
    } catch (_) {
      _error(context);
    } finally {
      isUpdatingBanner = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // SAVE PROFILE DETAILS
  // ------------------------------------------------------------
  Future<void> saveProfile({
    required BuildContext context,
    required String displayName,
    required String bio,
  }) async {
    if (!isOwner) return;

    try {
      await _profileService.updateProfileDetails(
        uid: user!.uid,
        displayName: displayName,
        bio: bio,
      );

      user = user!.copyWith(displayName: displayName, bio: bio);

      _success(context, 'Profile updated');
    } catch (_) {
      _error(context);
    }
  }

  // ------------------------------------------------------------
  // VIDEO DP — REPLACE
  // ------------------------------------------------------------

  Future<void> replaceVideoDp(BuildContext context) async {
    if (isUpdatingVideoDp || !isOwner) return;

    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 20),
      );
      if (picked == null) return;

      isUpdatingVideoDp = true;
      notifyListeners();

      await _profileService.updateVideoDp(
        uid: user!.uid,
        file: File(picked.path),
      );

      // 🔥 RELOAD USER
      user = await _profileService.getUser(user!.uid);
      currentUser = user;

      _success(context, 'Video DP updated');
    } catch (_) {
      _error(context);
    } finally {
      isUpdatingVideoDp = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // VIDEO DP — DELETE
  // ------------------------------------------------------------
  Future<void> deleteVideoDp(BuildContext context) async {
    if (isUpdatingVideoDp || !isOwner) return;

    try {
      isUpdatingVideoDp = true;
      notifyListeners();

      await _profileService.deleteVideoDp(user!.uid);

      // 🔥 RELOAD USER
      user = await _profileService.getUser(user!.uid);
      currentUser = user;

      _success(context, 'Video DP removed');
    } catch (_) {
      _error(context);
    } finally {
      isUpdatingVideoDp = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // updatVideo DP
  // ------------------------------------------------------------

  Future<void> updateVideoDp() async {
    debugPrint('🎥 updateVideoDp called');

    if (isUpdatingVideoDp || !isOwner) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 20),
      );
      if (picked == null) return;

      isUpdatingVideoDp = true;
      notifyListeners();

      await _profileService.updateVideoDp(uid: uid, file: File(picked.path));

      // 🔥 CRITICAL FIX — RELOAD USER FROM FIRESTORE
      user = await _profileService.getUser(uid);
      currentUser = user;

      debugPrint('✅ videoDpUrl after reload = ${user?.videoDpUrl}');
    } catch (e) {
      debugPrint('❌ updateVideoDp error: $e');
    } finally {
      isUpdatingVideoDp = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // UI HELPERS -Snackbars
  // ------------------------------------------------------------
  void _success(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------
  // VIDEO DP ACTIONS (UI TRIGGER)
  // ------------------------------------------------------------
  void showVideoDpActions(BuildContext context) {
    if (user == null || user!.videoDpUrl == null) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('View video'),
                onTap: () {
                  Navigator.pop(context);
                  // UI handles navigation
                },
              ),

              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Replace video'),
                onTap: () {
                  Navigator.pop(context);
                  replaceVideoDp(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete video',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  deleteVideoDp(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _error(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
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
  // TAB / GETTERS
  // ------------------------------------------------------------
  void setTab(int index) {
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
