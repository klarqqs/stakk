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
    final primaryGradientEnd = isDark
        ? AppColors.primaryDark
        : AppColors.primaryGradientEnd;
    final inactive = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = page == i;

        return Container(
          // duration: const Duration(milliseconds: 450),
          // curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(horizontal: isActive ? 5 : 3.5),
          width: isActive ? 28 : 7,
          height: 7,
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [active, primaryGradientEnd],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isActive ? null : inactive.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        );
      }),
    );
  }
}
