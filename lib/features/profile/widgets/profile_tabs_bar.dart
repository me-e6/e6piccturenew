/* import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile_controller.dart';

class ProfileTabsBar extends StatelessWidget {
  const ProfileTabsBar({super.key});

  static const _tabs = ['Pictures', 'Repics', 'Impact', 'Saved'];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final selected = controller.selectedTab;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_tabs.length, (index) {
          final isActive = index == selected;

          return GestureDetector(
            onTap: () => controller.setTab(index),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _tabs[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? Colors.black : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 2,
                  width: isActive ? 18 : 0,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
 */

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
