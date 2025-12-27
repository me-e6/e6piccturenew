import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================================
/// DEEP LINK SERVICE
/// ============================================================================
/// Handles deep links for the app:
/// - https://piccture.app/post/{postId}
/// - https://piccture.app/user/{userId}
/// - https://piccture.app/@{handle}
/// - https://piccture.app/share/{shareId}
/// 
/// Usage:
/// 1. Add to AndroidManifest.xml and Info.plist
/// 2. Initialize in main.dart
/// 3. Call handleDeepLink when link is received
/// ============================================================================
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  // Callback for navigation
  Function(DeepLinkResult)? _onDeepLink;

  /// Set the callback for handling deep links
  void setHandler(Function(DeepLinkResult) handler) {
    _onDeepLink = handler;
  }

  /// Parse and handle a deep link URL
  DeepLinkResult? parseDeepLink(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Check if it's our domain
      if (!_isValidDomain(uri.host)) {
        debugPrint('⚠️ Unknown deep link domain: ${uri.host}');
        return null;
      }

      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isEmpty) {
        return DeepLinkResult(type: DeepLinkType.home);
      }

      final firstSegment = pathSegments.first;

      // Handle /post/{postId}
      if (firstSegment == 'post' && pathSegments.length >= 2) {
        return DeepLinkResult(
          type: DeepLinkType.post,
          id: pathSegments[1],
        );
      }

      // Handle /user/{userId}
      if (firstSegment == 'user' && pathSegments.length >= 2) {
        return DeepLinkResult(
          type: DeepLinkType.profile,
          id: pathSegments[1],
        );
      }

      // Handle /@{handle}
      if (firstSegment.startsWith('@')) {
        return DeepLinkResult(
          type: DeepLinkType.profileByHandle,
          id: firstSegment.substring(1), // Remove @
        );
      }

      // Handle /share/{shareId}
      if (firstSegment == 'share' && pathSegments.length >= 2) {
        return DeepLinkResult(
          type: DeepLinkType.share,
          id: pathSegments[1],
        );
      }

      // Handle /notifications
      if (firstSegment == 'notifications') {
        return DeepLinkResult(type: DeepLinkType.notifications);
      }

      // Handle /settings
      if (firstSegment == 'settings') {
        return DeepLinkResult(type: DeepLinkType.settings);
      }

      debugPrint('⚠️ Unknown deep link path: $url');
      return DeepLinkResult(type: DeepLinkType.home);
    } catch (e) {
      debugPrint('❌ Error parsing deep link: $e');
      return null;
    }
  }

  /// Handle a deep link and navigate
  void handleDeepLink(String url) {
    final result = parseDeepLink(url);
    if (result != null && _onDeepLink != null) {
      _onDeepLink!(result);
    }
  }

  /// Check if domain is valid
  bool _isValidDomain(String host) {
    return host == 'piccture.app' || 
           host == 'www.piccture.app' ||
           host.endsWith('.piccture.app');
  }

  /// Generate a deep link URL
  static String generatePostLink(String postId) {
    return 'https://piccture.app/post/$postId';
  }

  static String generateProfileLink(String userId) {
    return 'https://piccture.app/user/$userId';
  }

  static String generateHandleLink(String handle) {
    return 'https://piccture.app/@$handle';
  }
}

/// Deep link result types
enum DeepLinkType {
  home,
  post,
  profile,
  profileByHandle,
  share,
  notifications,
  settings,
}

/// Result of parsing a deep link
class DeepLinkResult {
  final DeepLinkType type;
  final String? id;
  final Map<String, String>? params;

  DeepLinkResult({
    required this.type,
    this.id,
    this.params,
  });

  @override
  String toString() => 'DeepLinkResult(type: $type, id: $id)';
}

/// ============================================================================
/// DEEP LINK NAVIGATOR
/// ============================================================================
/// Helper to navigate based on deep link results.
/// Add this to your main navigation widget.
/// ============================================================================
class DeepLinkNavigator {
  final GlobalKey<NavigatorState> navigatorKey;
  final FirebaseAuth _auth;

  DeepLinkNavigator({
    required this.navigatorKey,
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  /// Navigate based on deep link result
  Future<void> navigate(DeepLinkResult result) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('⚠️ Navigator not available');
      return;
    }

    // Check if user is logged in for protected routes
    final user = _auth.currentUser;
    if (user == null && _requiresAuth(result.type)) {
      debugPrint('⚠️ Deep link requires auth, redirecting to login');
      // Store the deep link to handle after login
      _pendingDeepLink = result;
      return;
    }

    debugPrint('🔗 Navigating to: $result');

    switch (result.type) {
      case DeepLinkType.home:
        navigator.pushNamedAndRemoveUntil('/', (route) => false);
        break;

      case DeepLinkType.post:
        if (result.id != null) {
          navigator.pushNamed('/post', arguments: {'postId': result.id});
        }
        break;

      case DeepLinkType.profile:
        if (result.id != null) {
          navigator.pushNamed('/profile', arguments: {'userId': result.id});
        }
        break;

      case DeepLinkType.profileByHandle:
        if (result.id != null) {
          navigator.pushNamed('/profile', arguments: {'handle': result.id});
        }
        break;

      case DeepLinkType.share:
        if (result.id != null) {
          navigator.pushNamed('/share', arguments: {'shareId': result.id});
        }
        break;

      case DeepLinkType.notifications:
        navigator.pushNamed('/notifications');
        break;

      case DeepLinkType.settings:
        navigator.pushNamed('/settings');
        break;
    }
  }

  /// Check if route requires authentication
  bool _requiresAuth(DeepLinkType type) {
    switch (type) {
      case DeepLinkType.home:
      case DeepLinkType.post:
      case DeepLinkType.profile:
      case DeepLinkType.profileByHandle:
        return false; // Public routes
      case DeepLinkType.share:
      case DeepLinkType.notifications:
      case DeepLinkType.settings:
        return true; // Protected routes
    }
  }

  /// Pending deep link to handle after login
  DeepLinkResult? _pendingDeepLink;

  /// Get and clear pending deep link
  DeepLinkResult? consumePendingDeepLink() {
    final link = _pendingDeepLink;
    _pendingDeepLink = null;
    return link;
  }

  /// Check if there's a pending deep link
  bool get hasPendingDeepLink => _pendingDeepLink != null;
}
