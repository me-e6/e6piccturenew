import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ============================================================================
/// MUTUAL CHECKER SERVICE
/// ============================================================================
/// Efficiently checks if users are mutuals (follow each other).
/// Uses caching to minimize Firestore reads.
/// 
/// Usage in feed:
/// ```dart
/// final checker = MutualChecker();
/// await checker.initialize(); // Load once
/// 
/// // Then for each post:
/// final isMutual = checker.isMutual(post.authorId);
/// ```
/// ============================================================================
class MutualChecker {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MutualChecker({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  // Cache
  Set<String> _mutuals = {};
  Set<String> _following = {};
  Set<String> _gazetteers = {};
  bool _isInitialized = false;
  DateTime? _lastRefresh;

  static const _cacheValidDuration = Duration(minutes: 5);

  String? get _uid => _auth.currentUser?.uid;

  /// Check if cache is still valid
  bool get _isCacheValid {
    if (!_isInitialized || _lastRefresh == null) return false;
    return DateTime.now().difference(_lastRefresh!) < _cacheValidDuration;
  }

  // --------------------------------------------------------------------------
  // INITIALIZE (Call once when feed loads)
  // --------------------------------------------------------------------------
  Future<void> initialize({bool forceRefresh = false}) async {
    if (_isCacheValid && !forceRefresh) return;
    
    final uid = _uid;
    if (uid == null) return;

    try {
      // Fetch followers
      final followersSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followers')
          .get();

      // Fetch following
      final followingSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('following')
          .get();

      final followers = followersSnap.docs.map((d) => d.id).toSet();
      _following = followingSnap.docs.map((d) => d.id).toSet();

      // Mutuals = intersection
      _mutuals = followers.intersection(_following);

      _isInitialized = true;
      _lastRefresh = DateTime.now();

      debugPrint('✅ MutualChecker initialized: ${_mutuals.length} mutuals');
    } catch (e) {
      debugPrint('❌ Error initializing MutualChecker: $e');
    }
  }

  // --------------------------------------------------------------------------
  // LOAD GAZETTEERS (Call separately if needed)
  // --------------------------------------------------------------------------
  Future<void> loadGazetteers() async {
    try {
      final snap = await _firestore
          .collection('users')
          .where('type', isEqualTo: 'gazetteer')
          .get();

      _gazetteers = snap.docs.map((d) => d.id).toSet();

      debugPrint('✅ Loaded ${_gazetteers.length} gazetteers');
    } catch (e) {
      debugPrint('❌ Error loading gazetteers: $e');
    }
  }

  // --------------------------------------------------------------------------
  // CHECK METHODS
  // --------------------------------------------------------------------------

  /// Check if user is a mutual
  bool isMutual(String userId) {
    if (userId == _uid) return false; // Can't be mutual with yourself
    return _mutuals.contains(userId);
  }

  /// Check if user is being followed
  bool isFollowing(String userId) {
    return _following.contains(userId);
  }

  /// Check if user is a gazetteer
  bool isGazetteer(String userId) {
    return _gazetteers.contains(userId);
  }

  /// Get mutual status for multiple users at once
  Map<String, bool> getMutualStatuses(List<String> userIds) {
    return {
      for (final uid in userIds) uid: isMutual(uid),
    };
  }

  // --------------------------------------------------------------------------
  // STATS
  // --------------------------------------------------------------------------
  
  int get mutualCount => _mutuals.length;
  int get followingCount => _following.length;
  int get gazetteerCount => _gazetteers.length;

  // --------------------------------------------------------------------------
  // UPDATE METHODS (for local cache updates after actions)
  // --------------------------------------------------------------------------

  /// Add a new mutual (after follow back)
  void addMutual(String userId) {
    _mutuals.add(userId);
    _following.add(userId);
  }

  /// Remove a mutual (after unfollow)
  void removeMutual(String userId) {
    _mutuals.remove(userId);
    _following.remove(userId);
  }

  /// Clear cache (call on logout)
  void clear() {
    _mutuals.clear();
    _following.clear();
    _gazetteers.clear();
    _isInitialized = false;
    _lastRefresh = null;
  }
}

/// ============================================================================
/// POST ENRICHER
/// ============================================================================
/// Enriches posts with mutual/gazetteer status for display.
/// ============================================================================
class PostEnricher {
  final MutualChecker _checker;

  PostEnricher(this._checker);

  /// Enrich a list of author IDs with their status
  Map<String, UserStatus> enrichAuthors(List<String> authorIds) {
    return {
      for (final authorId in authorIds)
        authorId: UserStatus(
          isMutual: _checker.isMutual(authorId),
          isFollowing: _checker.isFollowing(authorId),
          isGazetteer: _checker.isGazetteer(authorId),
        ),
    };
  }
}

/// Status container for a user
class UserStatus {
  final bool isMutual;
  final bool isFollowing;
  final bool isGazetteer;

  UserStatus({
    this.isMutual = false,
    this.isFollowing = false,
    this.isGazetteer = false,
  });
}
