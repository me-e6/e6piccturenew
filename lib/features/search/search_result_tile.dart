import 'package:flutter/material.dart';
import '.././profile/user_model.dart';
import '.././post/create/post_model.dart';
import '.././post/details/post_details_screen.dart';
import '.././profile/profile_screen.dart';

class SearchResultTile extends StatelessWidget {
  final UserModel? user;
  final PostModel? post;

  const SearchResultTile({super.key, this.user, this.post});

  @override
  Widget build(BuildContext context) {
    if (user != null) {
      return ListTile(
        leading: CircleAvatar(
          backgroundImage: user!.photoUrl.isNotEmpty
              ? NetworkImage(user!.photoUrl)
              : const AssetImage("assets/profile_placeholder.png")
                    as ImageProvider,
        ),
        title: Text(user!.name),
        subtitle: Text(user!.type),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(uid: user!.uid)),
        ),
      );
    }

    if (post != null) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailsScreen(post: post!)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            post!.resolvedImages.first,
            height: 140,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
