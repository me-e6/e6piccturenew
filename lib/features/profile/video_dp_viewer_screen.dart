import 'package:flutter/material.dart';
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
