/* import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_service.dart';
import 'services/profile_tabs_service.dart';
import '../follow/follow_service.dart';
import '../post/create/post_model.dart';
import 'user_model.dart';

/// ============================================================================
/// PROFILE CONTROLLER V2
/// ============================================================================
/// State management for Profile Screen with proper tab data loading.
///
/// TABS:
/// - Pictures (index 0): User's own posts
/// - Repics (index 1): Posts user has repicced
/// - Quotes (index 2): Quote posts authored by user
/// - Saved (index 3): Posts user has bookmarked (owner only)
///
/// FEATURES:
/// - Profile photo/banner/video DP management
/// - Follow/unfollow with optimistic UI
/// - Tab switching with lazy loading
/// - Gazetter badge display
/// ============================================================================
class ProfileController extends ChangeNotifier {
  // --------------------------------------------------------------------------
  // DEPENDENCIES
  // --------------------------------------------------------------------------
  final ProfileService _profileService;
  final ProfileTabsService _tabsService;
  final FollowService _followService;
  final FirebaseAuth _auth;
  final ImagePicker _picker = ImagePicker();

  ProfileController({
    ProfileService? profileService,
    ProfileTabsService? tabsService,
    FollowService? followService,
    FirebaseAuth? auth,
  }) : _profileService = profileService ?? ProfileService(),
       _tabsService = tabsService ?? ProfileTabsService(),
       _followService = followService ?? FollowService(),
       _auth = auth ?? FirebaseAuth.instance;

  // --------------------------------------------------------------------------
  // STATE - Loading
  // --------------------------------------------------------------------------
  bool isLoading = true;
  bool isUpdatingPhoto = false;
  bool isUpdatingBanner = false;
  bool isUpdatingVideoDp = false;
  bool _isProcessingFollow = false;

  // --------------------------------------------------------------------------
  // STATE - User Data
  // --------------------------------------------------------------------------
  UserModel? user;
  UserModel? currentUser;
  String? _currentUserId;
  String? _targetUserId;

  // --------------------------------------------------------------------------
  // STATE - Follow
  // --------------------------------------------------------------------------
  bool _isFollowing = false;
  bool get isFollowing => _isFollowing;

  int followersCount = 0;
  int followingCount = 0;

  // --------------------------------------------------------------------------
  // STATE - Tab Data
  // --------------------------------------------------------------------------
  int selectedTab = 0;

  List<PostModel> _posts = []; // Tab 0: User's posts
  List<PostModel> _repics = []; // Tab 1: Repicced posts
  List<PostModel> _quotes = []; // Tab 2: Quote posts by user
  List<PostModel> _saved = []; // Tab 3: Saved posts (owner only)

  // Track which tabs have been loaded (lazy loading)
  final Set<int> _loadedTabs = {0}; // Posts loaded by default

  // --------------------------------------------------------------------------
  // GETTERS - Identity
  // --------------------------------------------------------------------------
  String? get currentUserId => _currentUserId;
  String? get targetUserId => _targetUserId;

  bool get isOwner {
    final uid = _currentUserId ?? _auth.currentUser?.uid;
    return uid != null && user != null && uid == user!.uid;
  }

  // --------------------------------------------------------------------------
  // GETTERS - Tab Data (Canonical)
  // --------------------------------------------------------------------------
  List<PostModel> get posts => _posts;
  List<PostModel> get repics => _repics;
  List<PostModel> get quotes => _quotes;
  List<PostModel> get saved => _saved;

  /// Current tab's posts (for convenience)
  List<PostModel> get currentTabPosts {
    switch (selectedTab) {
      case 0:
        return _posts;
      case 1:
        return _repics;
      case 2:
        return _quotes;
      case 3:
        return _saved;
      default:
        return _posts;
    }
  }

  /// Impact posts (high engagement) - optional feature
  List<PostModel> get impactPosts => _posts.where((post) {
    return post.likeCount >= 50 ||
        post.replyCount >= 10 ||
        post.quoteReplyCount >= 5;
  }).toList();

  // --------------------------------------------------------------------------
  // LOAD PROFILE DATA
  // --------------------------------------------------------------------------
  /// Loads profile data for target user.
  ///
  /// [currentUserId] - The logged-in user's ID (optional, defaults to auth user)
  /// [targetUserId] - The profile being viewed
  Future<void> loadProfileData({
    String? currentUserId,
    required String targetUserId,
  }) async {
    isLoading = true;
    _targetUserId = targetUserId;
    _currentUserId = currentUserId ?? _auth.currentUser?.uid;
    notifyListeners();

    try {
      // Load user profile
      user = await _profileService.getUser(targetUserId);
      if (user == null) {
        debugPrint('❌ User not found: $targetUserId');
        return;
      }

      // Load current user (for ownership check)
      if (_currentUserId != null && _currentUserId != targetUserId) {
        currentUser = await _profileService.getUser(_currentUserId!);
      } else {
        currentUser = user;
      }

      // Load follow status
      if (_currentUserId != null && _currentUserId != targetUserId) {
        _isFollowing = await _followService.isFollowing(
          currentUid: _currentUserId!,
          targetUid: targetUserId,
        );
      }

      // Load follow counts
      followersCount = await _followService.getFollowersCount(targetUserId);
      followingCount = await _followService.getFollowingCount(targetUserId);

      // Load default tab (Pictures)
      _posts = await _profileService.getUserPosts(targetUserId);
      _loadedTabs.add(0);

      debugPrint(
        '✅ Profile loaded: ${user!.displayName} (${_posts.length} posts)',
      );
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // TAB SWITCHING (with lazy loading)
  // --------------------------------------------------------------------------
  Future<void> setTab(int index) async {
    if (selectedTab == index) return;

    selectedTab = index;
    notifyListeners();

    // Lazy load tab data if not already loaded
    if (!_loadedTabs.contains(index)) {
      await _loadTabData(index);
    }
  }

  /// Load data for specific tab
  Future<void> _loadTabData(int tabIndex) async {
    if (_targetUserId == null) return;

    try {
      switch (tabIndex) {
        case 0: // Pictures
          _posts = await _profileService.getUserPosts(_targetUserId!);
          break;

        case 1: // Repics
          _repics = await _tabsService.getUserRepics(_targetUserId!);
          debugPrint('📦 Loaded ${_repics.length} repics');
          break;

        case 2: // Quotes
          _quotes = await _tabsService.getUserQuotes(_targetUserId!);
          debugPrint('📦 Loaded ${_quotes.length} quotes');
          break;

        case 3: // Saved (owner only)
          if (isOwner) {
            _saved = await _tabsService.getUserSaved(_targetUserId!);
            debugPrint('📦 Loaded ${_saved.length} saved posts');
          } else {
            _saved = [];
            debugPrint('⚠️ Saved tab only visible to owner');
          }
          break;
      }

      _loadedTabs.add(tabIndex);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading tab $tabIndex: $e');
    }
  }

  /// Force refresh current tab
  Future<void> refreshCurrentTab() async {
    _loadedTabs.remove(selectedTab);
    await _loadTabData(selectedTab);
  }

  /// Force refresh all tabs
  Future<void> refreshAllTabs() async {
    _loadedTabs.clear();
    await _loadTabData(selectedTab);
  }

  // --------------------------------------------------------------------------
  // UPDATE PROFILE PHOTO
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // UPDATE PROFILE BANNER
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // SAVE PROFILE DETAILS
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // VIDEO DP - UPDATE
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // VIDEO DP - REPLACE
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // VIDEO DP - DELETE
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // VIDEO DP ACTIONS (UI TRIGGER)
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // FOLLOW / UNFOLLOW (Optimistic UI)
  // --------------------------------------------------------------------------
  Future<void> toggleFollow() async {
    if (user == null || isOwner || _isProcessingFollow) return;

    final currentUid = _currentUserId ?? _auth.currentUser?.uid;
    if (currentUid == null) return;

    // Prevent race conditions
    _isProcessingFollow = true;

    // Store previous state for rollback
    final wasFollowing = _isFollowing;
    final previousCount = followersCount;

    try {
      // ✅ OPTIMISTIC UI UPDATE
      _isFollowing = !_isFollowing;
      followersCount += _isFollowing ? 1 : -1;
      notifyListeners();

      // Network call
      if (wasFollowing) {
        await _followService.unfollow(
          currentUid: currentUid,
          targetUid: user!.uid,
        );
        debugPrint('✅ Unfollowed ${user!.displayName}');
      } else {
        await _followService.follow(
          currentUid: currentUid,
          targetUid: user!.uid,
        );
        debugPrint('✅ Followed ${user!.displayName}');
      }
    } catch (e) {
      // ✅ ROLLBACK ON FAILURE
      debugPrint('❌ Error toggling follow: $e');
      _isFollowing = wasFollowing;
      followersCount = previousCount;
      notifyListeners();
    } finally {
      _isProcessingFollow = false;
    }
  }

  // --------------------------------------------------------------------------
  // UI HELPERS - Snackbars
  // --------------------------------------------------------------------------
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
}
 */

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_service.dart';
import 'services/profile_tabs_service.dart';
import '../follow/follow_service.dart';
import '../post/create/post_model.dart';
import 'user_model.dart';

