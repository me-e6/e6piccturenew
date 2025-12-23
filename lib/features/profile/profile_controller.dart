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
  // UPDATE PROFILE PHOTO (FIXED)
  // ------------------------------------------------------------
  Future<void> updatePhoto(BuildContext context) async {
    if (isUpdatingPhoto || !isOwner || user == null) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      // User cancelled picker
      if (picked == null) {
        debugPrint('User cancelled photo picker');
        return;
      }

      isUpdatingPhoto = true;
      notifyListeners();

      final url = await _profileService.updateProfilePhoto(
        uid: user!.uid,
        file: File(picked.path),
      );

      if (url != null && url.isNotEmpty) {
        user = user!.copyWith(profileImageUrl: url);
        currentUser = currentUser?.copyWith(profileImageUrl: url);

        if (context.mounted) {
          _success(context, 'Profile photo updated');
        }
      }
    } catch (e) {
      debugPrint('Error updating photo: $e');
      if (context.mounted) {
        _error(context);
      }
    } finally {
      isUpdatingPhoto = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // UPDATE PROFILE BANNER (FIXED)
  // ------------------------------------------------------------
  Future<void> updateBanner(BuildContext context) async {
    if (isUpdatingBanner || !isOwner || user == null) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      // User cancelled picker
      if (picked == null) {
        debugPrint('User cancelled banner picker');
        return;
      }

      isUpdatingBanner = true;
      notifyListeners();

      final url = await _profileService.updateProfileBanner(
        uid: user!.uid,
        file: File(picked.path),
      );

      if (url != null && url.isNotEmpty) {
        user = user!.copyWith(profileBannerUrl: url);

        if (context.mounted) {
          _success(context, 'Banner updated');
        }
      }
    } catch (e) {
      debugPrint('Error updating banner: $e');
      if (context.mounted) {
        _error(context);
      }
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
    if (!isOwner || user == null) return;

    try {
      await _profileService.updateProfileDetails(
        uid: user!.uid,
        displayName: displayName,
        bio: bio,
      );

      user = user!.copyWith(displayName: displayName, bio: bio);

      if (context.mounted) {
        _success(context, 'Profile updated');
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (context.mounted) {
        _error(context);
      }
    } finally {
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // VIDEO DP — REPLACE (FIXED)
  // ------------------------------------------------------------
  Future<void> replaceVideoDp(BuildContext context) async {
    if (isUpdatingVideoDp || !isOwner || user == null) return;

    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 20),
      );

      // User cancelled picker
      if (picked == null) {
        debugPrint('User cancelled video picker');
        return;
      }

      isUpdatingVideoDp = true;
      notifyListeners();

      await _profileService.updateVideoDp(
        uid: user!.uid,
        file: File(picked.path),
      );

      // Reload user from Firestore
      user = await _profileService.getUser(user!.uid);
      currentUser = user;

      if (context.mounted) {
        _success(context, 'Video DP updated');
      }
    } catch (e) {
      debugPrint('Error replacing video DP: $e');
      if (context.mounted) {
        _error(context);
      }
    } finally {
      isUpdatingVideoDp = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // VIDEO DP — DELETE (FIXED)
  // ------------------------------------------------------------
  Future<void> deleteVideoDp(BuildContext context) async {
    if (isUpdatingVideoDp || !isOwner || user == null) return;

    try {
      isUpdatingVideoDp = true;
      notifyListeners();

      await _profileService.deleteVideoDp(user!.uid);

      // Reload user from Firestore
      user = await _profileService.getUser(user!.uid);
      currentUser = user;

      if (context.mounted) {
        _success(context, 'Video DP removed');
      }
    } catch (e) {
      debugPrint('Error deleting video DP: $e');
      if (context.mounted) {
        _error(context);
      }
    } finally {
      isUpdatingVideoDp = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // UPDATE VIDEO DP (FIXED - CONSOLIDATED)
  // ------------------------------------------------------------
  Future<void> updateVideoDp(BuildContext context) async {
    debugPrint('🎥 updateVideoDp called');

    if (isUpdatingVideoDp || !isOwner) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('❌ No user authenticated');
      return;
    }

    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 20),
      );

      // User cancelled picker
      if (picked == null) {
        debugPrint('User cancelled video picker');
        return;
      }

      isUpdatingVideoDp = true;
      notifyListeners();

      await _profileService.updateVideoDp(uid: uid, file: File(picked.path));

      // Reload user from Firestore
      user = await _profileService.getUser(uid);
      currentUser = user;

      debugPrint('✅ videoDpUrl after reload = ${user?.videoDpUrl}');

      if (context.mounted) {
        _success(context, 'Video DP uploaded');
      }
    } catch (e) {
      debugPrint('❌ updateVideoDp error: $e');
      if (context.mounted) {
        _error(context);
      }
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

  // ------------------------------------------------------------
  // UI HELPERS - SNACKBARS
  // ------------------------------------------------------------
  void _success(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _error(BuildContext context) {
    if (!context.mounted) return;
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

    try {
      if (_isFollowing) {
        await _followService.unfollow(
          currentUid: currentUid,
          targetUid: user!.uid,
        );
        _isFollowing = false;
        followersCount--;
      } else {
        await _followService.follow(
          currentUid: currentUid,
          targetUid: user!.uid,
        );
        _isFollowing = true;
        followersCount++;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling follow: $e');
    }
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

  String? _currentUserId;
  String? _targetUserId;

  bool _isFollowing = false;
  bool get isFollowing => _isFollowing;

  int followersCount = 0;
  int followingCount = 0;

  List<PostModel> userPosts = [];
  List<PostModel> reposts = [];
  List<PostModel> savedPosts = [];

  int selectedTab = 0;

  // ------------------------------------------------------------
  // GETTERS
  // ------------------------------------------------------------
  String? get currentUserId => _currentUserId;
  String? get targetUserId => _targetUserId;

  bool get isOwner {
    final uid = _currentUserId ?? _auth.currentUser?.uid;
    return uid != null && user != null && uid == user!.uid;
  }

  // ------------------------------------------------------------
  // LOAD PROFILE DATA - Initialize with user IDs
  // ------------------------------------------------------------
  Future<void> loadProfileData({
    String? currentUserId,
    required String targetUserId,
  }) async {
    _currentUserId = currentUserId ?? _auth.currentUser?.uid;
    _targetUserId = targetUserId;

    if (_targetUserId == null) {
      debugPrint('Cannot load profile: targetUserId is null');
      isLoading = false;
      notifyListeners();
      return;
    }

    await _loadProfile(_targetUserId!);
  }

  // ------------------------------------------------------------
  // LOAD PROFILE (Internal method)
  // ------------------------------------------------------------
  Future<void> _loadProfile(String uid) async {
    isLoading = true;
    notifyListeners();

    try {
      final currentUid = _currentUserId ?? _auth.currentUser?.uid;

      user = await _profileService.getUser(uid);

      if (currentUid != null) {
        currentUser = await _profileService.getUser(currentUid);
      }

      if (user == null) {
        debugPrint('User not found: $uid');
        return;
      }

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
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // LOAD PROFILE (Public method - kept for backward compatibility)
  // ------------------------------------------------------------
  Future<void> loadProfile(String uid) async {
    _targetUserId = uid;
    await _loadProfile(uid);
  }

  // ------------------------------------------------------------
  // REFRESH (Reload profile)
  // ------------------------------------------------------------
  Future<void> refresh() async {
    if (_targetUserId != null) {
      await _loadProfile(_targetUserId!);
    }
  }

  // ------------------------------------------------------------
  // UPDATE PROFILE PHOTO (FIXED)
  // ------------------------------------------------------------
  Future<void> updatePhoto(BuildContext context) async {
    if (isUpdatingPhoto || !isOwner || user == null) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) {
        debugPrint('User cancelled photo picker');
        return;
      }

      isUpdatingPhoto = true;
      notifyListeners();

      final url = await _profileService.updateProfilePhoto(
        uid: user!.uid,
        file: File(picked.path),
      );

      if (url != null && url.isNotEmpty) {
        user = user!.copyWith(profileImageUrl: url);
        currentUser = currentUser?.copyWith(profileImageUrl: url);

        if (context.mounted) {
          _success(context, 'Profile photo updated');
        }
      }
    } catch (e) {
      debugPrint('Error updating photo: $e');
      if (context.mounted) {
        _error(context);
      }
    } finally {
      isUpdatingPhoto = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // UPDATE PROFILE BANNER (FIXED)
  // ------------------------------------------------------------
  Future<void> updateBanner(BuildContext context) async {
    if (isUpdatingBanner || !isOwner || user == null) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) {
        debugPrint('User cancelled banner picker');
        return;
      }

      isUpdatingBanner = true;
      notifyListeners();

      final url = await _profileService.updateProfileBanner(
        uid: user!.uid,
        file: File(picked.path),
      );

      if (url != null && url.isNotEmpty) {
        user = user!.copyWith(profileBannerUrl: url);

        if (context.mounted) {
          _success(context, 'Banner updated');
        }
      }
    } catch (e) {
      debugPrint('Error updating banner: $e');
      if (context.mounted) {
        _error(context);
      }
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
    if (!isOwner || user == null) return;

    try {
      await _profileService.updateProfileDetails(
        uid: user!.uid,
        displayName: displayName,
        bio: bio,
      );

      user = user!.copyWith(displayName: displayName, bio: bio);

      if (context.mounted) {
        _success(context, 'Profile updated');
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (context.mounted) {
        _error(context);
      }
    } finally {
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // VIDEO DP — REPLACE (FIXED)
  // ------------------------------------------------------------
  Future<void> replaceVideoDp(BuildContext context) async {
    if (isUpdatingVideoDp || !isOwner || user == null) return;

    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 20),
      );

      if (picked == null) {
        debugPrint('User cancelled video picker');
        return;
      }

      isUpdatingVideoDp = true;
      notifyListeners();

      await _profileService.updateVideoDp(
        uid: user!.uid,
        file: File(picked.path),
      );

      user = await _profileService.getUser(user!.uid);
      currentUser = user;

      if (context.mounted) {
        _success(context, 'Video DP updated');
      }
    } catch (e) {
      debugPrint('Error replacing video DP: $e');
      if (context.mounted) {
        _error(context);
      }
    } finally {
      isUpdatingVideoDp = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // VIDEO DP — DELETE (FIXED)
  // ------------------------------------------------------------
  Future<void> deleteVideoDp(BuildContext context) async {
    if (isUpdatingVideoDp || !isOwner || user == null) return;

    try {
      isUpdatingVideoDp = true;
      notifyListeners();

      await _profileService.deleteVideoDp(user!.uid);

      user = await _profileService.getUser(user!.uid);
      currentUser = user;

      if (context.mounted) {
        _success(context, 'Video DP removed');
      }
    } catch (e) {
      debugPrint('Error deleting video DP: $e');
      if (context.mounted) {
        _error(context);
      }
    } finally {
      isUpdatingVideoDp = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // UPDATE VIDEO DP (FIXED - CONSOLIDATED)
  // ------------------------------------------------------------
  Future<void> updateVideoDp(BuildContext context) async {
    debugPrint('🎥 updateVideoDp called');

    if (isUpdatingVideoDp || !isOwner) return;

    final uid = _currentUserId ?? _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('❌ No user authenticated');
      return;
    }

    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 20),
      );

      if (picked == null) {
        debugPrint('User cancelled video picker');
        return;
      }

      isUpdatingVideoDp = true;
      notifyListeners();

      await _profileService.updateVideoDp(uid: uid, file: File(picked.path));

      user = await _profileService.getUser(uid);
      currentUser = user;

      debugPrint('✅ videoDpUrl after reload = ${user?.videoDpUrl}');

      if (context.mounted) {
        _success(context, 'Video DP uploaded');
      }
    } catch (e) {
      debugPrint('❌ updateVideoDp error: $e');
      if (context.mounted) {
        _error(context);
      }
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

  // ------------------------------------------------------------
  // UI HELPERS - SNACKBARS
  // ------------------------------------------------------------
  void _success(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _error(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
  }

  // ------------------------------------------------------------
  // FOLLOW / UNFOLLOW
  // ------------------------------------------------------------
  Future<void> toggleFollow() async {
    if (user == null || isOwner) return;

    final currentUid = _currentUserId ?? _auth.currentUser?.uid;
    if (currentUid == null) return;

    try {
      if (_isFollowing) {
        await _followService.unfollow(
          currentUid: currentUid,
          targetUid: user!.uid,
        );
        _isFollowing = false;
        followersCount--;
      } else {
        await _followService.follow(
          currentUid: currentUid,
          targetUid: user!.uid,
        );
        _isFollowing = true;
        followersCount++;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling follow: $e');
    }
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

  // ------------------------------------------------------------
  // TAB DATA GETTERS (CANONICAL)
  // ------------------------------------------------------------

  List<PostModel> get repics => reposts;

  /// Quotes = posts where user has quoted
  /// (assumes ProfileService.getUserReposts already filters quote-replies)
  List<PostModel> get quotes =>
      reposts.where((p) => p.quoteReplyCount > 0).toList();

  List<PostModel> get currentTabPosts {
    switch (selectedTab) {
      case 0:
        return posts;
      case 1:
        return repics;
      case 2:
        return quotes;
      case 3:
        return saved;
      default:
        return posts;
    }
  }
}
