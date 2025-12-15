import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_scaffold.dart';
import '../settingsbreadcrumb/settings_snapout_screen.dart';

import 'home_controller_v2.dart';
import '../feed/day_feed_controller.dart';

import '../post/create/post_model.dart';
import '../post/details/post_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --------------------------------------------------
        // DAY FEED CONTROLLER
        // --------------------------------------------------
        ChangeNotifierProvider<DayFeedController>(
          create: (_) =>
              DayFeedController(followingUids: const [])..loadInitialFeed(),
        ),

        // --------------------------------------------------
        // HOME CONTROLLER (PROXY)
        // --------------------------------------------------
        ChangeNotifierProxyProvider<DayFeedController, HomeControllerV2>(
          create: (_) => HomeControllerV2(
            dayFeedController: DayFeedController(followingUids: const []),
          ),
          update: (_, dayFeedController, __) =>
              HomeControllerV2(dayFeedController: dayFeedController),
        ),
      ],
      child: Consumer<HomeControllerV2>(
        builder: (context, homeController, _) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          return AppScaffold(
            // --------------------------------------------------
            // SETTINGS SNAP-OUTendDrawer: const SettingsSnapOutScreen(),
            // --------------------------------------------------
            endDrawer: const SettingsSnapOutScreen(),

            // --------------------------------------------------
            // APP BAR (THEME-AWARE)
            // --------------------------------------------------
            appBar: AppBar(
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Row(
                children: [
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, "/company"),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: const AssetImage(
                        "assets/logo/company_logo.png",
                      ),
                      backgroundColor: scheme.surface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Piccture",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => Navigator.pushNamed(context, "/search"),
                  ),
                ],
              ),
              actions: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              ],
            ),

            // --------------------------------------------------
            // BODY
            // --------------------------------------------------
            body: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 12),

                // --------------------------------------------------
                // DAY ALBUM CARD
                // --------------------------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, "/day-feed"),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Day Album",
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            homeController.dayAlbumMessage,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onPrimary.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // --------------------------------------------------
                // SUGGESTED USERS (STUB)
                // --------------------------------------------------
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, i) => Container(
                      width: 90,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: scheme.onSurface.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Suggested",
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: 5,
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// POST CARD (THEME-SAFE, FUTURE-READY)
// ---------------------------------------------------------------------------

class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailsScreen(post: post)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.network(
                post.resolvedImages.first,
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                "Posted by ${post.authorName}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite,
                    size: 22,
                    color: post.likeCount > 0
                        ? Colors.red
                        : scheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text("${post.likeCount}", style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
