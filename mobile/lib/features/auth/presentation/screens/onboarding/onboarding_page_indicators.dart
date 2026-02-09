import 'package:flutter/material.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

class OnboardingPageIndicators extends StatelessWidget {
  final int page;
  final int total;

  const OnboardingPageIndicators({
    super.key,
    required this.page,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = isDark ? AppColors.primaryDark : AppColors.primary;
    final inactive = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = page == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? active : inactive.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        );
      }),
    );
  }
}
