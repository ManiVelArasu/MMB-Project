import 'package:flutter/material.dart';


class CanvasRatioModel {
  final String title;
  final String dimension;
  final String imagePath; // Dynamic Asset Image Path

  CanvasRatioModel({
    required this.title,
    required this.dimension,
    required this.imagePath,
  });
}


class AIToolModel {
  final String title;
  final String subtitle;
  final String imagePath;

  AIToolModel({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}