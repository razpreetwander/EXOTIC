import 'package:flutter/material.dart';

class AppColors {
  // Official EXOTIC Brand Palette
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF181818);
  static const Color surfaceLight = Color(0xFF282828);
  static const Color cardBg = Color(0xFF181818);
  static const Color cardHover = Color(0xFF2A2A2A);
  static const Color playerBar = Color(0xFF000000);
  static const Color glassBorder = Color(0x1AFFFFFF);

  // Brand Accents
  static const Color primary = Color(0xFFFF7A00); // Official EXOTIC Vibrant Orange
  static const Color secondary = Color(0xFFFF9E42); // Bright Neon Orange
  static const Color accentPink = Color(0xFFE91E63);
  static const Color accentBlue = Color(0xFF2D9CDB);
  static const Color accentPurple = Color(0xFF8E44AD);
  static const Color accentOrange = Color(0xFFFF7A00);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF7A00), Color(0xFFFF9E42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF202020), Color(0xFF121212)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF727272);

  // Interactive
  static const Color activeGreen = Color(0xFFFF7A00); // Orange theme
  static const Color activeOrange = Color(0xFFFF7A00);
}
