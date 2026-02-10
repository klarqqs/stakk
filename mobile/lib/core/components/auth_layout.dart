import 'package:flutter/material.dart';
import '../theme/tokens/app_colors.dart';
import 'glass_card.dart';

/// Shared auth screen layout: gradient background + glass form card.
/// 2026 fintech: calm, premium, trustworthy.
class AuthLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool useGlass;

  const AuthLayout({
    super.key,
    required this.child,
    this.padding,
    this.useGlass = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.gradientStartDark,
                  AppColors.gradientEndDark,
                ]
              : [
                  AppColors.gradientStartLight,
                  AppColors.gradientEndLight,
                ],
        ),
      ),
      child: SafeArea(bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: useGlass
              ? GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: child,
                )
              : child,
        ),
      ),
    );
  }
}
