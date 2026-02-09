import 'package:flutter/material.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/features/auth/presentation/screens/onboarding/onboarding_steps.dart';

/// Reusable onboarding page. Renders one step with icon, title, subtitle.
/// 2026 fintech: clean hero icon, strong hierarchy.
class OnboardingPageWidget extends StatelessWidget {
  final OnboardingStep step;

  const OnboardingPageWidget({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _HeroIcon(icon: step.icon, primary: primary),
          const SizedBox(height: 56),
          Text(
            step.title,
            style: AppTheme.headline(
              context: context,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            step.subtitle,
            style: AppTheme.body(
              context: context,
              fontSize: 17,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;
  final Color primary;

  const _HeroIcon({required this.icon, required this.primary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Icon(icon, size: 84, color: primary),
      // child: SvgPicture.asset(
      //   'assets/images/onboarding_${icon}.svg',
      //   width: 84,
      //   height: 84,
      //   colorFilter: ColorFilter.mode(primary, BlendMode.srcIn),
      // ),
    );
  }
}
