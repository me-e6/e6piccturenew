import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_controller_v2.dart';
import '../feed/day_feed_controller.dart';

import '../post/create/post_model.dart';
import '../post/details/post_details_screen.dart';
import '../settingsbreadcrumb/settings_snapout_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --------------------------------------------------
        // DAY FEED CONTROLLER (SOURCE OF TRUTH)
        // --------------------------------------------------
        ChangeNotifierProvider<DayFeedController>(
          create: (_) => DayFeedController(
            followingUids: const [], // TODO: inject from auth/profile
          )..loadInitialFeed(),
        ),

        // --------------------------------------------------
        // HOME CONTROLLER v2 (PROXY PROVIDER - FIXED)
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
          return Scaffold(
            backgroundColor: const Color(0xFFF5EDE3),

            // --------------------------------------------------
            // SETTINGS SNAP-OUT
            // --------------------------------------------------
            endDrawer: const SettingsSnapOutScreen(),

            // --------------------------------------------------
            // APP BAR
            // --------------------------------------------------
            appBar: AppBar(
              backgroundColor: const Color(0xFFF5EDE3),
              elevation: 6,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, "/company"),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage("assets/logo/company_logo.png"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Picctture",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8,
                      color: Color(0xFF6C7A4C),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, "/search"),
                    child: const Icon(
                      Icons.search,
                      size: 26,
                      color: Color(0xFF6C7A4C),
                    ),
                  ),
                ],
              ),
              actions: [
                Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Color(0xFF6C7A4C),
                        size: 28,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                    );
                  },
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
                    onTap: () {
                      Navigator.pushNamed(context, "/day-feed");
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C7A4C),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Day Album",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            homeController.dayAlbumMessage,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
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
                        color: const Color(0xFFE8E2D2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          "Suggested",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: 5,
                  ),
                ),

                const SizedBox(height: 24),

                // --------------------------------------------------
                // LEGACY FEED (TEMPORARY)
                // --------------------------------------------------
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
// POST CARD (UNCHANGED)
// ---------------------------------------------------------------------------

class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailsScreen(post: post)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E2D2),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
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
                style: const TextStyle(fontSize: 14, color: Color(0xFF6C7A4C)),
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
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${post.likeCount}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
