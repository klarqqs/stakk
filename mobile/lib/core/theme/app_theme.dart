import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'light_theme.dart';
import 'dark_theme.dart';
import 'tokens/app_colors.dart';

/// Central theme factory and typography helpers
class AppTheme {
  AppTheme._();

  static ThemeData get light => lightTheme;
  static ThemeData get dark => darkTheme;

  /// Resolve brightness from context or explicit param (defaults to light when both null)
  static bool _isDark(BuildContext? context, Brightness? brightness) {
    if (context != null) {
      return Theme.of(context).brightness == Brightness.dark;
    }
    return brightness == Brightness.dark;
  }

  /// Headline: large, bold. Use for hero text.
  static TextStyle headline({
    BuildContext? context,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Brightness? brightness,
  }) {
    final isDark = _isDark(context, brightness);
    return GoogleFonts.unbounded(
      fontSize: fontSize ?? 28,
      fontWeight: fontWeight ?? FontWeight.w700,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }

  /// Header font: Unbounded. Pass [context] for theme-aware colors on dark/light.
  static TextStyle header({
    BuildContext? context,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Brightness? brightness,
  }) {
    final isDark = _isDark(context, brightness);
    return GoogleFonts.unbounded(
      fontSize: fontSize ?? 22,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }

  /// Title: medium emphasis.
  static TextStyle title({
    BuildContext? context,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Brightness? brightness,
  }) {
    final isDark = _isDark(context, brightness);
    return GoogleFonts.unbounded(
      fontSize: fontSize ?? 18,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }

  /// Body font: Fustat. Pass [context] for theme-aware colors on dark/light.
  static TextStyle body({
    BuildContext? context,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Brightness? brightness,
  }) {
    final isDark = _isDark(context, brightness);
    return GoogleFonts.fustat(
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
    );
  }

  /// Caption: small, muted.
  static TextStyle caption({
    BuildContext? context,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Brightness? brightness,
  }) {
    final isDark = _isDark(context, brightness);
    return GoogleFonts.fustat(
      fontSize: fontSize ?? 12,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
    );
  }
}
