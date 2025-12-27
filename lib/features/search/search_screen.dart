import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'search_controllers.dart';
import 'search_result_tile.dart';

/// ============================================================================
/// SEARCH SCREEN - FIXED
/// ============================================================================
/// ✅ FIX: Changed `SearchController()` to `SearchControllers()` 
///    Flutter has a built-in SearchController class, causing conflict
/// ============================================================================
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // ✅ FIX: Use SearchControllers (our custom class), not SearchController (Flutter's built-in)
      create: (_) => SearchControllers(),
      child: const _SearchScreenBody(),
    );
  }
}

class _SearchScreenBody extends StatelessWidget {
  const _SearchScreenBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SearchControllers>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search users',
            hintStyle: TextStyle(color: scheme.onSurfaceVariant),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onChanged: controller.onQueryChanged,
        ),
        actions: [
          if (controller.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: controller.results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: scheme.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search for people',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: controller.results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return SearchResultTile(user: controller.results[index]);
              },
            ),
    );
  }
}
