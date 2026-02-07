import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme: Unbounded for headers, Fustat for body
class AppTheme {
  /// Header font: Unbounded
  static TextStyle header({double? fontSize, FontWeight? fontWeight, Color? color}) =>
      GoogleFonts.unbounded(
        fontSize: fontSize ?? 22,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? const Color(0xFF1F2937),
      );

  /// Body font: Fustat
  static TextStyle body({double? fontSize, FontWeight? fontWeight, Color? color}) =>
      GoogleFonts.fustat(
        fontSize: fontSize ?? 14,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? const Color(0xFF374151),
      );

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5),
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.fustatTextTheme(),
      fontFamily: GoogleFonts.fustat().fontFamily,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F2937),
        titleTextStyle: header(fontSize: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: body(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
