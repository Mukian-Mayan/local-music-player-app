import 'package:flutter/material.dart';

/// Shared design tokens for the glass + mono + accent look: a near-black
/// (or near-white, in light mode) base, one accent color used consistently
/// for active states, progress, and highlights, and translucent panels
/// layered on top for the frosted-glass effect.
class AppColors {
  static const accent = Color(0xFF00E5D8); // electric cyan

  static const darkBg = Color(0xFF0A0A0C);
  static const darkSurface = Color(0x14FFFFFF); // translucent white overlay
  static const darkBorder = Color(0x22FFFFFF);

  static const lightBg = Color(0xFFF2F2F5);
  static const lightSurface = Color(0x99FFFFFF);
  static const lightBorder = Color(0x33000000);
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: brightness,
  ).copyWith(primary: AppColors.accent);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: isDark ? AppColors.darkBg : AppColors.lightBg,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.accent,
      thumbColor: AppColors.accent,
      overlayColor: AppColors.accent.withValues(alpha: 0.2),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.accent),
  );
}
