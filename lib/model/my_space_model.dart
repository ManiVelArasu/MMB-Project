import 'package:flutter/material.dart';


class MySpaceModel {
  final String title;
  final String icon;
  final List<Color> gradientColors;

  MySpaceModel({
    required this.title,
    required this.icon,
    List<Color>? gradientColors, // Nullable parameter
  }) : gradientColors = gradientColors ??
      [const Color(0xFFE0F7FA), const Color(0xFF80DEEA)]; // Fallback Default Gradient
}class MyCelebrateModel {
  final String title;
  final String icon;
  final List<Color> gradientColors;

  MyCelebrateModel({
    required this.title,
    required this.icon,
    List<Color>? gradientColors, // Nullable parameter
  }) : gradientColors = gradientColors ??
      [const Color(0xFFE0F7FA), const Color(0xFF80DEEA)]; // Fallback Default Gradient
}