import 'package:flutter/material.dart';
import '../../post/create/post_model.dart';

class RepicsGrid extends StatelessWidget {
  final List<PostModel> posts;
  final void Function(PostModel post, int index)? onPostTap;

  const RepicsGrid({super.key, required this.posts, this.onPostTap});

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
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.repeat, size: 10, color: Colors.white),
                        SizedBox(width: 2),
                        Text(
                          'Repic',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
