import 'package:flutter/material.dart';

/// Design token colors for light and dark themes.
/// 2026 US fintech: minimal, calm, premium (Stripe, Cash App, Apple Wallet).
class AppColors {
  AppColors._();

  // Primary (indigo/blue gradient - fintech)
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryGradientEnd = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);

  // Surface
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color surfaceVariantLight = Color(0xFFF8FAFC);
  static const Color backgroundLight = Color(0xFFF1F5F9);
  /// Dark theme scaffold: neutral black, matches home card surfaces (editorial dark)
  static const Color backgroundDark = Color(0xFF0E0E10);
  static const Color surfaceVariantDark = Color(0xFF374151);
  /// Darker variant for cards in dark theme (less bright than surfaceVariantDark)
  static const Color surfaceVariantDarkMuted = Color(0xFF2D3748);
  /// Premium card surface (editorial, high-fashion) – use for list tiles, cards
  static const Color cardSurfaceLight = Color(0xFFFAFAFA);
  static const Color cardSurfaceDark = Color(0xFF16161A);
  /// Accent for premium CTAs (gold)
  static const Color accentGold = Color(0xFFC9A962);

  // Glassmorphism
  static const Color glassLight = Color(0x1AFFFFFF);
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassDark = Color(0x1A1F2937);
  static const Color glassBorderDark = Color(0x2A374151);

  // Text
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textSecondaryDark = Color.fromARGB(255, 161, 177, 200);
  static const Color textTertiaryLight = Color.fromARGB(255, 123, 135, 153);
  static const Color textTertiaryDark = Color(0xFF64748B);

  // Borders
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Semantic
  static const Color error = Color(0xFFDC2626);
  static const Color errorBackground = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);
  static const Color success = Color(0xFF059669);
  static const Color successBackground = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);

  // Soft gradients (premium, depth)
  static const Color gradientStartLight = Color(0xFFF8FAFC);
  static const Color gradientEndLight = Color(0xFFEEF2FF);
  static const Color gradientStartDark = Color(0xFF0F172A);
  static const Color gradientEndDark = Color(0xFF1E1B4B);
}
