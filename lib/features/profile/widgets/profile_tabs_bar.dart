import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile_controller.dart';

class ProfileTabsBar extends StatelessWidget {
  const ProfileTabsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final selected = controller.selectedTab;

    Widget tab(String label, int index) {
      final bool active = selected == index;

      return GestureDetector(
        onTap: () => controller.setTab(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: active ? 24 : 0,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        tab('Pictures', 0),
        tab('Repics', 1),
        tab('Impactters', 2),
        tab('Saved', 3),
      ],
    );
  }
}
