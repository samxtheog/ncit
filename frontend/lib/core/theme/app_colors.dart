import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF052659);
  static const Color secondary = Color(0xFF5483B3);
  static const Color accent = Color(0xFF7DA0CA);
  static const Color lightAccent = Color(0xFFC1E8FF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color warmAccent = Color(0xFFEAE0C8);

  // Surface colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F6FF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFF052659);
  static const Color textSecondary = Color(0xFF5483B3);
  static const Color textMuted = Color(0xFF8CA8C8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF052659), Color(0xFF5483B3)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF052659), Color(0xFF1A4A8A), Color(0xFF5483B3)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5483B3), Color(0xFF7DA0CA)],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC1E8FF), Color(0xFFEAF4FF)],
  );

  // Shadow
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: primary.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];
}
