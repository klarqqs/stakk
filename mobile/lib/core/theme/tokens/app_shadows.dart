import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Soft elevation shadows for premium 2026 fintech feel.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> softElevated(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (isDark ? Colors.black : AppColors.borderLight).withValues(alpha: isDark ? 0.25 : 0.05),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> button(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.25),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// Focus glow for inputs (2026 premium feel).
  static List<BoxShadow> focusGlow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return [
      BoxShadow(
        color: primary.withValues(alpha: 0.25),
        blurRadius: 12,
        offset: Offset.zero,
      ),
    ];
  }
}
