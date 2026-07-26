import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static TextTheme getTextTheme(TextTheme base) {
    return TextTheme(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32.sp,
        fontWeight: FontWeight.bold,
        color: base.displayLarge?.color,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        color: base.headlineLarge?.color,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 22.sp,
        fontWeight: FontWeight.w500,
        color: base.headlineMedium?.color,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 20.sp,
        fontWeight: FontWeight.w500,
        color: base.headlineMedium?.color,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 18.sp,
        fontWeight: FontWeight.w500,
        color: base.titleLarge?.color,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: base.titleMedium?.color,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16.sp,
        color: base.bodyLarge?.color,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14.sp,
        color: base.bodyMedium?.color,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12.sp,
        color: base.bodySmall?.color,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: base.labelLarge?.color,
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 10.sp,
        color: base.labelSmall?.color,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      textTheme: getTextTheme(base.textTheme),
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      textTheme: getTextTheme(base.textTheme),
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
    );
  }

}
