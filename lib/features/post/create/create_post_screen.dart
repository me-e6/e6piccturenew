import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'create_post_controller.dart';

/// ----------------------------------
/// CreatePostScreen
/// ----------------------------------
/// v0.4.0 rules:
/// - Image-only posts
/// - Multi-image selection supported
/// - No captions
/// - No camera
/// - Clean exit on success
class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreatePostController(),
      child: Scaffold(
        appBar: AppBar(title: const Text('New Post')),
        body: const _CreatePostBody(),
      ),
    );
  }
}

class _CreatePostBody extends StatelessWidget {
  const _CreatePostBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<CreatePostController>(
      builder: (context, controller, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: controller.selectedImages.isEmpty
                    ? _EmptyPickerState(onPick: controller.pickImages)
                    : _SelectedImagesGrid(images: controller.selectedImages),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.isUploading
                    ? null
                    : () async {
                        final success = await controller.createPost();

                        if (success && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                child: controller.isUploading
                    ? const CircularProgressIndicator()
                    : const Text('Post'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ----------------------------------
/// Empty Picker State
/// ----------------------------------
class _EmptyPickerState extends StatelessWidget {
  final VoidCallback onPick;

  const _EmptyPickerState({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        icon: const Icon(Icons.photo_library_outlined),
        label: const Text('Select photos'),
        onPressed: onPick,
      ),
    );
  }
}

/// ----------------------------------
/// Selected Images Grid
/// ----------------------------------
class _SelectedImagesGrid extends StatelessWidget {
  final List<String> images;

  const _SelectedImagesGrid({required this.images});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(images[index], fit: BoxFit.cover),
        );
      },
    );
  }
}
