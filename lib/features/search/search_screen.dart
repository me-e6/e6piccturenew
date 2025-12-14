import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '.././follow/follow_controller.dart';

import 'app_search_controller.dart';
import '.././profile/profile_screen.dart';
import '.././post/details/post_details_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppSearchController(),
      child: Consumer<AppSearchController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5EDE3),
            appBar: AppBar(
              backgroundColor: const Color(0xFFE8E2D2),
              elevation: 0,
              title: TextField(
                autofocus: true,
                onChanged: controller.search,
                decoration: InputDecoration(
                  hintText: "Search users or posts...",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            body: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFC56A45)),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // -------- FILTER CHIPS --------
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Wrap(
                            spacing: 8,
                            children: [
                              _filterChip(
                                label: "All",
                                filter: SearchFilter.all,
                                controller: controller,
                              ),
                              _filterChip(
                                label: "Followers",
                                filter: SearchFilter.followers,
                                controller: controller,
                              ),
                              _filterChip(
                                label: "Following",
                                filter: SearchFilter.following,
                                controller: controller,
                              ),
                              _filterChip(
                                label: "Mutual",
                                filter: SearchFilter.mutual,
                                controller: controller,
                              ),
                            ],
                          ),
                        ),

                        // -------- USER RESULTS --------
                        if (controller.userResults.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(
                              left: 16,
                              top: 12,
                              bottom: 4,
                            ),
                            child: Text(
                              "Users",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2F2F2F),
                              ),
                            ),
                          ),

                        // ------------------------------------------------------
                        // UPDATED USER LIST WITH FOLLOW BUTTON
                        // ------------------------------------------------------
                        ListView.builder(
                          itemCount: controller.userResults.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final user = controller.userResults[index];

                            return ChangeNotifierProvider(
                              create: (_) =>
                                  FollowController()..checkFollowing(user.uid),
                              child: Consumer<FollowController>(
                                builder: (context, follow, _) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: user.photoUrl.isNotEmpty
                                          ? NetworkImage(user.photoUrl)
                                          : const AssetImage(
                                                  "assets/profile_placeholder.png",
                                                )
                                                as ImageProvider,
                                    ),

                                    title: Text(user.name),
                                    subtitle: Text(user.email),

                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProfileScreen(uid: user.uid),
                                        ),
                                      );
                                    },

                                    // ---------------- FOLLOW BUTTON ----------------
                                    trailing: SizedBox(
                                      width: 110,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              follow.isFollowingUser
                                              ? Colors.green.shade600
                                              : const Color(0xFFC56A45),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          if (follow.isFollowingUser) {
                                            follow.unfollow(user.uid);
                                          } else {
                                            follow.follow(user.uid);
                                          }
                                        },
                                        child: Text(
                                          follow.isLoading
                                              ? "..."
                                              : follow.isFollowingUser
                                              ? "Following"
                                              : "Follow",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),

                        // -------- POST RESULTS --------
                        if (controller.postResults.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(
                              left: 16,
                              top: 20,
                              bottom: 8,
                            ),
                            child: Text(
                              "Posts",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2F2F2F),
                              ),
                            ),
                          ),

                        if (controller.postResults.isNotEmpty)
                          GridView.builder(
                            itemCount: controller.postResults.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                ),
                            itemBuilder: (context, index) {
                              final post = controller.postResults[index];

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PostDetailsScreen(post: post),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    post.resolvedImages.first,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required SearchFilter filter,
    required AppSearchController controller,
  }) {
    final bool selected = controller.activeFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => controller.setFilter(filter),
      selectedColor: const Color(0xFFC56A45),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF2F2F2F),
      ),
      backgroundColor: const Color(0xFFE8E2D2),
    );
  }
}
