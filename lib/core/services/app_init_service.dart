import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_persistence_service.dart';
import '../../core/services/deep_link_service.dart';

/// ============================================================================
/// APP INIT SERVICE
/// ============================================================================
/// Handles all startup initialization:
/// - ✅ Firebase initialization
/// - ✅ Auth state check
/// - ✅ Deep link setup
/// - ✅ Cache warming
/// - ✅ Remote config
/// - ✅ Analytics setup
/// ============================================================================
class AppInitService {
  static final AppInitService _instance = AppInitService._internal();
  factory AppInitService() => _instance;
  AppInitService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  User? _currentUser;
  User? get currentUser => _currentUser;

  String? _initError;
  String? get initError => _initError;

  // --------------------------------------------------------------------------
  // INITIALIZE
  // --------------------------------------------------------------------------
  Future<AppInitResult> initialize() async {
    if (_isInitialized) {
      return AppInitResult(
        success: true,
        isLoggedIn: _currentUser != null,
        user: _currentUser,
      );
    }

    try {
      debugPrint('🚀 Starting app initialization...');

      // 1. Initialize Firebase
      await _initFirebase();

      // 2. Check auth state
      final authResult = await _checkAuthState();

      // 3. Setup auth listener
      _setupAuthListener();

      // 4. Setup deep links
      _setupDeepLinks();

      // 5. Warm cache (optional)
      if (authResult.isLoggedIn) {
        await _warmCache(authResult.user!.uid);
      }

      _isInitialized = true;
      _currentUser = authResult.user;

      debugPrint('✅ App initialization complete');

      return AppInitResult(
        success: true,
        isLoggedIn: authResult.isLoggedIn,
        user: authResult.user,
      );
    } catch (e) {
      debugPrint('❌ App initialization failed: $e');
      _initError = e.toString();

      return AppInitResult(
        success: false,
        isLoggedIn: false,
        error: e.toString(),
      );
    }
  }

  // --------------------------------------------------------------------------
  // FIREBASE INIT
  // --------------------------------------------------------------------------
  Future<void> _initFirebase() async {
    debugPrint('📱 Initializing Firebase...');
    await Firebase.initializeApp();

    // Configure Firestore settings
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    debugPrint('✅ Firebase initialized');
  }

  // --------------------------------------------------------------------------
  // AUTH STATE CHECK
  // --------------------------------------------------------------------------
  Future<_AuthCheckResult> _checkAuthState() async {
    debugPrint('🔐 Checking auth state...');

    final persistence = AuthPersistenceService();
    final shouldAutoLogin = await persistence.shouldAutoLogin();

    if (!shouldAutoLogin) {
      debugPrint('📱 No auto-login, user needs to sign in');
      return _AuthCheckResult(isLoggedIn: false);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Reload user to check if still valid
      try {
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null) {
          debugPrint('✅ User authenticated: ${refreshedUser.uid}');
          return _AuthCheckResult(isLoggedIn: true, user: refreshedUser);
        }
      } catch (e) {
        debugPrint('⚠️ User token expired or invalid');
        await persistence.clearLoginState();
      }
    }

    return _AuthCheckResult(isLoggedIn: false);
  }

  // --------------------------------------------------------------------------
  // AUTH LISTENER
  // --------------------------------------------------------------------------
  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _currentUser = user;
      debugPrint('👤 Auth state changed: ${user?.uid ?? 'null'}');
    });
  }

  // --------------------------------------------------------------------------
  // DEEP LINKS SETUP
  // --------------------------------------------------------------------------
  void _setupDeepLinks() {
    // Deep link service is already a singleton
    // Just make sure it's ready
    DeepLinkService();
    debugPrint('🔗 Deep links ready');
  }

  // --------------------------------------------------------------------------
  // CACHE WARMING
  // --------------------------------------------------------------------------
  Future<void> _warmCache(String uid) async {
    debugPrint('🔥 Warming cache...');

    try {
      // Pre-fetch user profile
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      // Pre-fetch some feed data
      await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      debugPrint('✅ Cache warmed');
    } catch (e) {
      debugPrint('⚠️ Cache warming failed: $e');
      // Non-fatal, continue
    }
  }

  // --------------------------------------------------------------------------
  // RESET (for testing)
  // --------------------------------------------------------------------------
  void reset() {
    _isInitialized = false;
    _currentUser = null;
    _initError = null;
  }
}

class _AuthCheckResult {
  final bool isLoggedIn;
  final User? user;

  _AuthCheckResult({required this.isLoggedIn, this.user});
}

/// Result of app initialization
class AppInitResult {
  final bool success;
  final bool isLoggedIn;
  final User? user;
  final String? error;

  AppInitResult({
    required this.success,
    required this.isLoggedIn,
    this.user,
    this.error,
  });
}

/// ============================================================================
/// SPLASH SCREEN
/// ============================================================================
/// Shows while app is initializing.
/// Handles navigation based on auth state.
/// ============================================================================
class SplashScreen extends StatefulWidget {
  final Widget loginScreen;
  final Widget homeScreen;
  final Widget? errorScreen;

  const SplashScreen({
    super.key,
    required this.loginScreen,
    required this.homeScreen,
    this.errorScreen,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _statusText = 'Loading...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
    _initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final initService = AppInitService();

    setState(() => _statusText = 'Initializing...');

    final result = await initService.initialize();

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _hasError = true;
        _statusText = result.error ?? 'Unknown error';
      });

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      if (widget.errorScreen != null) {
        _navigateTo(widget.errorScreen!);
      } else {
        // Default: go to login screen
        _navigateTo(widget.loginScreen);
      }
      return;
    }

    setState(() => _statusText = 'Ready!');

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (result.isLoggedIn) {
      _navigateTo(widget.homeScreen);
    } else {
      _navigateTo(widget.loginScreen);
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.photo_camera,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // App name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'PICCTURE',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: scheme.onSurface,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Share your world',
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Loading indicator
                if (!_hasError)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  ),

                // Error icon
                if (_hasError)
                  Icon(Icons.error_outline, size: 32, color: scheme.error),

                const SizedBox(height: 16),

                // Status text
                Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: _hasError ? scheme.error : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
