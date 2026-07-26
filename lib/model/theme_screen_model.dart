import 'package:flutter/material.dart';

class ThemeCardModel {
  final String title;
  final String templateCount;
  final String likesCount;
  final String imagePath;
  final bool isPremium;

  ThemeCardModel({
    required this.title,
    required this.templateCount,
    required this.likesCount,
    required this.imagePath,
    this.isPremium = true,
  });
}

