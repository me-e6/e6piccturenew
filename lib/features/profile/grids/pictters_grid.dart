import 'package:flutter/material.dart';
import '../../post/create/post_model.dart';

class PicturesGrid extends StatelessWidget {
  final List<PostModel> posts;
  final void Function(PostModel post, int index)? onPostTap;

  const PicturesGrid({super.key, required this.posts, this.onPostTap});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(2),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final post = posts[index];
          final imageUrl = post.imageUrls.isNotEmpty
              ? post.imageUrls.first
              : null;

          return GestureDetector(
            onTap: onPostTap == null ? null : () => onPostTap!(post, index),
            child: imageUrl == null
                ? const ColoredBox(color: Colors.black12)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Colors.black12),
                  ),
          );
        }, childCount: posts.length),
      ),
    );
  }
}
