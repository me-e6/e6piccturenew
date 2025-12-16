import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../follow_controller.dart';

class FollowButton extends StatelessWidget {
  final String targetUid;

  const FollowButton({super.key, required this.targetUid});

  @override
  Widget build(BuildContext context) {
    return Consumer<FollowController>(
      builder: (_, controller, __) {
        return SizedBox(
          height: 40,
          width: 140,
          child: ElevatedButton(
            onPressed: controller.isLoading
                ? null
                : () {
                    if (controller.isFollowing) {
                      controller.unfollow(targetUid);
                    } else {
                      controller.follow(targetUid);
                    }
                  },
            child: controller.isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(controller.isFollowing ? "Following" : "Follow"),
          ),
        );
      },
    );
  }
}
