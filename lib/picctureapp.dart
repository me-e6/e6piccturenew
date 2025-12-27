import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ============================================================
// CORE
// ============================================================
import 'core/theme/app_themes.dart';
import 'core/theme/theme_controller.dart';

// ============================================================
// AUTH
// ============================================================
import 'features/auth/login/login_controller.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/login/login_screen.dart';
import 'features/auth/signup/signup_screen.dart';

// ============================================================
// NAVIGATION
// ============================================================
import 'features/navigation/main_navigation.dart';

// ============================================================
// PROFILE
// ============================================================
import 'features/profile/profile_entry.dart';

// ============================================================
// ADMIN
// ============================================================
import 'features/admin/admin_dashboard_screen.dart';

// ============================================================
// BLOCK & MUTE
// ============================================================
import 'features/block/blocked_users_screen.dart';
import 'features/mute/muted_users_screen.dart';

// ============================================================
// NOTIFICATIONS
// ============================================================
import 'features/notifications/notifications_screen.dart';

// ============================================================
// SETTINGS
// ============================================================
import 'features/settings/settings_screen.dart';

/// ============================================================================
/// PICCTURE APP
/// ============================================================================
class PicctureApp extends StatelessWidget {
  const PicctureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => LoginController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Piccture',
            theme: AppThemes.light,
            darkTheme: AppThemes.dark,
            themeMode: themeController.themeMode,
            initialRoute: '/login',

            // ══════════════════════════════════════════════════════════════
            // NAMED ROUTES
            // ══════════════════════════════════════════════════════════════
            routes: {
              '/login': (_) => const LoginScreen(),
              '/signup': (_) => SignupScreen(),
              '/home': (_) => const MainNavigation(),
              '/admin': (_) => const AdminDashboardScreen(),
              '/blocked': (_) => const BlockedUsersScreen(),
              '/muted': (_) => const MutedUsersScreen(),
              '/notifications': (_) => const NotificationsScreen(),
              '/settings': (_) => const SettingsScreen(),
            },

            // ══════════════════════════════════════════════════════════════
            // DYNAMIC ROUTES
            // ══════════════════════════════════════════════════════════════
            onGenerateRoute: (settings) {
              final uri = Uri.parse(settings.name ?? '');

              // /profile/:userId
              if (uri.pathSegments.length == 2 &&
                  uri.pathSegments[0] == 'profile') {
                final userId = uri.pathSegments[1];
                return MaterialPageRoute(
                  builder: (_) => ProfileEntry(userId: userId),
                  settings: settings,
                );
              }

              // /post/:postId (for deep links)
              if (uri.pathSegments.length == 2 &&
                  uri.pathSegments[0] == 'post') {
                final postId = uri.pathSegments[1];
                return MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Post')),
                    body: Center(child: Text('Post: $postId')),
                  ),
                  settings: settings,
                );
              }

              // 404 fallback
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Not Found')),
                  body: const Center(child: Text('Page not found')),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
