import 'package:flutter/material.dart';
import '../../post/create/post_model.dart';

class SavedGrid extends StatelessWidget {
  final List<PostModel> posts;
  final void Function(PostModel post, int index)? onPostTap;

  const SavedGrid({super.key, required this.posts, this.onPostTap});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(2),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final post = posts[index];

          return GestureDetector(
            onTap: () => onPostTap?.call(post, index),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  post.imageUrls.isNotEmpty ? post.imageUrls.first : '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Colors.black12),
                ),
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.bookmark,
                    color: Colors.white,
                    size: 16,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          );
        }, childCount: posts.length),
      ),
    );
  }
}
