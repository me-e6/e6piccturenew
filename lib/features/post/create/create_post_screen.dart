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
                "Create Post",
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
            ),

            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // IMAGE PREVIEW BOX
                    GestureDetector(
                      onTap: () => controller.pickImage(),
                      child: Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E2D2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFC56A45),
                            width: 1.5,
                          ),
                        ),
                        child: controller.selectedImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 48,
                                    color: Color(0xFF6C7A4C),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Tap to select image",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF2F2F2F),
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(controller.selectedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // DESCRIPTION FIELD
                    TextField(
                      controller: controller.descController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "Describe the issue",
                        filled: true,
                        fillColor: const Color(0xFFE8E2D2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // OFFICER DROPDOWN
                    Text(
                      "Tag an Officer (optional)",
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF2F2F2F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E2D2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.selectedOfficerId,
                          hint: const Text("Select Officer"),
                          items: controller.officerList
                              .map<DropdownMenuItem<String>>((officer) {
                                return DropdownMenuItem(
                                  value: officer["uid"],
                                  child: Text(officer["name"]),
                                );
                              })
                              .toList(),
                          onChanged: (value) {
                            controller.setOfficer(value);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // POST BUTTON
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
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
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
            ),
          );
        },
      ),
    );
  }
}
