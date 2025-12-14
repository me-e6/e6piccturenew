import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'create_post_controller.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreatePostController(),
      child: Consumer<CreatePostController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5EDE3),
            appBar: AppBar(
              backgroundColor: const Color(0xFFC56A45),
              elevation: 0,
              title: const Text(
                "New Post",
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
            ),

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
                  // ACTION BUTTONS (GALLERY / CAMERA)
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
                      fillColor: const Color(0xFFE8E2D2),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC56A45),
                        disabledBackgroundColor: const Color(0xFFB08573),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: controller.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Post",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
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
// IMAGE GRID PREVIEW WIDGET
// ============================================================

class _ImageGridPreview extends StatelessWidget {
  final CreatePostController controller;

  const _ImageGridPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.selectedImages.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E2D2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC56A45)),
        ),
        child: const Center(
          child: Text(
            "No images selected",
            style: TextStyle(color: Color(0xFF6C7A4C), fontSize: 16),
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black54,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
