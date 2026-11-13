
import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette(this.isDark);

  final bool isDark;

  // Background & Surface
  Color get background =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);

  Color get surface =>
      isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Color get border =>
      isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200;

  Color get placeholder =>
      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;

  // Text Colors
  Color get title =>
      isDark ? Colors.white : const Color(0xFF111827);

  Color get heading => title;

  Color get bodyText =>
      isDark ? Colors.white70 : const Color(0xFF222222);

  Color get body =>
      isDark ? Colors.white : Colors.black87;

  Color get subText =>
      isDark ? Colors.white60 : Colors.black54;

  Color get emptyText =>
      isDark ? Colors.white54 : Colors.grey;

  // Icon Colors
  Color get icon =>
      isDark ? Colors.white : Colors.black;

  Color get mutedIcon =>
      isDark ? Colors.white38 : Colors.grey;

  // Button & Filter Colors
  Color get backButtonBg =>
      isDark ? const Color(0xFF3A2022) : const Color(0xFFFFE5E7);

  Color get filterBar =>
      isDark ? const Color(0xFF1A1416) : const Color(0xFFFFF4F4);

  Color get chipBg => surface;

  Color get countBg =>
      isDark ? const Color(0xFF3A2022) : const Color(0xFFFFE5E5);

  // Tab Colors
  Color get tabActive =>
      isDark ? Colors.white : Colors.black;

  Color get tabInactive =>
      isDark ? const Color(0xFF6B6B6B) : const Color(0xFFC8C8C8);

  // Shadow
  Color get shadow =>
      Colors.black.withValues(alpha: isDark ? 0.35 : 0.05);
}
