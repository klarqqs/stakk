import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens/app_colors.dart';
import 'tokens/app_radius.dart';

ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surfaceLight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    textTheme: GoogleFonts.fustatTextTheme(),
    fontFamily: GoogleFonts.fustat().fontFamily,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.textPrimaryLight,
      titleTextStyle: GoogleFonts.unbounded(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      titleTextStyle: GoogleFonts.unbounded(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondaryLight,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
  );
}
