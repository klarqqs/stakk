import 'package:flutter/material.dart';
import '../theme/tokens/app_colors.dart';
import '../theme/tokens/app_radius.dart';
import '../theme/tokens/app_shadows.dart';

/// Rounded card with soft elevation. Theme-aware. 2026 fintech feel.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color ?? (isDark ? AppColors.surfaceVariantDarkMuted : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.xl),
        border: Border.all(
          color: isDark ? AppColors.borderDark.withValues(alpha: 0.5) : AppColors.borderLight.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: AppShadows.card(context),
      ),
      child: child,
    );
  }
}

/// Accent card (e.g. primary blue for balance/bill summary)
class AppCardAccent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppCardAccent({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
