import 'package:flutter/material.dart';

import '../post/create/post_model.dart';
//import '../home/widgets/engagement_bar.dart'; // if later extracted

class DayAlbumViewerScreen extends StatelessWidget {
  final List<PostModel> posts;
  final DateTime sessionStartedAt;

  const DayAlbumViewerScreen({
    super.key,
    required this.posts,
    required this.sessionStartedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Today’s Album'),
        centerTitle: true,
      ),
      body: PageView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];

          return Column(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: PageView.builder(
                    itemCount: post.imageUrls.length,
                    itemBuilder: (context, imgIndex) {
                      return Image.network(
                        post.imageUrls[imgIndex],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Reuse same engagement bar logic if extracted
              // EngagementBar(post: post),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('${index + 1} of ${posts.length}'),
              ),
            ],
          );
        },
      ),
    );
  }
}
