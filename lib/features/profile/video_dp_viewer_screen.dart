/* import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// ---------------------------------------------------------------------------
/// VIDEO DP VIEWER (FULLSCREEN, UI-ONLY)
/// ---------------------------------------------------------------------------
/// - No controllers
/// - No services
/// - Receives URL only
/// - Safe for reuse (Profile / Feed / User card)
class VideoDpViewerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoDpViewerScreen({super.key, required this.videoUrl});

  @override
  State<VideoDpViewerScreen> createState() => _VideoDpViewerScreenState();
}

class _VideoDpViewerScreenState extends State<VideoDpViewerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(true)
      ..initialize().then((_) {
        if (mounted) {
          _controller.play();
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),

            /// CLOSE BUTTON
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 */

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoDpViewerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoDpViewerScreen({super.key, required this.videoUrl});

  @override
  State<VideoDpViewerScreen> createState() => _VideoDpViewerScreenState();
}

class _VideoDpViewerScreenState extends State<VideoDpViewerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Video DP'),
      ),
      body: Center(
        child: _hasError
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white54, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load video',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              )
            : !_isInitialized
            ? const CircularProgressIndicator(color: Colors.white)
            : GestureDetector(
                onTap: () {
                  setState(() {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  });
                },
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
      ),
      floatingActionButton: _isInitialized && !_hasError
          ? FloatingActionButton(
              backgroundColor: Colors.white24,
              onPressed: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
