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

  /// Headline: large, bold. Use for hero text. Inter Bold 24px.
  static TextStyle headline({
    BuildContext? context,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Brightness? brightness,
  }) {
    final isDark = _isDark(context, brightness);
    return GoogleFonts.inter(
      fontSize: fontSize ?? 24,
      fontWeight: fontWeight ?? FontWeight.w700,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }

  /// Header font: Inter Semibold. Pass [context] for theme-aware colors on dark/light.
  static TextStyle header({
    BuildContext? context,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Brightness? brightness,
  }) {
    final isDark = _isDark(context, brightness);
    return GoogleFonts.inter(
      fontSize: fontSize ?? 22,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }

  /// Title: Inter Semibold 18px.
  static TextStyle title({
    BuildContext? context,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Brightness? brightness,
  }) {
    final isDark = _isDark(context, brightness);
    return GoogleFonts.inter(
      fontSize: fontSize ?? 18,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }

  /// Body font: Inter Medium 16px. Pass [context] for theme-aware colors on dark/light.
  static TextStyle body({
    BuildContext? context,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Brightness? brightness,
  }) {
    final isDark = _isDark(context, brightness);
    return GoogleFonts.inter(
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
    );
  }

  /// Caption: Inter Regular 14px.
  static TextStyle caption({
    BuildContext? context,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Brightness? brightness,
  }) {
    final isDark = _isDark(context, brightness);
    return GoogleFonts.inter(
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
    );
  }

  /// Balance/Numbers: Inter Semibold 32-48px with letterSpacing -0.5
  static TextStyle balance({
    BuildContext? context,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Brightness? brightness,
  }) {
    final isDark = _isDark(context, brightness);
    return GoogleFonts.inter(
      fontSize: fontSize ?? 36,
      fontWeight: fontWeight ?? FontWeight.w600,
      letterSpacing: -0.5,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }
}
