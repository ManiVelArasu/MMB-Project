import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class BrandVideoCard extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;

  const BrandVideoCard({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  @override
  State<BrandVideoCard> createState() => _BrandVideoCardState();
}

class _BrandVideoCardState extends State<BrandVideoCard> {
  VideoPlayerController? _controller;

  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initializeAndPlay() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      _controller = controller;

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      controller.setLooping(true);

      controller.addListener(_videoListener);

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      // Previous video pause
      videoPlaybackManager.setActive(controller);

      await controller.play();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;

    setState(() {});
  }

  Future<void> _togglePlayPause() async {
    if (_controller == null || !_isInitialized) {
      await _initializeAndPlay();
      return;
    }

    final controller = _controller!;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      videoPlaybackManager.setActive(controller);

      await controller.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    final controller = _controller;

    if (controller != null) {
      controller.removeListener(_videoListener);
      videoPlaybackManager.remove(controller);
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    final bool isPlaying =
        controller != null &&
        controller.value.isInitialized &&
        controller.value.isPlaying;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.black12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            // VIDEO / THUMBNAIL
            Positioned.fill(
              child: _isInitialized && controller != null
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    )
                  : Image.asset(
                      widget.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: Icon(
                            Icons.movie_creation,
                            size: 30.sp,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
            ),

            // LOADING
            if (_isLoading)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),

            // PLAY / PAUSE BUTTON
            Positioned(
              bottom: 10.h,
              left: 10.w,
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  height: 36.h,
                  width: 36.w,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlaybackManager {
  VideoPlayerController? _activeController;

  void setActive(VideoPlayerController controller) {
    if (_activeController != null &&
        _activeController != controller &&
        _activeController!.value.isInitialized) {
      _activeController!.pause();
    }

    _activeController = controller;
  }

  void remove(VideoPlayerController controller) {
    if (_activeController == controller) {
      _activeController = null;
    }
  }

  void dispose() {
    _activeController = null;
  }
}

final videoPlaybackManager = VideoPlaybackManager();
