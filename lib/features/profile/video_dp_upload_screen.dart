import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VideoDpUploadScreen extends StatefulWidget {
  const VideoDpUploadScreen({super.key});

  @override
  State<VideoDpUploadScreen> createState() => _VideoDpUploadScreenState();
}

class _VideoDpUploadScreenState extends State<VideoDpUploadScreen> {
  File? _video;

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final result = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 15),
    );

    if (result != null) {
      setState(() => _video = File(result.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video DP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_video == null)
              ElevatedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.video_library),
                label: const Text('Pick 15s Video'),
              )
            else
              Column(
                children: [
                  const Text('Video selected'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Upload logic goes here (Firebase Storage)
                    },
                    child: const Text('Upload'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
