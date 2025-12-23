import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../follow/follow_controller.dart';
import '../follow/mutual_controller.dart';
import 'profile_controller.dart';
import 'profile_screen.dart';

class ProfileEntry extends StatelessWidget {
  /// Profile owner (target user)
  final String userId;

  const ProfileEntry({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    /// Logged-in viewer
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return MultiProvider(
      providers: [
        // --------------------------------------------------
        // PROFILE (target user)
        // --------------------------------------------------
        ChangeNotifierProvider(
          create: (_) => ProfileController()
            ..loadProfileData(currentUserId: currentUid, targetUserId: userId),
        ),

        // --------------------------------------------------
        // FOLLOW STATE (viewer → target)
        // --------------------------------------------------
        ChangeNotifierProvider(
          create: (_) =>
              FollowController()
                ..loadFollower(currentUserId: currentUid, targetUserId: userId),
        ),

        // --------------------------------------------------
        // MUTUALS (viewer ↔ target)
        // --------------------------------------------------
        ChangeNotifierProvider(
          create: (_) =>
              MutualController()
                ..loadMutual(currentUserId: currentUid, targetUserId: userId),
        ),
      ],
      child: ProfileScreen(userId: userId),
    );
  }
}
