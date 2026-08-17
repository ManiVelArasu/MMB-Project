import 'dart:io';
import 'package:flutter/material.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imagePath;

  const ImageViewerScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          // 🚀 ஜூம் (Zoom) மற்றும் மூவ் (Pan) செய்யக்கூடிய வசதி
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: imagePath,
            child: imagePath.startsWith('http')
                ? Image.network(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  )
                : Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
