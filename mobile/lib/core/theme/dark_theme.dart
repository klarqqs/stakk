import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens/app_colors.dart';
import 'tokens/app_radius.dart';

ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      brightness: Brightness.dark,
      surface: AppColors.backgroundDark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textTheme: GoogleFonts.fustatTextTheme(ThemeData.dark().textTheme),
    fontFamily: GoogleFonts.fustat().fontFamily,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.textPrimaryDark,
      titleTextStyle: GoogleFonts.unbounded(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
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
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      titleTextStyle: GoogleFonts.unbounded(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondaryDark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariantDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
  );
}