/// ============================================================================
/// PROFILE CONTROLLER V2
/// ============================================================================
/// State management for Profile Screen with proper tab data loading.
///
/// TABS:
/// - Pictures (index 0): User's own posts
/// - Repics (index 1): Posts user has repicced
/// - Quotes (index 2): Quote posts authored by user
/// - Saved (index 3): Posts user has bookmarked (owner only)
///
/// FEATURES:
/// - Profile photo/banner/video DP management
/// - Follow/unfollow with optimistic UI
/// - Tab switching with lazy loading
/// - Gazetter badge display
/// ============================================================================
class ProfileController extends ChangeNotifier {
  // --------------------------------------------------------------------------
  // DEPENDENCIES
  // --------------------------------------------------------------------------
  final ProfileService _profileService;
  final ProfileTabsService _tabsService;
  final FollowService _followService;
  final FirebaseAuth _auth;
  final ImagePicker _picker = ImagePicker();

  ProfileController({
    ProfileService? profileService,
    ProfileTabsService? tabsService,
    FollowService? followService,
    FirebaseAuth? auth,
  }) : _profileService = profileService ?? ProfileService(),
       _tabsService = tabsService ?? ProfileTabsService(),
       _followService = followService ?? FollowService(),
       _auth = auth ?? FirebaseAuth.instance;

