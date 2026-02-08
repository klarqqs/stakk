import 'package:flutter/material.dart';

/// Design token colors for light and dark themes
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF6366F1);

  // Surface
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color surfaceVariantLight = Color(0xFFF9FAFB);
  static const Color surfaceVariantDark = Color(0xFF374151);

  // Text
  static const Color textPrimaryLight = Color(0xFF1F2937);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color textTertiaryDark = Color(0xFF6B7280);

  // Borders
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);

  // Semantic
  static const Color error = Color(0xFFDC2626);
  static const Color errorBackground = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);
  static const Color success = Color(0xFF059669);
  static const Color successBackground = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);
}
