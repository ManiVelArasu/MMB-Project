import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class EditorVideoWidget extends StatefulWidget {
  final String videoUrl;
  const EditorVideoWidget({super.key, required this.videoUrl});

  @override
  State<EditorVideoWidget> createState() => _EditorVideoWidgetState();
}

class _EditorVideoWidgetState extends State<EditorVideoWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  // Every init / release bumps this. An initialize() that finishes after the
  // widget was disposed (or the url changed) sees an old number and stops.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant EditorVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _releaseController();
      _isInitialized = false;
      _initVideo();
    }
  }

  /// ALWAYS disposes the player, even while initialize() is still running.
  /// (Before, a player that was not initialised yet was never disposed: its
  /// ExoPlayer kept downloading the whole video into the Java heap until the
  /// app died with OutOfMemoryError.)
  void _releaseController() {
    _generation++;
    final c = _controller;
    _controller = null;
    _isInitialized = false;
    c?.dispose();
  }

  Future<void> _initVideo() async {
    final url = widget.videoUrl.trim();
    if (url.isEmpty) return;

    final gen = ++_generation;
    // Send browser-like headers to avoid 403 Forbidden.
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Accept': 'video/webm,video/ogg,video/mp4;q=0.9,*/*;q=0.8',
      },
    );
    _controller = controller;

    try {
      await controller.initialize();
      // Disposed / url changed while loading: _releaseController already
      // disposed this controller.
      if (!mounted || gen != _generation) return;
      await controller.setLooping(true);
      await controller.play(); // auto-play like a background video
      if (!mounted || gen != _generation) return;
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Editor Video Init Error: $e');
      if (gen == _generation) {
        _controller = null;
        _isInitialized = false;
        controller.dispose();
      }
    }
  }

  @override
  void dispose() {
    _releaseController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_isInitialized || controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
        ),
      );
    }
    final size = controller.value.size;
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width > 0 ? size.width : 1,
          height: size.height > 0 ? size.height : 1,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}