import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class EditorVideoWidget extends StatefulWidget {
  final String videoUrl;
  const EditorVideoWidget({super.key, required this.videoUrl});

  @override
  State<EditorVideoWidget> createState() => _EditorVideoWidgetState();
}

class _EditorVideoWidgetState extends State<EditorVideoWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  // 🚀 புதிய வீடியோ URL மாறும்போது பழையதை டிஸ்போஸ் செய்துவிட்டு புதியதை இனிஷியலைஸ் செய்ய
  @override
  void didUpdateWidget(covariant EditorVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      if (_isInitialized) {
        _controller.dispose();
      }
      setState(() {
        _isInitialized = false;
      });
      _initVideo();
    }
  }

  void _initVideo() async {
    // 🚀 403 Forbidden பிழையைத் தவிர்க்க HTTP Headers-ஐ சேர்த்தல்
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      httpHeaders: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Accept': 'video/webm,video/ogg,video/mp4;q=0.9,*/*;q=0.8',
      },
    );

    try {
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.play(); // ஆட்டோவாக பேக்ரவுண்ட் வீடியோ பிளே ஆக
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Editor Video Init Error: $e");
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
        ),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}