import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ============================================================
// CORE
// ============================================================
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

// ============================================================
// GLOBAL CONTROLLERS
// ============================================================
import 'features/auth/login/login_controller.dart';
import 'features/engagement/engagement_controller.dart';
import './features/auth/auth_contoller.dart';
// ============================================================
// AUTH
// ============================================================
import 'features/auth/login/login_screen.dart';
import 'features/auth/signup/signup_screen.dart';

// ============================================================
// NAVIGATION
// ============================================================
import 'features/navigation/main_navigation.dart';

///import 'features/navigation/main_navigation_v1_refined.dart';

// ============================================================
// FEED
// ============================================================
import 'features/feed/day_feed_screen.dart';

// ============================================================
// POST
// ============================================================
import 'features/post/create/create_post_screen.dart';

// ============================================================
// SEARCH
// ============================================================
import 'features/search/search_screen.dart';

// ============================================================
// PROFILE
// ============================================================
import 'features/profile/video_dp_upload_screen.dart';

class PicctureApp extends StatelessWidget {
  const PicctureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --------------------------------------------------
        // AUTH
        // --------------------------------------------------
        ChangeNotifierProvider(create: (_) => AuthController()),

        ChangeNotifierProvider(create: (_) => LoginController()),

        // --------------------------------------------------
        // THEME (GLOBAL)
        // --------------------------------------------------
        ChangeNotifierProvider(create: (_) => ThemeController()),

        // --------------------------------------------------
        // ENGAGEMENT (GLOBAL COUNTERS / LIKES / ETC.)
        // --------------------------------------------------
        ChangeNotifierProvider(create: (_) => EngagementController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Piccture',

            // --------------------------------------------------
            // THEME
            // --------------------------------------------------
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeController.themeMode,

            // --------------------------------------------------
            // ROUTING (TOP-LEVEL ONLY)
            // --------------------------------------------------
            initialRoute: '/login',
            routes: {
              // ---------------- AUTH ----------------
              '/login': (_) => const LoginScreen(),
              '/signup': (_) => SignupScreen(),

              // ---------------- MAIN APP ----------------
              '/home': (_) => const MainNavigation(),
              // '/home': (_) => const MainNavigationV1Refined(),
              // ---------------- UTILITIES ----------------
              '/search': (_) => const SearchScreen(),
              '/create-post': (_) => const CreatePostScreen(files: []),
              '/video-dp-upload': (_) => const VideoDpUploadScreen(),

              // ---------------- FEED (OPTIONAL ENTRY) ----------------
              '/day-feed': (_) => const DayFeedScreen(),
            },
          );
        },
      ),
    );
  }
}