  // --------------------------------------------------------------------------
  // STATE - Loading
  // --------------------------------------------------------------------------
  bool isLoading = true;
  bool isUpdatingPhoto = false;
  bool isUpdatingBanner = false;
  bool isUpdatingVideoDp = false;
  bool _isProcessingFollow = false;

  // --------------------------------------------------------------------------
  // STATE - User Data
  // --------------------------------------------------------------------------
  UserModel? user;
  UserModel? currentUser;
  String? _currentUserId;
  String? _targetUserId;

  // --------------------------------------------------------------------------
  // STATE - Follow
  // --------------------------------------------------------------------------
  bool _isFollowing = false;
  bool get isFollowing => _isFollowing;

  int followersCount = 0;
  int followingCount = 0;

  // --------------------------------------------------------------------------
  // STATE - Tab Data
  // --------------------------------------------------------------------------
  int selectedTab = 0;

  List<PostModel> _posts = []; // Tab 0: User's posts
  List<PostModel> _repics = []; // Tab 1: Repicced posts
  List<PostModel> _quotes = []; // Tab 2: Quote posts by user
  List<PostModel> _saved = []; // Tab 3: Saved posts (owner only)

  // Track which tabs have been loaded (lazy loading)
  final Set<int> _loadedTabs = {0}; // Posts loaded by default

  // --------------------------------------------------------------------------
  // GETTERS - Identity
  // --------------------------------------------------------------------------
  String? get currentUserId => _currentUserId;
  String? get targetUserId => _targetUserId;

  bool get isOwner {
    final uid = _currentUserId ?? _auth.currentUser?.uid;
    return uid != null && user != null && uid == user!.uid;
  }

  // --------------------------------------------------------------------------
  // GETTERS - Tab Data (Canonical)
  // --------------------------------------------------------------------------
  List<PostModel> get posts => _posts;
  List<PostModel> get repics => _repics;
  List<PostModel> get quotes => _quotes;
  List<PostModel> get saved => _saved;

  /// Current tab's posts (for convenience)
  List<PostModel> get currentTabPosts {
    switch (selectedTab) {
      case 0:
        return _posts;
      case 1:
        return _repics;
      case 2:
        return _quotes;
      case 3:
        return _saved;
      default:
        return _posts;
    }
  }

  /// Impact posts (high engagement) - optional feature
  List<PostModel> get impactPosts => _posts.where((post) {
    return post.likeCount >= 50 ||
        post.replyCount >= 10 ||
        post.quoteReplyCount >= 5;
  }).toList();

  // --------------------------------------------------------------------------
  // LOAD PROFILE (Simple API)
  // --------------------------------------------------------------------------
  /// Simple API: `ProfileController()..loadProfile(userId)`
  Future<void> loadProfile(String uid) => loadProfileData(targetUserId: uid);

