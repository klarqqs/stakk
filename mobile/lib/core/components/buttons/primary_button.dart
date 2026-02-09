import 'package:flutter/material.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import '../../theme/tokens/app_colors.dart';
import '../../theme/tokens/app_radius.dart';
import '../../theme/tokens/app_shadows.dart';

/// Primary CTA with soft gradient and elevation. 2026 fintech feel.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: onPressed != null && !isLoading
              ? AppShadows.button(context)
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: AppTheme.body(
                    context: context,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
