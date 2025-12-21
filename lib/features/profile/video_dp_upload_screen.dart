/* import 'dart:io';
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
 */

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class VideoDpUploadScreen extends StatefulWidget {
  const VideoDpUploadScreen({super.key});

  @override
  State<VideoDpUploadScreen> createState() => _VideoDpUploadScreenState();
}

class _VideoDpUploadScreenState extends State<VideoDpUploadScreen> {
  File? _video;
  VideoPlayerController? _controller;
  bool _isUploading = false;
  String? _errorMessage;

  // ------------------------------------------------------------
  // PICK VIDEO - FIXED
  // ------------------------------------------------------------
  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 15),
      );

      // User cancelled picker
      if (result == null) {
        debugPrint('User cancelled video picker');
        return;
      }

      // Validate file path
      if (result.path.isEmpty || !File(result.path).existsSync()) {
        setState(() {
          _errorMessage = 'Invalid video file';
        });
        return;
      }

      // Clean up old controller
      await _controller?.dispose();

      setState(() {
        _video = File(result.path);
        _errorMessage = null;
      });

      // Initialize video player
      _initializeVideoPlayer();
    } catch (e) {
      debugPrint('Error picking video: $e');
      setState(() {
        _errorMessage = 'Failed to pick video: $e';
      });
    }
  }

  // ------------------------------------------------------------
  // INITIALIZE VIDEO PLAYER
  // ------------------------------------------------------------
  Future<void> _initializeVideoPlayer() async {
    if (_video == null) return;

    try {
      _controller = VideoPlayerController.file(_video!)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _controller?.play();
            _controller?.setLooping(true);
          }
        });
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      setState(() {
        _errorMessage = 'Failed to load video preview';
      });
    }
  }

  // ------------------------------------------------------------
  // UPLOAD VIDEO
  // ------------------------------------------------------------
  Future<void> _uploadVideo() async {
    if (_video == null || _isUploading) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Implement your Firebase Storage upload logic here
      // Example:
      // final storageService = StorageService();
      // final url = await storageService.uploadVideoDp(_video!);
      // await profileService.updateVideoDpUrl(url);

      await Future.delayed(const Duration(seconds: 2)); // Simulated upload

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video DP uploaded successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error uploading video: $e');
      setState(() {
        _errorMessage = 'Upload failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // CLEAR VIDEO
  // ------------------------------------------------------------
  void _clearVideo() {
    _controller?.dispose();
    setState(() {
      _video = null;
      _controller = null;
      _errorMessage = null;
    });
  }

  // ------------------------------------------------------------
  // LIFECYCLE
  // ------------------------------------------------------------
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video DP'),
        actions: [
          if (_video != null)
            IconButton(icon: const Icon(Icons.close), onPressed: _clearVideo),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),

              // Video preview or picker button
              Expanded(
                child: _video == null
                    ? _buildPickerButton()
                    : _buildVideoPreview(),
              ),

              const SizedBox(height: 16),

              // Upload button
              if (_video != null)
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadVideo,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Upload Video DP'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PICKER BUTTON
  // ------------------------------------------------------------
  Widget _buildPickerButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Select a video up to 15 seconds',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.video_library),
            label: const Text('Pick Video'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // VIDEO PREVIEW
  // ------------------------------------------------------------
  Widget _buildVideoPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller!),

            // Play/Pause overlay
            if (!_controller!.value.isPlaying)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                  onPressed: () => _controller!.play(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
