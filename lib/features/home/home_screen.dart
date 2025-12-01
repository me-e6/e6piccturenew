import 'package:e6piccturenew/features/settingsbreadcrumb/settings_snapout_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_controller.dart';
import '../post/create/post_model.dart';
import '../post/details/post_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeController(),
      child: Consumer<HomeController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5EDE3),

            // ⭐ Correct position
            endDrawer: const SettingsSnapOutScreen(),

            appBar: AppBar(
              backgroundColor: const Color(0xFFF5EDE3),
              elevation: 6,
              automaticallyImplyLeading: false,

              // ⭐ Keep ONLY logo + search here
              title: Row(
                children: [
                  // LOGO LEFT
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

                  const SizedBox(width: 5),

                  // ⭐ Company Name Text (Brand Label)
                  const Text(
                    "Picctture",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8,
                      color: Color(
                        0xFF6C7A4C,
                      ), // same accent color as search icon
                    ),
                  ),
                  const Spacer(),
                  // SEARCH BAR
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

              // ⭐ Menu Icon goes here
              actions: [
                Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const Icon(
                        Icons.menu,
                        //color: Color(0xFFC56A45),
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

            // BODY (unchanged)
            body: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFC56A45)),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (scroll) {
                      if (scroll.metrics.pixels ==
                              scroll.metrics.maxScrollExtent &&
                          !controller.isMoreLoading) {
                        controller.loadMore();
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      onRefresh: controller.refreshFeed,
                      color: const Color(0xFFC56A45),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          if (controller.isOffline)
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "You're offline – showing cached posts",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),

                          const SizedBox(height: 10),

                          ListView.builder(
                            padding: const EdgeInsets.all(16),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount:
                                controller.feedPosts.length +
                                (controller.isMoreLoading ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i < controller.feedPosts.length) {
                                final post = controller.feedPosts[i];
                                return _PostCard(post: post);
                              }

                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFC56A45),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

//
// ---------------- POST CARD UI -----------------
//

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
                post.imageUrl,
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                post.isRepost
                    ? "RePic by ${post.repostedByName ?? 'User'}"
                    : "Posted by ${post.originalOwnerName ?? 'User'}",
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
