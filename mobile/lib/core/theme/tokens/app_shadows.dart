import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Soft elevation shadows for premium feel
class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (isDark ? Colors.black : Colors.black).withOpacity(isDark ? 0.3 : 0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> softElevated(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (isDark ? Colors.black : Colors.black).withOpacity(isDark ? 0.4 : 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (isDark ? Colors.black : AppColors.borderLight).withOpacity(isDark ? 0.25 : 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> button(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: AppColors.primary.withOpacity(isDark ? 0.4 : 0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
