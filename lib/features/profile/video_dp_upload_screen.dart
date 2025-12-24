/* /* import 'dart:io';
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
 */
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/Profile_service.dart';

/// ============================================================================
/// VideoDpUploadScreen - ✅ FIXED
/// ============================================================================
///
/// CHANGES:
/// - ✅ Connected to ProfileService for actual upload
/// - ✅ Returns uploaded URL to caller
/// - ✅ Proper error handling with user feedback
/// - ✅ Loading states and progress indication
/// - ✅ Video validation (duration, size)
///
/// ============================================================================

class VideoDpUploadScreen extends StatefulWidget {
  const VideoDpUploadScreen({super.key});

  @override
  State<VideoDpUploadScreen> createState() => _VideoDpUploadScreenState();
}

class _VideoDpUploadScreenState extends State<VideoDpUploadScreen> {
  final ProfileService _profileService = ProfileService();

  File? _video;
  VideoPlayerController? _controller;
  bool _isUploading = false;
  String? _errorMessage;

  // ------------------------------------------------------------
  // PICK VIDEO - VALIDATED
  // ------------------------------------------------------------
  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 20), // Allow up to 20 seconds
      );

      // User cancelled picker
      if (result == null) {
        debugPrint('User cancelled video picker');
        return;
      }

      // Validate file path
      final file = File(result.path);
      if (!file.existsSync()) {
        setState(() {
          _errorMessage = 'Invalid video file';
        });
        return;
      }

      // Validate file size (max 50MB)
      final fileSizeInBytes = await file.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 50) {
        setState(() {
          _errorMessage = 'Video is too large. Maximum size is 50MB.';
        });
        return;
      }

      // Clean up old controller
      await _controller?.dispose();

      setState(() {
        _video = file;
        _errorMessage = null;
      });

      // Initialize video player
      await _initializeVideoPlayer();
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
      _controller = VideoPlayerController.file(_video!);
      await _controller!.initialize();

      if (mounted) {
        setState(() {});
        _controller?.play();
        _controller?.setLooping(true);
      }

      // Validate duration
      if (_controller!.value.duration.inSeconds > 20) {
        setState(() {
          _errorMessage = 'Video is too long. Maximum duration is 20 seconds.';
          _video = null;
        });
        await _controller?.dispose();
        _controller = null;
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      setState(() {
        _errorMessage = 'Failed to load video preview';
      });
    }
  }

  // ------------------------------------------------------------
  // UPLOAD VIDEO - ✅ FIXED: CONNECTED TO PROFILESERVICE
  // ------------------------------------------------------------
  Future<void> _uploadVideo() async {
    if (_video == null || _isUploading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'You must be logged in to upload a video DP';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // ✅ UPLOAD TO FIREBASE STORAGE VIA PROFILESERVICE
      final url = await _profileService.updateVideoDp(
        uid: user.uid,
        file: _video!,
      );

      debugPrint('✅ Video DP uploaded successfully: $url');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video DP uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Return URL to caller (ProfileController can refresh)
        Navigator.pop(context, url);
      }
    } catch (e) {
      debugPrint('❌ Error uploading video: $e');
      setState(() {
        _errorMessage = 'Upload failed: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          if (_video != null && !_isUploading)
            IconButton(icon: const Icon(Icons.close), onPressed: _clearVideo),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              if (_video == null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select a video up to 20 seconds and 50MB',
                          style: TextStyle(color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Uploading...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.cloud_upload),
                            SizedBox(width: 8),
                            Text('Upload Video DP'),
                          ],
                        ),
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
            'No video selected',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a video up to 20 seconds',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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

    return Column(
      children: [
        // Video duration info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, size: 16),
              const SizedBox(width: 8),
              Text(
                'Duration: ${_controller!.value.duration.inSeconds}s',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),

        // Video player
        Expanded(
          child: Center(
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
          ),
        ),
      ],
    );
  }
}