  // --------------------------------------------------------------------------
  // LOAD PROFILE DATA (Full API)
  // --------------------------------------------------------------------------
  /// Full API with named parameters.
  ///
  /// [currentUserId] - The logged-in user's ID (optional, defaults to auth user)
  /// [targetUserId] - The profile being viewed
  Future<void> loadProfileData({
    String? currentUserId,
    required String targetUserId,
  }) async {
    isLoading = true;
    _targetUserId = targetUserId;
    _currentUserId = currentUserId ?? _auth.currentUser?.uid;
    notifyListeners();

    try {
      // Load user profile
      user = await _profileService.getUser(targetUserId);
      if (user == null) {
        debugPrint('❌ User not found: $targetUserId');
        return;
      }

      // Load current user (for ownership check)
      if (_currentUserId != null && _currentUserId != targetUserId) {
        currentUser = await _profileService.getUser(_currentUserId!);
      } else {
        currentUser = user;
      }

      // Load follow status
      if (_currentUserId != null && _currentUserId != targetUserId) {
        _isFollowing = await _followService.isFollowing(
          currentUid: _currentUserId!,
          targetUid: targetUserId,
        );
      }

      // Load follow counts
      followersCount = await _followService.getFollowersCount(targetUserId);
      followingCount = await _followService.getFollowingCount(targetUserId);

      // Load default tab (Pictures)
      _posts = await _profileService.getUserPosts(targetUserId);
      _loadedTabs.add(0);

      debugPrint(
        '✅ Profile loaded: ${user!.displayName} (${_posts.length} posts)',
      );
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // TAB SWITCHING (with lazy loading)
  // --------------------------------------------------------------------------
  Future<void> setTab(int index) async {
    if (selectedTab == index) return;

    selectedTab = index;
    notifyListeners();

    // Lazy load tab data if not already loaded
    if (!_loadedTabs.contains(index)) {
      await _loadTabData(index);
    }
  }

  /// Load data for specific tab
  Future<void> _loadTabData(int tabIndex) async {
    if (_targetUserId == null) return;

    try {
      switch (tabIndex) {
        case 0: // Pictures
          _posts = await _profileService.getUserPosts(_targetUserId!);
          break;

        case 1: // Repics
          _repics = await _tabsService.getUserRepics(_targetUserId!);
          debugPrint('📦 Loaded ${_repics.length} repics');
          break;

        case 2: // Quotes
          _quotes = await _tabsService.getUserQuotes(_targetUserId!);
          debugPrint('📦 Loaded ${_quotes.length} quotes');
          break;

        case 3: // Saved (owner only)
          if (isOwner) {
            _saved = await _tabsService.getUserSaved(_targetUserId!);
            debugPrint('📦 Loaded ${_saved.length} saved posts');
          } else {
            _saved = [];
            debugPrint('⚠️ Saved tab only visible to owner');
          }
          break;
      }

      _loadedTabs.add(tabIndex);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading tab $tabIndex: $e');
    }
  }

  /// Force refresh current tab
  Future<void> refreshCurrentTab() async {
    _loadedTabs.remove(selectedTab);
    await _loadTabData(selectedTab);
  }

  /// Force refresh all tabs
  Future<void> refreshAllTabs() async {
    _loadedTabs.clear();
    await _loadTabData(selectedTab);
  }

  // --------------------------------------------------------------------------
  // UPDATE PROFILE PHOTO
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // UPDATE PROFILE BANNER
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // SAVE PROFILE DETAILS
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // VIDEO DP - UPDATE
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // VIDEO DP - REPLACE
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // VIDEO DP - DELETE
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // VIDEO DP ACTIONS (UI TRIGGER)
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // FOLLOW / UNFOLLOW (Optimistic UI)
  // --------------------------------------------------------------------------
  Future<void> toggleFollow() async {
    if (user == null || isOwner || _isProcessingFollow) return;

    final currentUid = _currentUserId ?? _auth.currentUser?.uid;
    if (currentUid == null) return;

    // Prevent race conditions
    _isProcessingFollow = true;

    // Store previous state for rollback
    final wasFollowing = _isFollowing;
    final previousCount = followersCount;

    try {
      // ✅ OPTIMISTIC UI UPDATE
      _isFollowing = !_isFollowing;
      followersCount += _isFollowing ? 1 : -1;
      notifyListeners();

      // Network call
      if (wasFollowing) {
        await _followService.unfollow(
          currentUid: currentUid,
          targetUid: user!.uid,
        );
        debugPrint('✅ Unfollowed ${user!.displayName}');
      } else {
        await _followService.follow(
          currentUid: currentUid,
          targetUid: user!.uid,
        );
        debugPrint('✅ Followed ${user!.displayName}');
      }
    } catch (e) {
      // ✅ ROLLBACK ON FAILURE
      debugPrint('❌ Error toggling follow: $e');
      _isFollowing = wasFollowing;
      followersCount = previousCount;
      notifyListeners();
    } finally {
      _isProcessingFollow = false;
    }
  }

  // --------------------------------------------------------------------------
  // UI HELPERS - Snackbars
  // --------------------------------------------------------------------------
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
}
