import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile_controller.dart';

/// ============================================================================
/// PROFILE TABS BAR
/// ============================================================================
/// Tab selector for profile content.
///
/// Tabs:
/// - Pictures (index 0) - Always visible
/// - Repics (index 1) - Always visible
/// - Quotes (index 2) - Always visible
/// - Saved (index 3) - Only visible to profile owner
/// ============================================================================
class ProfileTabsBar extends StatelessWidget {
  const ProfileTabsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final selected = controller.selectedTab;
    final isOwner = controller.isOwner;

    Widget tab(String label, int index, {IconData? icon}) {
      final bool active = selected == index;

      return GestureDetector(
        onTap: () => controller.setTab(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Icon + Label Row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 14,
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Underline indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: active ? 24 : 0,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Always visible tabs
          tab('Pictures', 0, icon: Icons.grid_on),
          tab('Repics', 1, icon: Icons.repeat),
          tab('Quotes', 2, icon: Icons.format_quote),

          // Saved tab - only visible to owner
          if (isOwner) tab('Saved', 3, icon: Icons.bookmark_outline),
        ],
      ),
    );
  }
}
