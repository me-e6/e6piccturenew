import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

// Core
import 'core/theme/theme_controller.dart';
import 'core/theme/app_themes.dart';

// Features
import 'features/auth/auth_gate.dart';
import 'features/navigation/main_navigation.dart';
import 'features/feed/day_feed_controller.dart';
import 'features/feed/day_feed_service.dart';

// Controllers (Global)
import 'features/follow/mutual_checker.dart';

/// ============================================================================
/// MAIN.DART - PICCTURE APP
/// ============================================================================
/// Entry point with:
/// - ✅ Firebase initialization
/// - ✅ Persistent login
/// - ✅ Theme management
/// - ✅ Global providers
/// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const PicctureApp());
}

class PicctureApp extends StatelessWidget {
  const PicctureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme controller
        ChangeNotifierProvider(create: (_) => ThemeController()),

        // Mutual checker (global cache)
        Provider(create: (_) => MutualChecker()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Piccture',
            debugShowCheckedModeBanner: false,

            // Theme
            // Usage stays the same:
            theme: AppThemes.light,
            darkTheme: AppThemes.dark,
            themeMode: themeController.themeMode,

            // Start with AuthGate which handles login state
            home: const AuthGate(),

            // Named routes (for deep linking)
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }

  /// Route generator for named navigation
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/home':
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => DayFeedController(DayFeedService())..init(),
            child: const MainNavigation(),
          ),
        );

      case '/login':
        return MaterialPageRoute(builder: (_) => const AuthGate());

      case '/profile':
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;
        final handle = args?['handle'] as String?;

        if (userId != null) {
          return MaterialPageRoute(
            builder: (_) => _ProfileRoute(userId: userId),
          );
        } else if (handle != null) {
          return MaterialPageRoute(
            builder: (_) => _ProfileByHandleRoute(handle: handle),
          );
        }
        return null;

      case '/post':
        final args = settings.arguments as Map<String, dynamic>?;
        final postId = args?['postId'] as String?;

        if (postId != null) {
          return MaterialPageRoute(builder: (_) => _PostRoute(postId: postId));
        }
        return null;

      case '/notifications':
        return MaterialPageRoute(builder: (_) => const _NotificationsRoute());

      case '/settings':
        return MaterialPageRoute(builder: (_) => const _SettingsRoute());

      default:
        return MaterialPageRoute(builder: (_) => const _NotFoundRoute());
    }
  }
}

// =============================================================================
// ROUTE PLACEHOLDERS (Replace with actual screens)
// =============================================================================

class _ProfileRoute extends StatelessWidget {
  final String userId;
  const _ProfileRoute({required this.userId});

  @override
  Widget build(BuildContext context) {
    // Import and use: ProfileEntry(userId: userId)
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(child: Text('Profile: $userId')),
    );
  }
}

class _ProfileByHandleRoute extends StatelessWidget {
  final String handle;
  const _ProfileByHandleRoute({required this.handle});

  @override
  Widget build(BuildContext context) {
    // Look up userId by handle, then show profile
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(child: Text('Profile: @$handle')),
    );
  }
}

class _PostRoute extends StatelessWidget {
  final String postId;
  const _PostRoute({required this.postId});

  @override
  Widget build(BuildContext context) {
    // Import and use: PostDetailScreen(postId: postId)
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Center(child: Text('Post: $postId')),
    );
  }
}

class _NotificationsRoute extends StatelessWidget {
  const _NotificationsRoute();

  @override
  Widget build(BuildContext context) {
    // Import and use: NotificationsScreen()
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Notifications')),
    );
  }
}

class _SettingsRoute extends StatelessWidget {
  const _SettingsRoute();

  @override
  Widget build(BuildContext context) {
    // Import and use: SettingsScreen()
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings')),
    );
  }
}

class _NotFoundRoute extends StatelessWidget {
  const _NotFoundRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64),
            SizedBox(height: 16),
            Text('Page not found'),
          ],
        ),
      ),
    );
  }
}
