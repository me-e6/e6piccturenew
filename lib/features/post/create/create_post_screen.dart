import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'create_post_controller.dart';

/// ----------------------------------
/// CreatePostScreen
/// ----------------------------------
/// v0.4.0 rules:
/// - Image-only posts
/// - Multi-image selection supported
/// - No captions
/// - Clean exit on success
class CreatePostScreen extends StatelessWidget {
  final List<XFile> files;

  const CreatePostScreen({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreatePostController(
        initialImagePaths: files.map((f) => f.path).toList(),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('New Post')),
        body: _CreatePostBody(), // ← NOT const
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isUploading
                      ? null
                      : () async {
                          final success = await controller.createPost();

                          if (success && context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                  child: controller.isUploading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                ),
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
/// Selected Images Grid (LOCAL FILE PREVIEW)
/// ----------------------------------
class _SelectedImagesGrid extends StatelessWidget {
  final List<String> images; // local file paths

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
          child: Image.file(File(images[index]), fit: BoxFit.cover),
        );
      },
    );
  }
}
