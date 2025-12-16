import 'package:flutter/material.dart';
import 'core/theme/theme_controller.dart';
import '../../core/theme/app_theme.dart';
import '.././features/engagement/engagement_controller.dart';
// ---------------- AUTH ----------------
import 'features/auth/login/login_controller.dart';
import 'features/auth/login/login_screen.dart';
import 'features/auth/signup/signup_screen.dart';
// ---------------- NAVIGATION ----------------
import 'features/navigation/main_navigation.dart';
// ---------------- FEED ----------------
import 'features/feed/day_feed_screen.dart';
// ---------------- POST ----------------
import 'features/post/create/create_post_screen.dart';
// ---------------- SEARCH ----------------
import 'features/search/search_screen.dart';
import 'package:provider/provider.dart';

import 'package:e6piccturenew/debug/day_feed_probe_screen.dart';

class PicctureApp extends StatelessWidget {
  const PicctureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --------------------------------------------------
        // AUTH CONTROLLER
        // --------------------------------------------------
        ChangeNotifierProvider(create: (_) => LoginController()),

        // --------------------------------------------------
        // THEME CONTROLLER (GLOBAL)
        // --------------------------------------------------
        ChangeNotifierProvider(create: (_) => ThemeController()),

        // Engagement Controller
        ChangeNotifierProvider(create: (_) => EngagementController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Piccture',
            // ---------------- CORE / THEME ----------------
            // ---------------- THEME ----------------
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeController.themeMode,

            // ---------------- ROUTING ----------------
            initialRoute: "/login",
            routes: {
              // AUTH
              "/login": (_) => const LoginScreen(),
              "/signup": (_) => SignupScreen(),

              // MAIN APP
              "/home": (_) => const MainNavigation(),

              // FEED
              "/day-feed": (_) => const DayFeedScreen(),
              //'/day-feed': (_) => const DayFeedProbeScreen(),
              // POST
              "/create-post": (_) => const CreatePostScreen(),

              // SEARCH
              "/search": (_) => const SearchScreen(),
            },
          );
        },
      ),
    );
  }
}
