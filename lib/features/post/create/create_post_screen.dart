import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_scaffold.dart';
import 'create_post_controller.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreatePostController(),
      child: Consumer<CreatePostController>(
        builder: (context, controller, _) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          return AppScaffold(
            // --------------------------------------------------
            // APP BAR (THEME-AWARE)
            // --------------------------------------------------
            appBar: AppBar(title: const Text("New Post"), centerTitle: true),

            // --------------------------------------------------
            // BODY
            // --------------------------------------------------
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --------------------------------------------------
                  // IMAGE GRID PREVIEW
                  // --------------------------------------------------
                  _ImageGridPreview(controller: controller),

                  const SizedBox(height: 20),

                  // --------------------------------------------------
                  // ACTION BUTTONS
                  // --------------------------------------------------
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text("Gallery"),
                          onPressed: controller.pickImagesFromGallery,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Camera"),
                          onPressed: controller.takePhoto,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --------------------------------------------------
                  // CAPTION
                  // --------------------------------------------------
                  TextField(
                    controller: controller.descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Write a caption...",
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --------------------------------------------------
                  // POST BUTTON
                  // --------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: controller.isLoading
                          ? null
                          : () => controller.createPost(context),
                      child: controller.isLoading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const Text("Post", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// IMAGE GRID PREVIEW (THEME-SAFE)
// ============================================================

class _ImageGridPreview extends StatelessWidget {
  final CreatePostController controller;

  const _ImageGridPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (controller.selectedImages.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary),
        ),
        child: Center(
          child: Text(
            "No images selected",
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.primary),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.selectedImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final img = controller.selectedImages[index];

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(img.path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // REMOVE BUTTON
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => controller.removeImageAt(index),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.scrim.withValues(alpha: 0.6),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, color: scheme.onPrimary, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
