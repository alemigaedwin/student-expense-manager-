import 'package:flutter/material.dart';

/// Central palette. Semantic colours stay consistent while neutral colours
/// switch when the user changes between light and dark mode.
class AppColors {
  AppColors._();

  static bool darkMode = false;

  static Color get background => darkMode ? Color(0xFF101827) : Color(0xFFF4F7FC);
  static Color get surface => darkMode ? Color(0xFF1B2638) : Colors.white;
  static Color get surfaceLight => darkMode ? Color(0xFF26364D) : Color(0xFFE8EEF8);
  static Color get card => surface;
  static Color get border => darkMode ? Color(0xFF34445D) : Color(0xFFD7E0ED);

  static const Color accent = Color(0xFF2563EB);
  static const Color income = Color(0xFF34C759);
  static const Color expense = Color(0xFFFF453A);
  static const Color transfer = Color(0xFFFF9F0A);

  static Color get textPrimary => darkMode ? Color(0xFFF3F6FC) : Color(0xFF17233A);
  static Color get textSecondary => darkMode ? Color(0xFFB0BED2) : Color(0xFF5D6B82);
  static Color get textMuted => darkMode ? Color(0xFF8292AA) : Color(0xFF8997AB);
}
