import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../follow/mutual_controller.dart';
import '../profile/profile_controller.dart';
import '../follow/follow_controller.dart';
import '../profile/profile_screen.dart';

class ProfileEntry extends StatelessWidget {
  final String userId;

  const ProfileEntry({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid == userId;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProfileController()..loadProfile(userId),
        ),
        ChangeNotifierProvider(
          create: (_) => MutualController()..loadMutuals(userId),
        ),
        if (!isOwner)
          ChangeNotifierProvider(
            create: (_) => FollowController()..load(userId),
          ),
      ],
      child: ProfileScreen(userId: userId),
    );
  }
}
