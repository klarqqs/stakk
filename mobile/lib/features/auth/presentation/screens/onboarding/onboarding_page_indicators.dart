import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final primaryGradientEnd = isDark ? AppColors.primaryDark : AppColors.primaryGradientEnd;
    final inactive = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = page == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? 32 : 8,
          height: 8,
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
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: active.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        )
            .animate(key: ValueKey('indicator_$i'))
            .scale(
              begin: isActive ? const Offset(0.8, 0.8) : const Offset(1.0, 1.0),
              end: const Offset(1.0, 1.0),
              duration: 300.ms,
              curve: Curves.easeOutBack,
            );
      }),
    );
  }
}
