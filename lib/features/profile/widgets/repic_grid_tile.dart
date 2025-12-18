import 'package:flutter/material.dart';
import '../../post/create/post_model.dart';

class RepicGridTile extends StatelessWidget {
  final PostModel post;

  const RepicGridTile({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          /// IMAGE
          Image.network(post.imageUrls.first, fit: BoxFit.cover),

          /// TOP-LEFT REPIC BADGE
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.repeat, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Repic',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// BOTTOM ORIGINAL AUTHOR
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              color: Colors.black.withOpacity(0.55),
              child: Text(
                '@${post.authorName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
