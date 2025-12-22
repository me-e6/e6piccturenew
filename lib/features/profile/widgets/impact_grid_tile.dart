import 'package:flutter/material.dart';
import '../../post/create/post_model.dart';

class ImpactGridTile extends StatelessWidget {
  final PostModel post;

  const ImpactGridTile({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.withValues(alpha: .6), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            /// IMAGE
            Positioned.fill(
              child: Image.network(post.imageUrls.first, fit: BoxFit.cover),
            ),

            /// IMPACT BADGE
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Colors.amberAccent,
                ),
              ),
            ),

            /// OPTIONAL ENGAGEMENT HINT
            if (post.likeCount > 0)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        post.likeCount.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
