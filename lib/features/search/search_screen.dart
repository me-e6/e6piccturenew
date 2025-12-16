import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_scaffold.dart';
import 'app_search_controller.dart';
import '../follow/follow_controller.dart';
import '../profile/profile_screen.dart';
import '../post/details/post_details_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppSearchController(),
      child: Consumer<AppSearchController>(
        builder: (context, controller, _) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          return AppScaffold(
            // --------------------------------------------------
            // APP BAR WITH SEARCH FIELD
            // --------------------------------------------------
            appBar: AppBar(
              title: TextField(
                autofocus: true,
                onChanged: controller.search,
                decoration: InputDecoration(
                  hintText: "Search users or posts...",
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // BODY
            // --------------------------------------------------
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --------------------------------------------------
                        // FILTER CHIPS
                        // --------------------------------------------------
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Wrap(
                            spacing: 8,
                            children: [
                              _filterChip(
                                context,
                                label: "All",
                                filter: SearchFilter.all,
                                controller: controller,
                              ),
                              _filterChip(
                                context,
                                label: "Followers",
                                filter: SearchFilter.followers,
                                controller: controller,
                              ),
                              _filterChip(
                                context,
                                label: "Following",
                                filter: SearchFilter.following,
                                controller: controller,
                              ),
                              _filterChip(
                                context,
                                label: "Mutual",
                                filter: SearchFilter.mutual,
                                controller: controller,
                              ),
                            ],
                          ),
                        ),

                        // --------------------------------------------------
                        // USER RESULTS
                        // --------------------------------------------------
                        if (controller.userResults.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              top: 12,
                              bottom: 4,
                            ),
                            child: Text(
                              "Users",
                              style: theme.textTheme.titleMedium,
                            ),
                          ),

                        ListView.builder(
                          itemCount: controller.userResults.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final user = controller.userResults[index];

                            return ChangeNotifierProvider(
                              create: (_) => FollowController()..load(user.uid),
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

                                    // ✅ displayName is canonical
                                    title: Text(user.displayName),
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

                                    trailing: SizedBox(
                                      width: 110,
                                      child: ElevatedButton(
                                        onPressed: follow.isLoading
                                            ? null
                                            : () {
                                                if (follow.isFollowing) {
                                                  follow.unfollow(user.uid);
                                                } else {
                                                  follow.follow(user.uid);
                                                }
                                              },
                                        child: follow.isLoading
                                            ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(
                                                follow.isFollowing
                                                    ? "Following"
                                                    : "Follow",
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),

                        // --------------------------------------------------
                        // POST RESULTS
                        // --------------------------------------------------
                        if (controller.postResults.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              top: 20,
                              bottom: 8,
                            ),
                            child: Text(
                              "Posts",
                              style: theme.textTheme.titleMedium,
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

  // ---------------------------------------------------------------------------
  // FILTER CHIP
  // ---------------------------------------------------------------------------
  Widget _filterChip(
    BuildContext context, {
    required String label,
    required SearchFilter filter,
    required AppSearchController controller,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final selected = controller.activeFilter == filter;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => controller.setFilter(filter),
      selectedColor: scheme.primary,
      backgroundColor: scheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: selected ? scheme.onPrimary : scheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
