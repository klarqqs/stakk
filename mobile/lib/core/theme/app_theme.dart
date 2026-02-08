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

  /// Header font: Unbounded
  static TextStyle header({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Brightness? brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    return GoogleFonts.unbounded(
      fontSize: fontSize ?? 22,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
  }

  /// Body font: Fustat
  static TextStyle body({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Brightness? brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    return GoogleFonts.fustat(
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
    );
  }
}
