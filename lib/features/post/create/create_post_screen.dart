import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'create_post_controller.dart';

/// ============================================================================
/// CREATE POST SCREEN
/// ============================================================================
/// Enhanced post creation UI with:
/// - ✅ Reorderable image grid (drag to rearrange)
/// - ✅ Per-image crop button
/// - ✅ Per-image delete button
/// - ✅ Add more images button
/// - ✅ Upload progress indicator
/// - ✅ Theme-aware design
/// ============================================================================
class CreatePostScreen extends StatelessWidget {
  final List<XFile> files;

  const CreatePostScreen({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreatePostController(
        initialImagePaths: files.map((f) => f.path).toList(),
      ),
      child: const _CreatePostView(),
    );
  }
}

// ============================================================================
// CREATE POST VIEW
// ============================================================================

class _CreatePostView extends StatelessWidget {
  const _CreatePostView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CreatePostController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: scheme.onSurface),
          onPressed: () => _handleClose(context, controller),
        ),
        title: Text(
          'New Post',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Post button in app bar
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: controller.isBusy || !controller.hasImages
                  ? null
                  : () => _handlePost(context, controller),
              child: Text(
                'Post',
                style: TextStyle(
                  color: controller.hasImages && !controller.isBusy
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─────────────────────────────────────────────────────────────────
            // IMAGE GRID (Reorderable)
            // ─────────────────────────────────────────────────────────────────
            Expanded(
              child: controller.hasImages
                  ? _ImageEditorGrid(controller: controller)
                  : _EmptyState(controller: controller),
            ),

            // ─────────────────────────────────────────────────────────────────
            // ERROR MESSAGE
            // ─────────────────────────────────────────────────────────────────
            if (controller.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: scheme.errorContainer,
                child: Text(
                  controller.errorMessage!,
                  style: TextStyle(color: scheme.onErrorContainer),
                  textAlign: TextAlign.center,
                ),
              ),

            // ─────────────────────────────────────────────────────────────────
            // BOTTOM BAR
            // ─────────────────────────────────────────────────────────────────
            _BottomBar(controller: controller),
          ],
        ),
      ),
    );
  }

  void _handleClose(BuildContext context, CreatePostController controller) {
    if (controller.hasImages) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard Post?'),
          content: const Text('Your selected images will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Editing'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(
                'Discard',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handlePost(
    BuildContext context,
    CreatePostController controller,
  ) async {
    final success = await controller.createPost();
    if (success && context.mounted) {
      Navigator.pop(context, true);
    }
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyState extends StatelessWidget {
  final CreatePostController controller;

  const _EmptyState({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 80,
            color: scheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Add photos to your post',
            style: TextStyle(
              fontSize: 18,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: controller.isProcessing ? null : controller.pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: controller.isProcessing ? null : controller.pickFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// IMAGE EDITOR GRID (Reorderable)
// ============================================================================

class _ImageEditorGrid extends StatelessWidget {
  final CreatePostController controller;

  const _ImageEditorGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hint text
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Hold and drag to reorder • Tap icons to edit',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Reorderable grid
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: controller.imageCount,
              onReorder: controller.reorderImages,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                return _ImageTile(
                  key: ValueKey(controller.selectedImages[index]),
                  index: index,
                  imagePath: controller.selectedImages[index],
                  controller: controller,
                  isFirst: index == 0,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// IMAGE TILE (With crop/delete actions)
// ============================================================================

class _ImageTile extends StatelessWidget {
  final int index;
  final String imagePath;
  final CreatePostController controller;
  final bool isFirst;

  const _ImageTile({
    super.key,
    required this.index,
    required this.imagePath,
    required this.controller,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ReorderableDragStartListener(
        index: index,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFirst ? scheme.primary : scheme.outlineVariant,
              width: isFirst ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),

                // Gradient overlay for buttons
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Index badge (Cover indicator for first image)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isFirst ? scheme.primary : Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFirst ? 'Cover' : '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Drag handle
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.drag_handle, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Hold to drag',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Action buttons (top-right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      // Crop button
                      _ActionChip(
                        icon: Icons.crop,
                        onTap: () => controller.cropImage(index, context),
                      ),
                      const SizedBox(width: 8),
                      // Delete button
                      _ActionChip(
                        icon: Icons.close,
                        onTap: () => _confirmDelete(context),
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Image?'),
        content: const Text('This image will be removed from your post.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.removeImage(index);
            },
            child: Text(
              'Remove',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACTION CHIP (Crop/Delete buttons)
// ============================================================================

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionChip({
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.9)
              : Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

// ============================================================================
// BOTTOM BAR
// ============================================================================

class _BottomBar extends StatelessWidget {
  final CreatePostController controller;

  const _BottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upload progress
          if (controller.isUploading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: controller.uploadProgress > 0
                        ? controller.uploadProgress
                        : null,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uploading...',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons
          Row(
            children: [
              // Add more button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.isBusy
                      ? null
                      : () => controller.addMoreImages(context),
                  icon: const Icon(Icons.add_photo_alternate, size: 20),
                  label: const Text('Add More'),
                ),
              ),
              const SizedBox(width: 12),
              // Post button
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: controller.isBusy || !controller.hasImages
                      ? null
                      : () async {
                          final success = await controller.createPost();
                          if (success && context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                  child: controller.isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Post'),
                ),
              ),
            ],
          ),

          // Image count
          if (controller.hasImages)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${controller.imageCount} ${controller.imageCount == 1 ? 'image' : 'images'} selected',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
