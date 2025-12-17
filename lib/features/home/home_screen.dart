import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../feed/day_feed_service.dart';

import '../../core/widgets/app_scaffold.dart';
import '../feed/day_feed_controller.dart';
import '../feed/day_feed_screen.dart';
import 'home_controller_v2.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // -----------------------------
        // Day Feed (source of truth)
        // -----------------------------
        ChangeNotifierProvider(
          create: (_) => DayFeedController(DayFeedService())..init(),
        ),

        // -----------------------------
        // Home Controller (derived)
        // -----------------------------
        ChangeNotifierProxyProvider<DayFeedController, HomeControllerV2>(
          create: (_) => HomeControllerV2.empty(),
          update: (_, dayFeed, __) =>
              HomeControllerV2(dayFeedController: dayFeed),
        ),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final home = context.watch<HomeControllerV2>();
    final dayFeed = context.watch<DayFeedController>();

    return AppScaffold(
      // --------------------------------------------------
      // APP BAR (NO drawer logic here)
      // --------------------------------------------------
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage("assets/logo/company_logo.png"),
            ),
            const SizedBox(width: 10),
            const Text("Piccture"),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.pushNamed(context, "/search"),
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
        ),
      ),

      // --------------------------------------------------
      // BODY
      // --------------------------------------------------
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {
            // Guard
            if (dayFeed.totalPostCount == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No pictures in the last 24 hours"),
                ),
              );
              return;
            }

            // Navigate to feed
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: dayFeed,
                  child: const DayFeedScreen(),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              home.dayAlbumMessage,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
