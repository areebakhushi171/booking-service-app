import 'package:flutter/material.dart';

/// Single source of truth for all brand colors.
/// Values are identical to the original BookEase palette.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1E5EFF);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color indigo = Color(0xFF6366F1);

  // Light surfaces
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Dark surfaces
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);

  // Dark-theme brand variants
  static const Color primaryDark = Color(0xFF4379FF);
  static const Color accentTealDark = Color(0xFF14B8A6);
  static const Color buttonDark = Color(0xFF3B72FF);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Colors.redAccent;
}
