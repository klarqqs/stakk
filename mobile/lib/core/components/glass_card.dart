import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/tokens/app_colors.dart';
import '../theme/tokens/app_radius.dart';

/// Frosted glass card for 2026 fintech feel.
/// Use over soft gradients for subtle glassmorphism.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double blur;
  final Color? overlayColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = 12,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadius.xl;
    final overlay = overlayColor ??
        (isDark ? AppColors.glassDark : AppColors.glassLight);
    final borderColor = isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: overlay,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
