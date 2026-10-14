import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class QuickActionModel {
  final String title;
  final String iconPath;
  final List<Color> gradientColors;
  final Function(BuildContext context) onTap;

  QuickActionModel({
    required this.title,
    required this.iconPath,
    required this.gradientColors,
    required this.onTap,
  });
}

class SettingsItemModel {
  final String title;
  final String? subtitle;
  final String iconPath;
  final bool hasSwitch;
  final bool switchValue;

  SettingsItemModel({
    required this.title,
    this.subtitle,
    required this.iconPath,
    this.hasSwitch = false,
    this.switchValue = false,
  });
}