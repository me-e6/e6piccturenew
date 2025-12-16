import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_search_controller.dart';
import 'search_result_tile.dart';

/// ----------------------------------
/// SearchScreen
/// ----------------------------------
/// v0.4.0 Search rules:
/// - Profiles ONLY
/// - No posts
/// - No navigation to feed
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppSearchController(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Search')),
        body: const _SearchBody(),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSearchController>(
      builder: (context, controller, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search users',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: controller.searchUsers,
              ),
            ),
            Expanded(child: _SearchResults()),
          ],
        );
      },
    );
  }
}

/// ----------------------------------
/// Search Results
/// ----------------------------------
class _SearchResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppSearchController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.results.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        return ListView.separated(
          itemCount: controller.results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = controller.results[index];

            return SearchResultTile(user: user);
          },
        );
      },
    );
  }
}
