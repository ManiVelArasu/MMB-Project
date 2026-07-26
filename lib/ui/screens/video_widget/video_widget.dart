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

  void _videoListener() {
    // Controller play/pause state change aagumbodhu icon update aaga UI rebuild pannum
    if (mounted) {
      setState(() {});
    }
  }

  void _togglePlayPause() {
    if (_controller == null) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {
            _isInitialized = true;
          });
          _controller!.addListener(_videoListener); // 👈 State listener added
          _controller!.play();
          _controller!.setLooping(true);
        });
    } else {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener); // 👈 Clean up listener
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Exact play state check
    final bool isPlaying = _controller != null &&
        _controller!.value.isInitialized &&
        _controller!.value.isPlaying;

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
            // 1. VIDEO OR THUMBNAIL IMAGE
            Positioned.fill(
              child: _isInitialized && _controller != null
                  ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
                  : Image.asset(
                widget.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: Icon(
                    Icons.movie_creation,
                    size: 30.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            // 2. PLAY / PAUSE TRANSLUCENT OVERLAY BUTTON
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
                          : Icons.play_arrow_rounded, // 👈 Correct Icon State
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