import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
// import 'package:stakk_savings/core/theme/tokens/app_radius.dart';
import 'package:stakk_savings/features/auth/presentation/screens/onboarding/onboarding_steps.dart';

/// Reusable onboarding page. Renders one step with icon, title, subtitle.
/// 2026 fintech: premium visuals, smooth animations, captivating design.
class OnboardingPageWidget extends StatelessWidget {
  final OnboardingStep step;
  final int pageIndex;

  const OnboardingPageWidget({
    super.key,
    required this.step,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final primaryGradientEnd = isDark
        ? AppColors.primaryDark
        : AppColors.primaryGradientEnd;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            const SizedBox(height: 36),

          // Hero Icon with enhanced visual effects
          _HeroIcon(
                icon: step.icon,
                primary: primary,
                primaryGradientEnd: primaryGradientEnd,
                isDark: isDark,
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                delay: 100.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 24),

          // Title with animation
          Text(
                step.title,
                style: AppTheme.headline(
                  context: context,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ).copyWith(height: 1.1),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 500.ms,
                delay: 300.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 18),

          // Subtitle with animation
          Text(
                step.subtitle,
                style: AppTheme.body(
                  context: context,
                  fontSize: 18,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),

                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 500.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 500.ms,
                delay: 500.ms,
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;
  final Color primary;
  final Color primaryGradientEnd;
  final bool isDark;

  const _HeroIcon({
    required this.icon,
    required this.primary,
    required this.primaryGradientEnd,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withOpacity(0.15),
            primaryGradientEnd.withOpacity(0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primary.withOpacity(0.2), width: 2),
            ),
          ),
          // Icon container with gradient background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.surfaceVariantDarkMuted,
                        AppColors.surfaceVariantDark,
                      ]
                    : [Colors.white, AppColors.surfaceVariantLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, size: 64, color: primary),
          ),
        ],
      ),
    );
  }
}
