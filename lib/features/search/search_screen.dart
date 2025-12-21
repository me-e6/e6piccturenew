import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'search_controllers.dart';
import 'search_result_tile.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchController(),
      child: const _SearchScreenBody(),
    );
  }
}

class _SearchScreenBody extends StatelessWidget {
  const _SearchScreenBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SearchControllers>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search users',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
          onChanged: controller.onQueryChanged,
        ),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : controller.results.isEmpty
          ? const Center(
              child: Text(
                'Search for people',
                style: TextStyle(color: Colors.grey),
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
